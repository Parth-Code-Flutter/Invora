import 'package:drift/drift.dart';

import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../models/delivery_challan_model.dart';
import '../models/invoice_calculation_models.dart';
import '../models/invoice_model.dart';
import '../services/app_database.dart';
import '../services/invoice_calculation_service.dart';
import 'base_repository.dart';
import 'invoice_repository.dart';

class DeliveryChallanQuantityUpdate {
  const DeliveryChallanQuantityUpdate({
    required this.itemId,
    required this.deliveredQuantityScaled,
    required this.returnedQuantityScaled,
  });

  final int itemId;
  final int deliveredQuantityScaled;
  final int returnedQuantityScaled;
}

class DeliveryChallanConvertLine {
  const DeliveryChallanConvertLine({
    required this.itemId,
    required this.quantityScaled,
  });

  final int itemId;
  final int quantityScaled;
}

class DeliveryChallanRepository extends BaseRepository {
  DeliveryChallanRepository(super.database, this._invoices);

  final InvoiceRepository _invoices;
  static const _calculator = InvoiceCalculationService();

  Future<String> nextNumber() async {
    const prefix = 'DC';
    final rows = await (database.select(
      database.deliveryChallans,
    )..where((table) => table.challanNumber.like('$prefix-%'))).get();
    var next = 1;
    for (final row in rows) {
      final value = int.tryParse(row.challanNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  Stream<List<DeliveryChallanSummaryModel>> watchAll() {
    final statement = database.select(database.deliveryChallans)
      ..orderBy([(table) => OrderingTerm.desc(table.challanDate)]);
    return statement.watch().asyncMap((rows) async {
      final summaries = <DeliveryChallanSummaryModel>[];
      for (final row in rows) {
        final count =
            await (database.select(database.deliveryChallanItems)
                  ..where((table) => table.challanId.equals(row.id)))
                .get()
                .then((items) => items.length);
        summaries.add(_toSummary(row, count));
      }
      return summaries;
    });
  }

  Future<DeliveryChallanModel?> getById(int id) async {
    final row = await (database.select(
      database.deliveryChallans,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<DeliveryChallanModel> save(
    DeliveryChallanModel model, {
    required bool asDraft,
  }) async {
    final name = model.customer.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Choose a customer.');
    }
    if (model.items.isEmpty ||
        model.items.every((item) => item.dispatchedQuantityScaled <= 0)) {
      throw ArgumentError('Add at least one item with a dispatched quantity.');
    }
    for (final item in model.items) {
      if (item.name.trim().isEmpty) {
        throw ArgumentError('Every item needs a name.');
      }
      if (item.dispatchedQuantityScaled <= 0) {
        throw ArgumentError('Dispatched quantity must be greater than zero.');
      }
      if (item.orderedQuantityScaled < 0 ||
          item.deliveredQuantityScaled < 0 ||
          item.returnedQuantityScaled < 0 ||
          item.invoicedQuantityScaled < 0) {
        throw ArgumentError('Quantities cannot be negative.');
      }
      if (item.deliveredQuantityScaled > item.dispatchedQuantityScaled) {
        throw ArgumentError('Delivered quantity cannot exceed dispatched.');
      }
      if (item.returnedQuantityScaled > item.dispatchedQuantityScaled) {
        throw ArgumentError('Returned quantity cannot exceed dispatched.');
      }
      if (item.invoicedQuantityScaled >
          item.dispatchedQuantityScaled - item.returnedQuantityScaled) {
        throw ArgumentError(
          'Invoiced quantity cannot exceed remaining dispatched quantity.',
        );
      }
    }
    await _assertRemainingDispatch(model);

    return database.transaction(() async {
      if (model.id != null) {
        final existing = await getById(model.id!);
        if (existing == null) {
          throw ArgumentError('This delivery challan could not be found.');
        }
        if (existing.isCancelled) {
          throw ArgumentError('Cancelled challans cannot be edited.');
        }
        if (!existing.canEdit) {
          throw ArgumentError(
            'This challan has invoices and cannot be edited.',
          );
        }
      }
      final now = DateTime.now();
      final number = model.challanNumber.trim().isEmpty
          ? await nextNumber()
          : model.challanNumber.trim();
      final date = _dateOnly(model.challanDate);
      final status = asDraft
          ? DeliveryChallanStatus.draft
          : _derivedStatus(
              items: model.items,
              cancelled: false,
              preferDraft: false,
            );
      final companion = DeliveryChallansCompanion(
        id: model.id == null ? const Value.absent() : Value(model.id!),
        challanNumber: Value(number),
        customerId: Value(model.customer.customerId),
        customerName: Value(name),
        customerCompany: Value(_emptyToNull(model.customer.companyName)),
        customerMobile: Value(_emptyToNull(model.customer.mobile)),
        customerEmail: Value(_emptyToNull(model.customer.email)),
        customerAddress: Value(_emptyToNull(model.customer.address)),
        customerCity: Value(_emptyToNull(model.customer.city)),
        customerState: Value(_emptyToNull(model.customer.state)),
        customerPinCode: Value(_emptyToNull(model.customer.pinCode)),
        customerGstin: Value(_emptyToNull(model.customer.gstin)),
        sourceType: Value(model.sourceType.name),
        sourceId: Value(model.sourceId),
        challanDate: Value(date),
        dispatchDate: Value(
          model.dispatchDate == null ? null : _dateOnly(model.dispatchDate!),
        ),
        status: Value(status.name),
        movementReason: Value(model.movementReason.name),
        movementReasonNote: Value(_emptyToNull(model.movementReasonNote)),
        dispatchAddress: Value(_emptyToNull(model.dispatchAddress)),
        dispatchCity: Value(_emptyToNull(model.dispatchCity)),
        dispatchState: Value(_emptyToNull(model.dispatchState)),
        dispatchPinCode: Value(_emptyToNull(model.dispatchPinCode)),
        deliveryAddress: Value(_emptyToNull(model.deliveryAddress)),
        deliveryCity: Value(_emptyToNull(model.deliveryCity)),
        deliveryState: Value(_emptyToNull(model.deliveryState)),
        deliveryPinCode: Value(_emptyToNull(model.deliveryPinCode)),
        transporterName: Value(_emptyToNull(model.transporterName)),
        transporterId: Value(_emptyToNull(model.transporterId)),
        vehicleNumber: Value(_emptyToNull(model.vehicleNumber)),
        transportDocumentNumber: Value(
          _emptyToNull(model.transportDocumentNumber),
        ),
        transportDocumentDate: Value(
          model.transportDocumentDate == null
              ? null
              : _dateOnly(model.transportDocumentDate!),
        ),
        distanceKm: Value(model.distanceKm),
        ewayStatus: Value(model.ewayStatus.name),
        ewayNumber: Value(_emptyToNull(model.ewayNumber)),
        notes: Value(_emptyToNull(model.notes)),
        createdAt: Value(model.id == null ? now : model.createdAt),
        updatedAt: Value(now),
      );
      final id = model.id == null
          ? await database.into(database.deliveryChallans).insert(companion)
          : await () async {
              await (database.update(
                database.deliveryChallans,
              )..where((table) => table.id.equals(model.id!))).write(companion);
              await (database.delete(
                database.deliveryChallanItems,
              )..where((table) => table.challanId.equals(model.id!))).go();
              return model.id!;
            }();
      for (var index = 0; index < model.items.length; index++) {
        final item = model.items[index];
        await database
            .into(database.deliveryChallanItems)
            .insert(
              DeliveryChallanItemsCompanion.insert(
                challanId: id,
                productId: Value(item.productId),
                sourceItemId: Value(item.sourceItemId),
                name: item.name.trim(),
                description: Value(_emptyToNull(item.description)),
                orderedQuantityScaled: item.orderedQuantityScaled,
                dispatchedQuantityScaled: item.dispatchedQuantityScaled,
                deliveredQuantityScaled: Value(item.deliveredQuantityScaled),
                returnedQuantityScaled: Value(item.returnedQuantityScaled),
                invoicedQuantityScaled: Value(item.invoicedQuantityScaled),
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

  Future<DeliveryChallanModel> recordQuantities({
    required int challanId,
    required List<DeliveryChallanQuantityUpdate> updates,
  }) async {
    return database.transaction(() async {
      final current = await getById(challanId);
      if (current == null) {
        throw ArgumentError('This delivery challan could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('Cancelled challans cannot be updated.');
      }
      if (updates.isEmpty) {
        throw ArgumentError('Enter delivered or returned quantities.');
      }
      for (final update in updates) {
        final item = current.items.where((row) => row.id == update.itemId);
        if (item.isEmpty) {
          throw ArgumentError('An item on this challan could not be found.');
        }
        final line = item.single;
        if (update.deliveredQuantityScaled < 0 ||
            update.returnedQuantityScaled < 0) {
          throw ArgumentError('Quantities cannot be negative.');
        }
        if (update.deliveredQuantityScaled > line.dispatchedQuantityScaled) {
          throw ArgumentError('Delivered quantity cannot exceed dispatched.');
        }
        if (update.returnedQuantityScaled > line.dispatchedQuantityScaled) {
          throw ArgumentError('Returned quantity cannot exceed dispatched.');
        }
        if (line.invoicedQuantityScaled >
            line.dispatchedQuantityScaled - update.returnedQuantityScaled) {
          throw ArgumentError(
            'Returned quantity would leave invoiced goods unaccounted for.',
          );
        }
        await (database.update(
          database.deliveryChallanItems,
        )..where((table) => table.id.equals(update.itemId))).write(
          DeliveryChallanItemsCompanion(
            deliveredQuantityScaled: Value(update.deliveredQuantityScaled),
            returnedQuantityScaled: Value(update.returnedQuantityScaled),
          ),
        );
      }
      final refreshed = (await getById(challanId))!;
      await _writeStatus(challanId, _derivedStatus(items: refreshed.items));
      return (await getById(challanId))!;
    });
  }

  Future<DeliveryChallanModel> cancel({
    required int challanId,
    required String reason,
  }) async {
    final normalized = reason.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Enter a cancellation reason.');
    }
    return database.transaction(() async {
      final current = await getById(challanId);
      if (current == null) {
        throw ArgumentError('This delivery challan could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('This challan is already cancelled.');
      }
      if (!current.canCancel) {
        throw ArgumentError(
          'This challan has invoices and cannot be cancelled.',
        );
      }
      final now = DateTime.now();
      await (database.update(
        database.deliveryChallans,
      )..where((table) => table.id.equals(challanId))).write(
        DeliveryChallansCompanion(
          status: Value(DeliveryChallanStatus.cancelled.name),
          cancellationReason: Value(normalized),
          cancelledAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return (await getById(challanId))!;
    });
  }

  Future<DeliveryChallanModel> prepareEway(int challanId) async {
    final current = await getById(challanId);
    if (current == null) {
      throw ArgumentError('This delivery challan could not be found.');
    }
    if (current.isCancelled) {
      throw ArgumentError('Cancelled challans cannot prepare e-way fields.');
    }
    if (current.ewayStatus == EwayStatus.generated) {
      return current;
    }
    if (!current.hasTransportDetails) {
      throw ArgumentError(
        'Add a transporter or vehicle number before preparing e-way fields.',
      );
    }
    await (database.update(
      database.deliveryChallans,
    )..where((table) => table.id.equals(challanId))).write(
      DeliveryChallansCompanion(
        ewayStatus: Value(EwayStatus.prepared.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (await getById(challanId))!;
  }

  Future<DeliveryChallanModel> importEwayAcknowledgement({
    required int challanId,
    required String ewayNumber,
  }) async {
    final normalized = ewayNumber.trim();
    if (normalized.isEmpty) {
      throw ArgumentError(
        'Enter an e-way bill number from the portal acknowledgement.',
      );
    }
    final current = await getById(challanId);
    if (current == null) {
      throw ArgumentError('This delivery challan could not be found.');
    }
    if (current.isCancelled) {
      throw ArgumentError(
        'Cancelled challans cannot import an acknowledgement.',
      );
    }
    await (database.update(
      database.deliveryChallans,
    )..where((table) => table.id.equals(challanId))).write(
      DeliveryChallansCompanion(
        ewayStatus: Value(EwayStatus.generated.name),
        ewayNumber: Value(normalized),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (await getById(challanId))!;
  }

  Future<InvoiceModel> convertToInvoice({
    required int challanId,
    required List<DeliveryChallanConvertLine> lines,
    required String invoiceNumber,
    TaxType taxType = TaxType.cgstSgst,
    DateTime? invoiceDate,
    DateTime? dueDate,
  }) async {
    return database.transaction(() async {
      final current = await getById(challanId);
      if (current == null) {
        throw ArgumentError('This delivery challan could not be found.');
      }
      if (current.isCancelled) {
        throw ArgumentError('Cancelled challans cannot be converted.');
      }
      if (current.isAgainstInvoice) {
        throw ArgumentError(
          'This challan is against an invoice. Remaining quantity is for delivery, not another invoice.',
        );
      }
      if (current.movementReason != MovementReason.supply) {
        throw ArgumentError(
          'Non-sale movement cannot be converted to an invoice.',
        );
      }
      final selected =
          <({DeliveryChallanItemModel item, int quantityScaled})>[];
      for (final line in lines) {
        if (line.quantityScaled <= 0) continue;
        final match = current.items.where((item) => item.id == line.itemId);
        if (match.isEmpty) {
          throw ArgumentError('An item on this challan could not be found.');
        }
        final item = match.single;
        if (line.quantityScaled > item.remainingToInvoiceScaled) {
          throw ArgumentError('Cannot invoice more than remaining quantity.');
        }
        selected.add((item: item, quantityScaled: line.quantityScaled));
      }
      if (selected.isEmpty) {
        throw ArgumentError('Choose remaining quantity to invoice.');
      }

      final now = DateTime.now();
      final date = _dateOnly(invoiceDate ?? now);
      final calculation = _calculator.calculate(
        InvoiceCalculationInput(
          taxType: taxType,
          items: [
            for (final line in selected)
              InvoiceCalculationItemInput(
                id: line.item.localId,
                quantityScaled: line.quantityScaled,
                rateMinor: line.item.rateMinor,
                taxRateBasisPoints: line.item.taxRateBasisPoints,
              ),
          ],
        ),
      );
      final invoice = await _invoices.save(
        InvoiceModel(
          invoiceNumber: invoiceNumber,
          customer: current.customer,
          invoiceDate: date,
          dueDate: dueDate == null ? null : _dateOnly(dueDate),
          status: InvoiceStatus.unpaid,
          taxType: taxType,
          invoiceDiscount: const DiscountInput.none(),
          items: [
            for (final line in selected)
              InvoiceItemModel(
                localId: line.item.localId,
                productId: line.item.productId,
                name: line.item.name,
                description: line.item.description,
                quantityScaled: line.quantityScaled,
                unit: line.item.unit,
                rateMinor: line.item.rateMinor,
                hsnSac: line.item.hsnSac,
                taxRateBasisPoints: line.item.taxRateBasisPoints,
              ),
          ],
          charges: const [],
          calculation: calculation,
          notes: 'From delivery challan ${current.challanNumber}',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database
          .into(database.deliveryChallanInvoices)
          .insert(
            DeliveryChallanInvoicesCompanion.insert(
              challanId: challanId,
              invoiceId: invoice.id!,
              convertedAt: now,
            ),
          );
      for (final line in selected) {
        await (database.update(
          database.deliveryChallanItems,
        )..where((table) => table.id.equals(line.item.id!))).write(
          DeliveryChallanItemsCompanion(
            invoicedQuantityScaled: Value(
              line.item.invoicedQuantityScaled + line.quantityScaled,
            ),
          ),
        );
      }
      final refreshed = (await getById(challanId))!;
      await _writeStatus(challanId, _derivedStatus(items: refreshed.items));
      return invoice;
    });
  }

  Future<Map<int, int>> dispatchedQuantityBySourceItem({
    required DeliveryChallanSourceType sourceType,
    required int sourceId,
    int? excludeChallanId,
  }) async {
    final challans =
        await (database.select(database.deliveryChallans)..where(
              (table) =>
                  table.sourceType.equals(sourceType.name) &
                  table.sourceId.equals(sourceId) &
                  table.status
                      .equals(DeliveryChallanStatus.cancelled.name)
                      .not(),
            ))
            .get();
    final totals = <int, int>{};
    for (final challan in challans) {
      if (excludeChallanId != null && challan.id == excludeChallanId) {
        continue;
      }
      final items = await (database.select(
        database.deliveryChallanItems,
      )..where((table) => table.challanId.equals(challan.id))).get();
      for (final item in items) {
        final sourceItemId = item.sourceItemId;
        if (sourceItemId == null) continue;
        totals[sourceItemId] =
            (totals[sourceItemId] ?? 0) + item.dispatchedQuantityScaled;
      }
    }
    return totals;
  }

  Future<List<DeliveryChallanItemModel>> remainingLinesFromDocument(
    InvoiceModel document, {
    required DeliveryChallanSourceType sourceType,
    int? excludeChallanId,
  }) async {
    final sourceId = document.id;
    if (sourceId == null) return const [];
    final dispatched = await dispatchedQuantityBySourceItem(
      sourceType: sourceType,
      sourceId: sourceId,
      excludeChallanId: excludeChallanId,
    );
    return [
      for (final item in document.items)
        if (item.id != null &&
            item.quantityScaled - (dispatched[item.id!] ?? 0) > 0)
          DeliveryChallanItemModel(
            localId: 'src-${item.id}',
            productId: item.productId,
            sourceItemId: item.id,
            name: item.name,
            description: item.description,
            orderedQuantityScaled: item.quantityScaled,
            dispatchedQuantityScaled:
                item.quantityScaled - (dispatched[item.id!] ?? 0),
            unit: item.unit,
            rateMinor: item.rateMinor,
            hsnSac: item.hsnSac,
            taxRateBasisPoints: item.taxRateBasisPoints,
          ),
    ];
  }

  Future<void> _assertRemainingDispatch(DeliveryChallanModel model) async {
    if (model.sourceId == null ||
        (model.sourceType != DeliveryChallanSourceType.invoice &&
            model.sourceType != DeliveryChallanSourceType.quotation)) {
      return;
    }
    final source = await _invoices.getById(model.sourceId!);
    if (source == null) {
      throw ArgumentError(
        'The source document for this challan could not be found.',
      );
    }
    final dispatched = await dispatchedQuantityBySourceItem(
      sourceType: model.sourceType,
      sourceId: model.sourceId!,
      excludeChallanId: model.id,
    );
    for (final item in model.items) {
      final sourceItemId = item.sourceItemId;
      if (sourceItemId == null) continue;
      final match = source.items.where((row) => row.id == sourceItemId);
      if (match.isEmpty) {
        throw ArgumentError('An item is not on the source document.');
      }
      final remaining =
          match.single.quantityScaled - (dispatched[sourceItemId] ?? 0);
      if (item.dispatchedQuantityScaled > remaining) {
        throw ArgumentError(
          'Cannot dispatch more than remaining quantity on ${source.invoiceNumber}.',
        );
      }
    }
  }

  Future<void> _writeStatus(int challanId, DeliveryChallanStatus status) {
    return (database.update(
      database.deliveryChallans,
    )..where((table) => table.id.equals(challanId))).write(
      DeliveryChallansCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<DeliveryChallanModel> _load(DeliveryChallan row) async {
    final itemRows =
        await (database.select(database.deliveryChallanItems)
              ..where((table) => table.challanId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final conversionRows =
        await (database.select(database.deliveryChallanInvoices)
              ..where((table) => table.challanId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.desc(table.convertedAt)]))
            .get();
    final conversions = <DeliveryChallanConversionModel>[];
    for (final conversion in conversionRows) {
      final invoice = await _invoices.getById(conversion.invoiceId);
      conversions.add(
        DeliveryChallanConversionModel(
          invoiceId: conversion.invoiceId,
          invoiceNumber: invoice?.invoiceNumber ?? 'Invoice',
          convertedAt: conversion.convertedAt,
        ),
      );
    }
    String? sourceNumber;
    if (row.sourceId != null &&
        (row.sourceType == DeliveryChallanSourceType.quotation.name ||
            row.sourceType == DeliveryChallanSourceType.invoice.name)) {
      sourceNumber = (await _invoices.getById(row.sourceId!))?.invoiceNumber;
    }
    return DeliveryChallanModel(
      id: row.id,
      challanNumber: row.challanNumber,
      customer: CustomerSnapshotModel(
        customerId: row.customerId,
        name: row.customerName,
        companyName: row.customerCompany,
        mobile: row.customerMobile,
        email: row.customerEmail,
        address: row.customerAddress,
        city: row.customerCity,
        state: row.customerState,
        pinCode: row.customerPinCode,
        gstin: row.customerGstin,
      ),
      sourceType: DeliveryChallanSourceType.values.byName(row.sourceType),
      sourceId: row.sourceId,
      sourceNumber: sourceNumber,
      challanDate: row.challanDate,
      dispatchDate: row.dispatchDate,
      status: DeliveryChallanStatus.values.byName(row.status),
      movementReason: MovementReason.values.byName(row.movementReason),
      movementReasonNote: row.movementReasonNote,
      dispatchAddress: row.dispatchAddress,
      dispatchCity: row.dispatchCity,
      dispatchState: row.dispatchState,
      dispatchPinCode: row.dispatchPinCode,
      deliveryAddress: row.deliveryAddress,
      deliveryCity: row.deliveryCity,
      deliveryState: row.deliveryState,
      deliveryPinCode: row.deliveryPinCode,
      transporterName: row.transporterName,
      transporterId: row.transporterId,
      vehicleNumber: row.vehicleNumber,
      transportDocumentNumber: row.transportDocumentNumber,
      transportDocumentDate: row.transportDocumentDate,
      distanceKm: row.distanceKm,
      ewayStatus: EwayStatus.values.byName(row.ewayStatus),
      ewayNumber: row.ewayNumber,
      notes: row.notes,
      cancellationReason: row.cancellationReason,
      cancelledAt: row.cancelledAt,
      items: [
        for (final item in itemRows)
          DeliveryChallanItemModel(
            localId: 'saved-${item.id}',
            id: item.id,
            productId: item.productId,
            sourceItemId: item.sourceItemId,
            name: item.name,
            description: item.description,
            orderedQuantityScaled: item.orderedQuantityScaled,
            dispatchedQuantityScaled: item.dispatchedQuantityScaled,
            deliveredQuantityScaled: item.deliveredQuantityScaled,
            returnedQuantityScaled: item.returnedQuantityScaled,
            invoicedQuantityScaled: item.invoicedQuantityScaled,
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

  DeliveryChallanSummaryModel _toSummary(DeliveryChallan row, int itemCount) {
    return DeliveryChallanSummaryModel(
      id: row.id,
      challanNumber: row.challanNumber,
      customerName: row.customerName,
      challanDate: row.challanDate,
      status: DeliveryChallanStatus.values.byName(row.status),
      movementReason: MovementReason.values.byName(row.movementReason),
      itemCount: itemCount,
    );
  }

  DeliveryChallanStatus _derivedStatus({
    required List<DeliveryChallanItemModel> items,
    bool cancelled = false,
    bool preferDraft = false,
  }) {
    if (cancelled) return DeliveryChallanStatus.cancelled;
    if (preferDraft) return DeliveryChallanStatus.draft;
    final hasInvoiced = items.any((item) => item.invoicedQuantityScaled > 0);
    final remainingInvoice = items.fold<int>(
      0,
      (total, item) => total + item.remainingToInvoiceScaled,
    );
    final hasDispatched = items.any(
      (item) => item.dispatchedQuantityScaled > 0,
    );
    final allDelivered =
        hasDispatched &&
        items.every(
          (item) =>
              item.dispatchedQuantityScaled == 0 ||
              item.deliveredQuantityScaled >= item.dispatchedQuantityScaled,
        );
    final someDelivered = items.any((item) => item.deliveredQuantityScaled > 0);
    if (hasInvoiced && remainingInvoice == 0) {
      return DeliveryChallanStatus.invoiced;
    }
    if (hasInvoiced) return DeliveryChallanStatus.partInvoiced;
    if (allDelivered) return DeliveryChallanStatus.delivered;
    if (someDelivered) return DeliveryChallanStatus.partDelivered;
    return DeliveryChallanStatus.open;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
