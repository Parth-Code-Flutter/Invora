import 'package:drift/drift.dart';

import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../models/credit_note_model.dart';
import '../models/invoice_calculation_models.dart';
import '../models/invoice_model.dart';
import '../models/cash_book_models.dart';
import '../services/app_database.dart';
import '../services/invoice_calculation_service.dart';
import '../services/money_ledger.dart';
import '../services/stock_ledger.dart';
import '../models/stock_models.dart';
import 'base_repository.dart';
import 'invoice_repository.dart';

class CreditNoteRepository extends BaseRepository {
  CreditNoteRepository(super.database, this._invoices);

  final InvoiceRepository _invoices;
  static const _calculator = InvoiceCalculationService();

  Future<String> nextNumber() async {
    const prefix = 'CN';
    final rows = await (database.select(
      database.creditNotes,
    )..where((table) => table.creditNoteNumber.like('$prefix-%'))).get();
    var next = 1;
    for (final row in rows) {
      final value = int.tryParse(row.creditNoteNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  Future<List<CreditNoteSummaryModel>> listForInvoice(int invoiceId) async {
    final rows =
        await (database.select(database.creditNotes)
              ..where((table) => table.invoiceId.equals(invoiceId))
              ..orderBy([(table) => OrderingTerm.desc(table.creditNoteDate)]))
            .get();
    return Future.wait(rows.map(_toSummary));
  }

  Future<List<CreditNoteSummaryModel>> listForCustomer(int customerId) async {
    final rows =
        await (database.select(database.creditNotes)
              ..where((table) => table.customerId.equals(customerId))
              ..orderBy([(table) => OrderingTerm.desc(table.creditNoteDate)]))
            .get();
    return Future.wait(rows.map(_toSummary));
  }

  Future<List<CreditNoteModel>> listInRange(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final rows =
        await (database.select(database.creditNotes)
              ..where(
                (table) =>
                    table.creditNoteDate.isBiggerOrEqualValue(start) &
                    table.creditNoteDate.isSmallerOrEqualValue(end),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.creditNoteDate)]))
            .get();
    return Future.wait(rows.map(_load));
  }

  Future<List<CreditNoteSummaryModel>> unappliedForCustomer(
    int customerId,
  ) async {
    final rows =
        await (database.select(database.creditNotes)
              ..where((table) => table.customerId.equals(customerId))
              ..orderBy([(table) => OrderingTerm.desc(table.creditNoteDate)]))
            .get();
    final summaries = await Future.wait(rows.map(_toSummary));
    return summaries.where((note) => note.unappliedMinor > 0).toList();
  }

  Future<CreditNoteModel?> getById(int id) async {
    final row = await (database.select(
      database.creditNotes,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<Map<int, int>> returnedQuantityByItem(int invoiceId) async {
    final notes = await (database.select(
      database.creditNotes,
    )..where((table) => table.invoiceId.equals(invoiceId))).get();
    final returned = <int, int>{};
    for (final note in notes) {
      final items = await (database.select(
        database.creditNoteItems,
      )..where((table) => table.creditNoteId.equals(note.id))).get();
      for (final item in items) {
        final sourceId = item.invoiceItemId;
        if (sourceId == null) continue;
        returned[sourceId] = (returned[sourceId] ?? 0) + item.quantityScaled;
      }
    }
    return returned;
  }

  Future<int> creditedValueForInvoice(int invoiceId) async {
    final notes = await (database.select(
      database.creditNotes,
    )..where((table) => table.invoiceId.equals(invoiceId))).get();
    return notes.fold<int>(0, (total, note) => total + note.grandTotalMinor);
  }

  Future<CreditNoteModel> issue({
    required InvoiceModel invoice,
    required DateTime creditNoteDate,
    required String reason,
    required List<CreditNoteItemDraft> returnedItems,
    int? valueAdjustmentMinor,
    int valueAdjustmentTaxRateBasisPoints = 0,
    required CreditNoteRemainderAction remainder,
    String? refundMethod,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('A credit note reason is required.');
    }
    if (invoice.id == null) throw StateError('Invoice is not saved.');
    if (invoice.documentType != DocumentType.invoice) {
      throw StateError('Credit notes can only be issued against invoices.');
    }
    if (invoice.status == InvoiceStatus.draft ||
        invoice.status == InvoiceStatus.cancelled) {
      throw StateError('This invoice cannot receive a credit note.');
    }
    final dateOnly = DateTime(
      creditNoteDate.year,
      creditNoteDate.month,
      creditNoteDate.day,
    );
    final invoiceDay = DateTime(
      invoice.invoiceDate.year,
      invoice.invoiceDate.month,
      invoice.invoiceDate.day,
    );
    if (dateOnly.isBefore(invoiceDay)) {
      throw ArgumentError('Credit note date cannot precede the invoice date.');
    }

    final alreadyReturned = await returnedQuantityByItem(invoice.id!);
    final alreadyCredited = await creditedValueForInvoice(invoice.id!);
    final remainingValue =
        invoice.calculation.grandTotalMinor - alreadyCredited;
    if (remainingValue <= 0) {
      throw StateError('This invoice has already been fully credited.');
    }

    final items = <InvoiceCalculationItemInput>[];
    final snapshots = <_PreparedItem>[];
    for (final draft in returnedItems) {
      if (draft.returnedQuantityScaled <= 0) continue;
      final sourceId = draft.invoiceItem.id;
      if (sourceId == null) {
        throw StateError('Returned lines must belong to the original invoice.');
      }
      final prior = alreadyReturned[sourceId] ?? 0;
      if (draft.returnedQuantityScaled + prior > draft.originalQuantityScaled) {
        throw ArgumentError(
          'Returned quantity cannot exceed the original line.',
        );
      }
      items.add(
        InvoiceCalculationItemInput(
          id: 'item-$sourceId',
          quantityScaled: draft.returnedQuantityScaled,
          rateMinor: draft.invoiceItem.rateMinor,
          discount: draft.invoiceItem.discount,
          taxRateBasisPoints: draft.invoiceItem.taxRateBasisPoints,
        ),
      );
      snapshots.add(
        _PreparedItem(
          invoiceItemId: sourceId,
          item: draft.invoiceItem,
          quantityScaled: draft.returnedQuantityScaled,
        ),
      );
    }
    if (valueAdjustmentMinor != null) {
      if (valueAdjustmentMinor <= 0) {
        throw ArgumentError('Value adjustment must be greater than zero.');
      }
      items.add(
        InvoiceCalculationItemInput(
          id: 'adjustment',
          quantityScaled: 1000,
          rateMinor: valueAdjustmentMinor,
          taxRateBasisPoints: valueAdjustmentTaxRateBasisPoints,
        ),
      );
      snapshots.add(
        _PreparedItem(
          invoiceItemId: null,
          item: InvoiceItemModel(
            localId: 'adjustment',
            name: 'Value adjustment',
            quantityScaled: 1000,
            unit: 'adjustment',
            rateMinor: valueAdjustmentMinor,
            taxRateBasisPoints: valueAdjustmentTaxRateBasisPoints,
          ),
          quantityScaled: 1000,
        ),
      );
    }
    if (items.isEmpty) {
      throw ArgumentError('Select returned quantities or a value adjustment.');
    }

    final calculation = _calculator.calculate(
      InvoiceCalculationInput(items: items, taxType: invoice.taxType),
    );
    if (calculation.grandTotalMinor > remainingValue) {
      throw ArgumentError(
        'This credit note would exceed the remaining invoice value.',
      );
    }

    return database.transaction(() async {
      final now = DateTime.now();
      final number = await nextNumber();
      final creditNoteId = await database
          .into(database.creditNotes)
          .insert(
            CreditNotesCompanion.insert(
              creditNoteNumber: number,
              invoiceId: invoice.id!,
              customerId: Value(invoice.customer.customerId),
              customerName: invoice.customer.name,
              creditNoteDate: dateOnly,
              reason: normalizedReason,
              taxType: invoice.taxType.name,
              subtotalMinor: calculation.subtotalMinor,
              itemDiscountMinor: Value(calculation.itemDiscountTotalMinor),
              taxableMinor: calculation.taxableTotalMinor,
              taxMinor: calculation.taxTotalMinor,
              cgstMinor: calculation.cgstMinor,
              sgstMinor: calculation.sgstMinor,
              igstMinor: calculation.igstMinor,
              roundOffMinor: Value(calculation.roundOffMinor),
              grandTotalMinor: calculation.grandTotalMinor,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      for (var index = 0; index < snapshots.length; index++) {
        final snapshot = snapshots[index];
        final result = calculation.items[index];
        await database
            .into(database.creditNoteItems)
            .insert(
              CreditNoteItemsCompanion.insert(
                creditNoteId: creditNoteId,
                invoiceItemId: Value(snapshot.invoiceItemId),
                name: snapshot.item.name,
                description: Value(snapshot.item.description),
                quantityScaled: snapshot.quantityScaled,
                unit: snapshot.item.unit,
                rateMinor: snapshot.item.rateMinor,
                hsnSac: Value(snapshot.item.hsnSac),
                taxRateBasisPoints: snapshot.item.taxRateBasisPoints,
                discountType: snapshot.item.discount.type.name,
                discountValue: Value(
                  discountStorageValue(snapshot.item.discount),
                ),
                baseAmountMinor: result.baseMinor,
                discountAmountMinor: result.discountMinor,
                taxableAmountMinor: result.taxableMinor,
                taxAmountMinor: result.taxMinor,
                totalMinor: result.totalMinor,
                sortOrder: index,
              ),
            );
      }

      final latest = await _invoices.getById(invoice.id!);
      if (latest == null) throw StateError('Invoice not found.');
      final applyAmount =
          calculation.grandTotalMinor < latest.calculation.balanceDueMinor
          ? calculation.grandTotalMinor
          : latest.calculation.balanceDueMinor;
      if (applyAmount > 0) {
        await database
            .into(database.creditNoteApplications)
            .insert(
              CreditNoteApplicationsCompanion.insert(
                creditNoteId: creditNoteId,
                invoiceId: invoice.id!,
                amountMinor: applyAmount,
                appliedAt: now,
              ),
            );
        await _invoices.applyCredit(
          invoiceId: invoice.id!,
          amountMinor: applyAmount,
        );
      }

      final leftover = calculation.grandTotalMinor - applyAmount;
      if (leftover > 0 &&
          remainder == CreditNoteRemainderAction.applyThenRefund) {
        await (database.update(
          database.creditNotes,
        )..where((table) => table.id.equals(creditNoteId))).write(
          CreditNotesCompanion(
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
          sourceType: MoneySourceType.creditNote,
          sourceId: creditNoteId,
          amountMinor: leftover,
          occurredAt: now,
          direction: MoneyDirection.outbound,
          entryType: MoneyEntryType.refund,
          method: refundMethod,
          note: 'Credit note refund',
        );
      }

      await StockLedger(database).replaceSource(
        sourceType: StockSourceType.creditNote,
        sourceId: creditNoteId,
        type: StockMovementType.creditNote,
        lines: [
          for (final snapshot in snapshots)
            if (snapshot.item.productId != null)
              StockLine(
                productId: snapshot.item.productId!,
                quantityScaled: snapshot.quantityScaled,
              ),
        ],
      );

      return (await getById(creditNoteId))!;
    });
  }

  Future<void> applyUnapplied({
    required int creditNoteId,
    required int invoiceId,
    required int amountMinor,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Credit amount must be greater than zero.');
    }
    await database.transaction(() async {
      final note = await getById(creditNoteId);
      if (note == null) throw StateError('Credit note not found.');
      if (amountMinor > note.unappliedMinor) {
        throw ArgumentError('Amount exceeds the remaining customer credit.');
      }
      final invoice = await _invoices.getById(invoiceId);
      if (invoice == null) throw StateError('Invoice not found.');
      if (invoice.customer.customerId != note.customerId) {
        throw StateError('Credit can only be applied to the same customer.');
      }
      await database
          .into(database.creditNoteApplications)
          .insert(
            CreditNoteApplicationsCompanion.insert(
              creditNoteId: creditNoteId,
              invoiceId: invoiceId,
              amountMinor: amountMinor,
              appliedAt: DateTime.now(),
            ),
          );
      await _invoices.applyCredit(
        invoiceId: invoiceId,
        amountMinor: amountMinor,
      );
    });
  }

  Future<CreditNoteSummaryModel> _toSummary(CreditNote row) async {
    final invoice = await (database.select(
      database.invoices,
    )..where((table) => table.id.equals(row.invoiceId))).getSingle();
    final applied = await _appliedTotal(row.id);
    return CreditNoteSummaryModel(
      id: row.id,
      creditNoteNumber: row.creditNoteNumber,
      invoiceId: row.invoiceId,
      invoiceNumber: invoice.invoiceNumber,
      customerName: row.customerName,
      creditNoteDate: row.creditNoteDate,
      reason: row.reason,
      grandTotalMinor: row.grandTotalMinor,
      appliedMinor: applied,
      refundedMinor: row.refundedMinor,
    );
  }

  Future<CreditNoteModel> _load(CreditNote row) async {
    final invoice = await (database.select(
      database.invoices,
    )..where((table) => table.id.equals(row.invoiceId))).getSingle();
    final itemRows =
        await (database.select(database.creditNoteItems)
              ..where((table) => table.creditNoteId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final applied = await _appliedTotal(row.id);
    return CreditNoteModel(
      id: row.id,
      creditNoteNumber: row.creditNoteNumber,
      invoiceId: row.invoiceId,
      invoiceNumber: invoice.invoiceNumber,
      customerId: row.customerId,
      customerName: row.customerName,
      creditNoteDate: row.creditNoteDate,
      reason: row.reason,
      taxType: TaxType.values.byName(row.taxType),
      items: itemRows
          .map(
            (item) => CreditNoteItemModel(
              id: item.id,
              invoiceItemId: item.invoiceItemId,
              name: item.name,
              description: item.description,
              quantityScaled: item.quantityScaled,
              unit: item.unit,
              rateMinor: item.rateMinor,
              hsnSac: item.hsnSac,
              taxRateBasisPoints: item.taxRateBasisPoints,
              discount: discountFromStorage(
                DiscountType.values.byName(item.discountType),
                item.discountValue,
              ),
              baseAmountMinor: item.baseAmountMinor,
              discountAmountMinor: item.discountAmountMinor,
              taxableAmountMinor: item.taxableAmountMinor,
              taxAmountMinor: item.taxAmountMinor,
              totalMinor: item.totalMinor,
            ),
          )
          .toList(),
      subtotalMinor: row.subtotalMinor,
      itemDiscountMinor: row.itemDiscountMinor,
      taxableMinor: row.taxableMinor,
      taxMinor: row.taxMinor,
      cgstMinor: row.cgstMinor,
      sgstMinor: row.sgstMinor,
      igstMinor: row.igstMinor,
      roundOffMinor: row.roundOffMinor,
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

  Future<int> _appliedTotal(int creditNoteId) async {
    final rows = await (database.select(
      database.creditNoteApplications,
    )..where((table) => table.creditNoteId.equals(creditNoteId))).get();
    return rows.fold<int>(0, (total, row) => total + row.amountMinor);
  }
}

class _PreparedItem {
  const _PreparedItem({
    required this.invoiceItemId,
    required this.item,
    required this.quantityScaled,
  });

  final int? invoiceItemId;
  final InvoiceItemModel item;
  final int quantityScaled;
}
