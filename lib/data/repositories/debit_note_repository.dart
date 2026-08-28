import 'package:drift/drift.dart';

import '../models/debit_note_model.dart';
import '../models/purchase_models.dart';
import '../models/cash_book_models.dart';
import '../services/app_database.dart';
import '../services/money_ledger.dart';
import 'base_repository.dart';
import 'purchase_repository.dart';

class DebitNoteRepository extends BaseRepository {
  DebitNoteRepository(super.database, this._purchases);

  final PurchaseRepository _purchases;

  Future<String> nextNumber() async {
    const prefix = 'DN';
    final rows = await (database.select(
      database.debitNotes,
    )..where((table) => table.debitNoteNumber.like('$prefix-%'))).get();
    var next = 1;
    for (final row in rows) {
      final value = int.tryParse(row.debitNoteNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  Future<List<DebitNoteSummaryModel>> listForBill(int billId) async {
    final rows =
        await (database.select(database.debitNotes)
              ..where((table) => table.purchaseBillId.equals(billId))
              ..orderBy([(table) => OrderingTerm.desc(table.debitNoteDate)]))
            .get();
    return Future.wait(rows.map(_toSummary));
  }

  Future<List<DebitNoteSummaryModel>> listForSupplier(int supplierId) async {
    final rows =
        await (database.select(database.debitNotes)
              ..where((table) => table.supplierId.equals(supplierId))
              ..orderBy([(table) => OrderingTerm.desc(table.debitNoteDate)]))
            .get();
    return Future.wait(rows.map(_toSummary));
  }

  Future<List<DebitNoteModel>> listInRange(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final rows =
        await (database.select(database.debitNotes)
              ..where(
                (table) =>
                    table.debitNoteDate.isBiggerOrEqualValue(start) &
                    table.debitNoteDate.isSmallerOrEqualValue(end),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.debitNoteDate)]))
            .get();
    return Future.wait(rows.map(_load));
  }

  Future<List<DebitNoteSummaryModel>> unappliedForSupplier(
    int supplierId,
  ) async {
    final rows =
        await (database.select(database.debitNotes)
              ..where((table) => table.supplierId.equals(supplierId))
              ..orderBy([(table) => OrderingTerm.desc(table.debitNoteDate)]))
            .get();
    final summaries = await Future.wait(rows.map(_toSummary));
    return summaries.where((note) => note.unappliedMinor > 0).toList();
  }

  Future<DebitNoteModel?> getById(int id) async {
    final row = await (database.select(
      database.debitNotes,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<Map<int, int>> returnedQuantityByItem(int billId) async {
    final notes = await (database.select(
      database.debitNotes,
    )..where((table) => table.purchaseBillId.equals(billId))).get();
    final returned = <int, int>{};
    for (final note in notes) {
      final items = await (database.select(
        database.debitNoteItems,
      )..where((table) => table.debitNoteId.equals(note.id))).get();
      for (final item in items) {
        final sourceId = item.purchaseItemId;
        if (sourceId == null) continue;
        returned[sourceId] = (returned[sourceId] ?? 0) + item.quantityScaled;
      }
    }
    return returned;
  }

  Future<int> debitedValueForBill(int billId) async {
    final notes = await (database.select(
      database.debitNotes,
    )..where((table) => table.purchaseBillId.equals(billId))).get();
    return notes.fold<int>(0, (total, note) => total + note.grandTotalMinor);
  }

  Future<DebitNoteModel> issue({
    required PurchaseBillModel bill,
    required DateTime debitNoteDate,
    required String reason,
    required List<DebitNoteItemDraft> returnedItems,
    int? valueAdjustmentMinor,
    int valueAdjustmentTaxRateBasisPoints = 0,
    required DebitNoteRemainderAction remainder,
    String? refundMethod,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('A debit note reason is required.');
    }
    if (bill.id == null) throw StateError('Purchase bill is not saved.');
    if (bill.status == 'cancelled') {
      throw StateError('This purchase bill cannot receive a debit note.');
    }
    final dateOnly = DateTime(
      debitNoteDate.year,
      debitNoteDate.month,
      debitNoteDate.day,
    );
    final billDay = DateTime(
      bill.billDate.year,
      bill.billDate.month,
      bill.billDate.day,
    );
    if (dateOnly.isBefore(billDay)) {
      throw ArgumentError(
        'Debit note date cannot precede the purchase bill date.',
      );
    }

    final alreadyReturned = await returnedQuantityByItem(bill.id!);
    final alreadyDebited = await debitedValueForBill(bill.id!);
    final remainingValue = bill.totalMinor - alreadyDebited;
    if (remainingValue <= 0) {
      throw StateError('This purchase bill has already been fully returned.');
    }

    final snapshots = <_PreparedItem>[];
    for (final draft in returnedItems) {
      if (draft.returnedQuantityScaled <= 0) continue;
      final sourceId = draft.purchaseItem.id;
      if (sourceId == null) {
        throw StateError(
          'Returned lines must belong to the original purchase bill.',
        );
      }
      final prior = alreadyReturned[sourceId] ?? 0;
      if (draft.returnedQuantityScaled + prior > draft.originalQuantityScaled) {
        throw ArgumentError(
          'Returned quantity cannot exceed the original line.',
        );
      }
      snapshots.add(
        _PreparedItem(
          purchaseItemId: sourceId,
          name: draft.purchaseItem.name,
          quantityScaled: draft.returnedQuantityScaled,
          unit: draft.purchaseItem.unit,
          rateMinor: draft.purchaseItem.rateMinor,
          hsnSac: draft.purchaseItem.hsnSac,
          taxRateBasisPoints: (draft.purchaseItem.taxRate * 100).round(),
        ),
      );
    }
    if (valueAdjustmentMinor != null) {
      if (valueAdjustmentMinor <= 0) {
        throw ArgumentError('Value adjustment must be greater than zero.');
      }
      snapshots.add(
        _PreparedItem(
          purchaseItemId: null,
          name: 'Value adjustment',
          quantityScaled: 1000,
          unit: 'adjustment',
          rateMinor: valueAdjustmentMinor,
          hsnSac: null,
          taxRateBasisPoints: valueAdjustmentTaxRateBasisPoints,
        ),
      );
    }
    if (snapshots.isEmpty) {
      throw ArgumentError('Select returned quantities or a value adjustment.');
    }

    var subtotal = 0;
    var tax = 0;
    final computed = <({_PreparedItem item, int base, int tax, int total})>[];
    for (final snapshot in snapshots) {
      final base = _baseMinor(snapshot.quantityScaled, snapshot.rateMinor);
      final lineTax = bill.taxMode == 'exempt'
          ? 0
          : _taxMinor(base, snapshot.taxRateBasisPoints);
      computed.add((
        item: snapshot,
        base: base,
        tax: lineTax,
        total: base + lineTax,
      ));
      subtotal += base;
      tax += lineTax;
    }
    final grandTotal = subtotal + tax;
    if (grandTotal > remainingValue) {
      throw ArgumentError(
        'This debit note would exceed the remaining purchase bill value.',
      );
    }
    final split = _splitTax(bill.taxMode, tax);

    return database.transaction(() async {
      final now = DateTime.now();
      final number = await nextNumber();
      final debitNoteId = await database
          .into(database.debitNotes)
          .insert(
            DebitNotesCompanion.insert(
              debitNoteNumber: number,
              purchaseBillId: bill.id!,
              supplierId: Value(bill.supplierId),
              supplierName: bill.supplierName,
              debitNoteDate: dateOnly,
              reason: normalizedReason,
              taxMode: Value(bill.taxMode),
              itcEligible: Value(bill.itcEligible),
              subtotalMinor: subtotal,
              taxMinor: tax,
              cgstMinor: Value(split.$1),
              sgstMinor: Value(split.$2),
              igstMinor: Value(split.$3),
              grandTotalMinor: grandTotal,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      for (var index = 0; index < computed.length; index++) {
        final line = computed[index];
        await database
            .into(database.debitNoteItems)
            .insert(
              DebitNoteItemsCompanion.insert(
                debitNoteId: debitNoteId,
                purchaseItemId: Value(line.item.purchaseItemId),
                name: line.item.name,
                quantityScaled: line.item.quantityScaled,
                unit: line.item.unit,
                rateMinor: line.item.rateMinor,
                hsnSac: Value(line.item.hsnSac),
                taxRateBasisPoints: Value(line.item.taxRateBasisPoints),
                baseAmountMinor: line.base,
                taxAmountMinor: line.tax,
                totalMinor: line.total,
                sortOrder: index,
              ),
            );
      }

      final latest = await _purchases.getBill(bill.id!);
      if (latest == null) throw StateError('Purchase bill not found.');
      final applyAmount = grandTotal < latest.balanceMinor
          ? grandTotal
          : latest.balanceMinor;
      if (applyAmount > 0) {
        await database
            .into(database.debitNoteApplications)
            .insert(
              DebitNoteApplicationsCompanion.insert(
                debitNoteId: debitNoteId,
                purchaseBillId: bill.id!,
                amountMinor: applyAmount,
                appliedAt: now,
              ),
            );
        await _purchases.applyDebit(billId: bill.id!, amountMinor: applyAmount);
      }

      final leftover = grandTotal - applyAmount;
      if (leftover > 0 &&
          remainder == DebitNoteRemainderAction.applyThenRefund) {
        await (database.update(
          database.debitNotes,
        )..where((table) => table.id.equals(debitNoteId))).write(
          DebitNotesCompanion(
            refundedMinor: Value(leftover),
            refundMethod: Value(
              (refundMethod == null || refundMethod.trim().isEmpty)
                  ? 'Refund'
                  : refundMethod.trim(),
            ),
            refundedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await MoneyLedger(database).postLinked(
          sourceType: MoneySourceType.debitNote,
          sourceId: debitNoteId,
          amountMinor: leftover,
          occurredAt: now,
          direction: MoneyDirection.inbound,
          entryType: MoneyEntryType.refund,
          method: refundMethod,
          note: 'Debit note refund',
        );
      }

      return (await getById(debitNoteId))!;
    });
  }

  Future<void> applyUnapplied({
    required int debitNoteId,
    required int billId,
    required int amountMinor,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Debit amount must be greater than zero.');
    }
    await database.transaction(() async {
      final note = await getById(debitNoteId);
      if (note == null) throw StateError('Debit note not found.');
      if (amountMinor > note.unappliedMinor) {
        throw ArgumentError('Amount exceeds the remaining supplier credit.');
      }
      final bill = await _purchases.getBill(billId);
      if (bill == null) throw StateError('Purchase bill not found.');
      if (bill.supplierId != note.supplierId) {
        throw StateError(
          'Supplier credit can only be applied to the same supplier.',
        );
      }
      await database
          .into(database.debitNoteApplications)
          .insert(
            DebitNoteApplicationsCompanion.insert(
              debitNoteId: debitNoteId,
              purchaseBillId: billId,
              amountMinor: amountMinor,
              appliedAt: DateTime.now(),
            ),
          );
      await _purchases.applyDebit(billId: billId, amountMinor: amountMinor);
    });
  }

  Future<DebitNoteSummaryModel> _toSummary(DebitNote row) async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((table) => table.id.equals(row.purchaseBillId))).getSingle();
    final applied = await _appliedTotal(row.id);
    return DebitNoteSummaryModel(
      id: row.id,
      debitNoteNumber: row.debitNoteNumber,
      purchaseBillId: row.purchaseBillId,
      billNumber: bill.billNumber,
      supplierName: row.supplierName,
      debitNoteDate: row.debitNoteDate,
      reason: row.reason,
      grandTotalMinor: row.grandTotalMinor,
      appliedMinor: applied,
      refundedMinor: row.refundedMinor,
    );
  }

  Future<DebitNoteModel> _load(DebitNote row) async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((table) => table.id.equals(row.purchaseBillId))).getSingle();
    final itemRows =
        await (database.select(database.debitNoteItems)
              ..where((table) => table.debitNoteId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final applied = await _appliedTotal(row.id);
    return DebitNoteModel(
      id: row.id,
      debitNoteNumber: row.debitNoteNumber,
      purchaseBillId: row.purchaseBillId,
      billNumber: bill.billNumber,
      supplierId: row.supplierId,
      supplierName: row.supplierName,
      debitNoteDate: row.debitNoteDate,
      reason: row.reason,
      taxMode: row.taxMode,
      itcEligible: row.itcEligible,
      items: itemRows
          .map(
            (item) => DebitNoteItemModel(
              id: item.id,
              purchaseItemId: item.purchaseItemId,
              name: item.name,
              quantityScaled: item.quantityScaled,
              unit: item.unit,
              rateMinor: item.rateMinor,
              hsnSac: item.hsnSac,
              taxRateBasisPoints: item.taxRateBasisPoints,
              baseAmountMinor: item.baseAmountMinor,
              taxAmountMinor: item.taxAmountMinor,
              totalMinor: item.totalMinor,
            ),
          )
          .toList(),
      subtotalMinor: row.subtotalMinor,
      taxMinor: row.taxMinor,
      cgstMinor: row.cgstMinor,
      sgstMinor: row.sgstMinor,
      igstMinor: row.igstMinor,
      grandTotalMinor: row.grandTotalMinor,
      appliedMinor: applied,
      refundedMinor: row.refundedMinor,
      refundMethod: row.refundMethod,
      refundedAt: row.refundedAt,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<int> _appliedTotal(int debitNoteId) async {
    final rows = await (database.select(
      database.debitNoteApplications,
    )..where((table) => table.debitNoteId.equals(debitNoteId))).get();
    return rows.fold<int>(0, (total, row) => total + row.amountMinor);
  }

  static int _baseMinor(int quantityScaled, int rateMinor) =>
      ((quantityScaled / 1000) * rateMinor).round();

  static int _taxMinor(int baseMinor, int taxRateBasisPoints) =>
      (baseMinor * taxRateBasisPoints / 10000).round();

  static (int cgst, int sgst, int igst) _splitTax(String taxMode, int tax) {
    if (taxMode == 'igst') return (0, 0, tax);
    if (taxMode == 'exempt') return (0, 0, 0);
    final cgst = tax ~/ 2;
    return (cgst, tax - cgst, 0);
  }
}

class _PreparedItem {
  const _PreparedItem({
    required this.purchaseItemId,
    required this.name,
    required this.quantityScaled,
    required this.unit,
    required this.rateMinor,
    required this.hsnSac,
    required this.taxRateBasisPoints,
  });

  final int? purchaseItemId;
  final String name;
  final int quantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
}
