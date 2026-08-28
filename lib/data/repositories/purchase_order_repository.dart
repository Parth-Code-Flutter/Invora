import 'package:drift/drift.dart';

import '../../app/utils/quantity_utils.dart';
import '../models/purchase_models.dart';
import '../models/purchase_order_model.dart';
import '../services/app_database.dart';
import 'base_repository.dart';
import 'purchase_repository.dart';

class PurchaseOrderQuantityUpdate {
  const PurchaseOrderQuantityUpdate({
    required this.itemId,
    required this.receivedQuantityScaled,
    required this.returnedQuantityScaled,
  });

  final int itemId;
  final int receivedQuantityScaled;
  final int returnedQuantityScaled;
}

class PurchaseOrderConvertLine {
  const PurchaseOrderConvertLine({
    required this.itemId,
    required this.quantityScaled,
  });

  final int itemId;
  final int quantityScaled;
}

class PurchaseOrderRepository extends BaseRepository {
  PurchaseOrderRepository(super.database, this._purchases);

  final PurchaseRepository _purchases;

  Future<String> nextNumber() async {
    const prefix = 'PO';
    final rows = await (database.select(
      database.purchaseOrders,
    )..where((table) => table.orderNumber.like('$prefix-%'))).get();
    var next = 1;
    for (final row in rows) {
      final value = int.tryParse(row.orderNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  Stream<List<PurchaseOrderSummaryModel>> watchAll() {
    final statement = database.select(database.purchaseOrders)
      ..orderBy([(table) => OrderingTerm.desc(table.orderDate)]);
    return statement.watch().asyncMap((rows) async {
      final summaries = <PurchaseOrderSummaryModel>[];
      for (final row in rows) {
        final count =
            await (database.select(database.purchaseOrderItems)
                  ..where((table) => table.orderId.equals(row.id)))
                .get()
                .then((items) => items.length);
        summaries.add(_toSummary(row, count));
      }
      return summaries;
    });
  }

  Future<PurchaseOrderModel?> getById(int id) async {
    final row = await (database.select(
      database.purchaseOrders,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<PurchaseOrderModel> save(
    PurchaseOrderModel model, {
    required bool asDraft,
  }) async {
    final name = model.supplier.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Choose a supplier.');
    }
    if (model.supplier.id == null) {
      throw ArgumentError('Choose a supplier.');
    }
    if (model.items.isEmpty ||
        model.items.every((item) => item.orderedQuantityScaled <= 0)) {
      throw ArgumentError('Add at least one item with an ordered quantity.');
    }
    for (final item in model.items) {
      if (item.name.trim().isEmpty) {
        throw ArgumentError('Every item needs a name.');
      }
      if (item.orderedQuantityScaled <= 0) {
        throw ArgumentError('Ordered quantity must be greater than zero.');
      }
      if (item.receivedQuantityScaled < 0 ||
          item.returnedQuantityScaled < 0 ||
          item.billedQuantityScaled < 0) {
        throw ArgumentError('Quantities cannot be negative.');
      }
      if (item.receivedQuantityScaled > item.orderedQuantityScaled) {
        throw ArgumentError('Received quantity cannot exceed ordered.');
      }
      if (item.returnedQuantityScaled > item.receivedQuantityScaled) {
        throw ArgumentError('Returned quantity cannot exceed received.');
      }
      if (item.billedQuantityScaled >
          item.receivedQuantityScaled - item.returnedQuantityScaled) {
        throw ArgumentError(
          'Billed quantity cannot exceed remaining received quantity.',
        );
      }
    }

    return database.transaction(() async {
      if (model.id != null) {
        final existing = await getById(model.id!);
        if (existing == null) {
          throw ArgumentError('This purchase order could not be found.');
        }
        if (existing.isCancelled) {
          throw ArgumentError('Cancelled purchase orders cannot be edited.');
        }
        if (!existing.canEdit) {
          throw ArgumentError(
            'This purchase order has bills and cannot be edited.',
          );
        }
      }
      final now = DateTime.now();
      final number = model.orderNumber.trim().isEmpty
          ? await nextNumber()
          : model.orderNumber.trim();
      final date = _dateOnly(model.orderDate);
      final expected = model.expectedDate == null
          ? null
          : _dateOnly(model.expectedDate!);
      final keepDraft =
          asDraft &&
          model.items.every(
            (item) =>
                item.receivedQuantityScaled == 0 &&
                item.billedQuantityScaled == 0,
          );
      final status = keepDraft
          ? PurchaseOrderStatus.draft
          : _derivedStatus(items: model.items);
      final companion = PurchaseOrdersCompanion(
        id: model.id == null ? const Value.absent() : Value(model.id!),
        orderNumber: Value(number),
        supplierId: Value(model.supplier.id!),
        supplierName: Value(name),
        supplierCompany: Value(_emptyToNull(model.supplier.companyName)),
        supplierMobile: Value(_emptyToNull(model.supplier.mobile)),
        supplierEmail: Value(_emptyToNull(model.supplier.email)),
        supplierGstin: Value(_emptyToNull(model.supplier.gstin)),
        supplierAddress: Value(_emptyToNull(model.supplier.address)),
        orderDate: Value(date),
        expectedDate: Value(expected),
        status: Value(status.name),
        taxMode: Value(model.taxMode),
        terms: Value(_emptyToNull(model.terms)),
        notes: Value(_emptyToNull(model.notes)),
        cancellationReason: const Value(null),
        cancelledAt: const Value(null),
        createdAt: Value(model.id == null ? now : model.createdAt),
        updatedAt: Value(now),
      );
      final id = model.id == null
          ? await database.into(database.purchaseOrders).insert(companion)
          : await () async {
              await (database.update(
                database.purchaseOrders,
              )..where((table) => table.id.equals(model.id!))).write(companion);
              await (database.delete(
                database.purchaseOrderItems,
              )..where((table) => table.orderId.equals(model.id!))).go();
              return model.id!;
            }();
      for (var index = 0; index < model.items.length; index++) {
        final item = model.items[index];
        await database
            .into(database.purchaseOrderItems)
            .insert(
              PurchaseOrderItemsCompanion.insert(
                orderId: id,
                productId: Value(item.productId),
                name: item.name.trim(),
                description: Value(_emptyToNull(item.description)),
                orderedQuantityScaled: item.orderedQuantityScaled,
                receivedQuantityScaled: Value(item.receivedQuantityScaled),
                returnedQuantityScaled: Value(item.returnedQuantityScaled),
                billedQuantityScaled: Value(item.billedQuantityScaled),
                unit: item.unit.trim().isEmpty ? 'pcs' : item.unit.trim(),
                rateMinor: item.rateMinor,
                hsnSac: Value(_emptyToNull(item.hsnSac)),
                taxRateBasisPoints: Value(item.taxRateBasisPoints),
                sortOrder: index,
              ),
            );
      }
      return (await getById(id))!;
    });
  }

  Future<PurchaseOrderModel> recordQuantities({
    required int orderId,
    required List<PurchaseOrderQuantityUpdate> updates,
  }) async {
    return database.transaction(() async {
      final current = await getById(orderId);
      if (current == null) {
        throw ArgumentError('This purchase order could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('Cancelled purchase orders cannot be updated.');
      }
      if (current.isDraft) {
        throw ArgumentError(
          'Issue this purchase order before recording goods.',
        );
      }
      if (updates.isEmpty) {
        throw ArgumentError('Enter received or returned quantities.');
      }
      for (final update in updates) {
        final item = current.items.where((row) => row.id == update.itemId);
        if (item.isEmpty) {
          throw ArgumentError(
            'An item on this purchase order could not be found.',
          );
        }
        final line = item.single;
        if (update.receivedQuantityScaled < 0 ||
            update.returnedQuantityScaled < 0) {
          throw ArgumentError('Quantities cannot be negative.');
        }
        if (update.receivedQuantityScaled > line.orderedQuantityScaled) {
          throw ArgumentError('Received quantity cannot exceed ordered.');
        }
        if (update.returnedQuantityScaled > update.receivedQuantityScaled) {
          throw ArgumentError('Returned quantity cannot exceed received.');
        }
        if (line.billedQuantityScaled >
            update.receivedQuantityScaled - update.returnedQuantityScaled) {
          throw ArgumentError(
            'Returned quantity would leave billed goods unaccounted for.',
          );
        }
        await (database.update(
          database.purchaseOrderItems,
        )..where((table) => table.id.equals(update.itemId))).write(
          PurchaseOrderItemsCompanion(
            receivedQuantityScaled: Value(update.receivedQuantityScaled),
            returnedQuantityScaled: Value(update.returnedQuantityScaled),
          ),
        );
      }
      final refreshed = (await getById(orderId))!;
      await _writeStatus(orderId, _derivedStatus(items: refreshed.items));
      return (await getById(orderId))!;
    });
  }

  Future<PurchaseBillModel> convertToBill({
    required int orderId,
    required String billNumber,
    required List<PurchaseOrderConvertLine> lines,
    DateTime? billDate,
    DateTime? dueDate,
  }) async {
    return database.transaction(() async {
      final current = await getById(orderId);
      if (current == null) {
        throw ArgumentError('This purchase order could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('Cancelled purchase orders cannot be converted.');
      }
      if (current.isDraft) {
        throw ArgumentError('Issue this purchase order before converting.');
      }
      final number = billNumber.trim();
      if (number.isEmpty) {
        throw ArgumentError('Enter the supplier bill number.');
      }
      final date = _dateOnly(billDate ?? DateTime.now());
      final available = await _purchases.isBillNumberAvailable(
        number,
        supplierId: current.supplier.id,
        billDate: date,
      );
      if (!available) {
        throw ArgumentError(
          'This supplier already has a bill with that number this year.',
        );
      }
      final selected = <({PurchaseOrderItemModel item, int quantityScaled})>[];
      for (final line in lines) {
        if (line.quantityScaled <= 0) continue;
        final match = current.items.where((item) => item.id == line.itemId);
        if (match.isEmpty) {
          throw ArgumentError(
            'An item on this purchase order could not be found.',
          );
        }
        final item = match.single;
        if (line.quantityScaled > item.remainingToBillScaled) {
          throw ArgumentError(
            'Cannot bill more than remaining received quantity.',
          );
        }
        selected.add((item: item, quantityScaled: line.quantityScaled));
      }
      if (selected.isEmpty) {
        throw ArgumentError('Choose remaining quantity to bill.');
      }

      final now = DateTime.now();
      final billId = await _purchases.saveBill(
        PurchaseBillModel(
          billNumber: number,
          supplierId: current.supplier.id,
          supplierName: current.supplier.name,
          billDate: date,
          dueDate: dueDate == null ? null : _dateOnly(dueDate),
          items: [
            for (final line in selected)
              PurchaseItemModel(
                productId: line.item.productId,
                name: line.item.name,
                quantity: line.quantityScaled / QuantityUtils.scale,
                unit: line.item.unit,
                hsnSac: line.item.hsnSac,
                rateMinor: line.item.rateMinor,
                taxRate: line.item.taxRateBasisPoints / 100,
              ),
          ],
          notes: 'From purchase order ${current.orderNumber}',
          taxMode: current.taxMode,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final bill = await _purchases.getBill(billId);
      if (bill == null) {
        throw ArgumentError('The purchase bill could not be created.');
      }
      await database
          .into(database.purchaseOrderBills)
          .insert(
            PurchaseOrderBillsCompanion.insert(
              orderId: orderId,
              purchaseBillId: billId,
              convertedAt: now,
            ),
          );
      for (final line in selected) {
        await (database.update(
          database.purchaseOrderItems,
        )..where((table) => table.id.equals(line.item.id!))).write(
          PurchaseOrderItemsCompanion(
            billedQuantityScaled: Value(
              line.item.billedQuantityScaled + line.quantityScaled,
            ),
          ),
        );
      }
      final refreshed = (await getById(orderId))!;
      await _writeStatus(orderId, _derivedStatus(items: refreshed.items));
      return bill;
    });
  }

  Future<PurchaseOrderModel> cancel({
    required int orderId,
    required String reason,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter a cancellation reason.');
    }
    return database.transaction(() async {
      final current = await getById(orderId);
      if (current == null) {
        throw ArgumentError('This purchase order could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('This purchase order is already cancelled.');
      }
      if (!current.canCancel) {
        throw ArgumentError(
          'This purchase order has bills and cannot be cancelled.',
        );
      }
      final now = DateTime.now();
      await (database.update(
        database.purchaseOrders,
      )..where((table) => table.id.equals(orderId))).write(
        PurchaseOrdersCompanion(
          status: Value(PurchaseOrderStatus.cancelled.name),
          cancellationReason: Value(trimmed),
          cancelledAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return (await getById(orderId))!;
    });
  }

  Future<void> _writeStatus(int orderId, PurchaseOrderStatus status) {
    return (database.update(
      database.purchaseOrders,
    )..where((table) => table.id.equals(orderId))).write(
      PurchaseOrdersCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<PurchaseOrderModel> _load(PurchaseOrder row) async {
    final itemRows =
        await (database.select(database.purchaseOrderItems)
              ..where((table) => table.orderId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final conversionRows =
        await (database.select(database.purchaseOrderBills)
              ..where((table) => table.orderId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.desc(table.convertedAt)]))
            .get();
    final conversions = <PurchaseOrderConversionModel>[];
    for (final conversion in conversionRows) {
      final bill = await _purchases.getBill(conversion.purchaseBillId);
      conversions.add(
        PurchaseOrderConversionModel(
          purchaseBillId: conversion.purchaseBillId,
          billNumber: bill?.billNumber ?? 'Purchase bill',
          convertedAt: conversion.convertedAt,
        ),
      );
    }
    return PurchaseOrderModel(
      id: row.id,
      orderNumber: row.orderNumber,
      supplier: SupplierModel(
        id: row.supplierId,
        name: row.supplierName,
        companyName: row.supplierCompany,
        mobile: row.supplierMobile,
        email: row.supplierEmail,
        gstin: row.supplierGstin,
        address: row.supplierAddress,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      ),
      orderDate: row.orderDate,
      expectedDate: row.expectedDate,
      status: PurchaseOrderStatus.values.byName(row.status),
      taxMode: row.taxMode,
      terms: row.terms,
      notes: row.notes,
      cancellationReason: row.cancellationReason,
      cancelledAt: row.cancelledAt,
      items: [
        for (final item in itemRows)
          PurchaseOrderItemModel(
            localId: 'po-${item.id}',
            id: item.id,
            productId: item.productId,
            name: item.name,
            description: item.description,
            orderedQuantityScaled: item.orderedQuantityScaled,
            receivedQuantityScaled: item.receivedQuantityScaled,
            returnedQuantityScaled: item.returnedQuantityScaled,
            billedQuantityScaled: item.billedQuantityScaled,
            unit: item.unit,
            rateMinor: item.rateMinor,
            hsnSac: item.hsnSac,
            taxRateBasisPoints: item.taxRateBasisPoints,
          ),
      ],
      conversions: conversions,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PurchaseOrderSummaryModel _toSummary(PurchaseOrder row, int itemCount) {
    return PurchaseOrderSummaryModel(
      id: row.id,
      orderNumber: row.orderNumber,
      supplierName: row.supplierName,
      orderDate: row.orderDate,
      status: PurchaseOrderStatus.values.byName(row.status),
      itemCount: itemCount,
    );
  }

  PurchaseOrderStatus _derivedStatus({
    required List<PurchaseOrderItemModel> items,
    bool cancelled = false,
  }) {
    if (cancelled) return PurchaseOrderStatus.cancelled;
    final remainingReceive = items.fold<int>(
      0,
      (total, item) => total + item.remainingToReceiveScaled,
    );
    final remainingBill = items.fold<int>(
      0,
      (total, item) => total + item.remainingToBillScaled,
    );
    final received = items.fold<int>(
      0,
      (total, item) => total + item.receivedQuantityScaled,
    );
    final billed = items.fold<int>(
      0,
      (total, item) => total + item.billedQuantityScaled,
    );
    if (billed > 0 && remainingReceive == 0 && remainingBill == 0) {
      return PurchaseOrderStatus.billed;
    }
    if (billed > 0) return PurchaseOrderStatus.partBilled;
    if (received > 0 && remainingReceive == 0) {
      return PurchaseOrderStatus.received;
    }
    if (received > 0) return PurchaseOrderStatus.partReceived;
    return PurchaseOrderStatus.open;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
