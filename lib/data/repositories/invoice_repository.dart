import 'package:drift/drift.dart';

import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../models/invoice_calculation_models.dart';
import '../models/invoice_model.dart';
import '../services/app_database.dart';
import 'base_repository.dart';

class InvoiceRepository extends BaseRepository {
  const InvoiceRepository(super.database);

  Future<String> nextInvoiceNumber({
    required String prefix,
    required int startingNumber,
  }) async {
    final normalized = prefix.trim().isEmpty
        ? 'INV'
        : prefix.trim().toUpperCase();
    final rows = await (database.select(
      database.invoices,
    )..where((table) => table.invoiceNumber.like('$normalized-%'))).get();
    var next = startingNumber;
    for (final row in rows) {
      final value = int.tryParse(row.invoiceNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$normalized-${next.toString().padLeft(4, '0')}';
  }

  Future<bool> numberExists(String number, {int? excludingId}) async {
    final query = database.select(database.invoices)
      ..where((table) => table.invoiceNumber.equals(number));
    if (excludingId != null) {
      query.where((table) => table.id.isNotValue(excludingId));
    }
    return await query.getSingleOrNull() != null;
  }

  Future<InvoiceModel?> latestDraft() async {
    final row =
        await (database.select(database.invoices)
              ..where((table) => table.status.equals(InvoiceStatus.draft.name))
              ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<InvoiceModel?> getById(int id) async {
    final row = await (database.select(
      database.invoices,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<InvoiceModel> save(InvoiceModel model) async {
    return database.transaction(() async {
      final invoice = InvoicesCompanion(
        id: model.id == null ? const Value.absent() : Value(model.id!),
        invoiceNumber: Value(model.invoiceNumber),
        customerId: Value(model.customer.customerId),
        customerName: Value(model.customer.name),
        customerCompany: Value(model.customer.companyName),
        customerMobile: Value(model.customer.mobile),
        customerEmail: Value(model.customer.email),
        customerAddress: Value(model.customer.address),
        customerCity: Value(model.customer.city),
        customerState: Value(model.customer.state),
        customerPinCode: Value(model.customer.pinCode),
        customerGstin: Value(model.customer.gstin),
        invoiceDate: Value(model.invoiceDate),
        dueDate: Value(model.dueDate),
        status: Value(model.status.name),
        taxType: Value(model.taxType.name),
        discountType: Value(model.invoiceDiscount.type.name),
        discountValue: Value(discountStorageValue(model.invoiceDiscount)),
        subtotalMinor: Value(model.calculation.subtotalMinor),
        itemDiscountMinor: Value(model.calculation.itemDiscountTotalMinor),
        invoiceDiscountMinor: Value(model.calculation.invoiceDiscountMinor),
        taxableMinor: Value(model.calculation.taxableTotalMinor),
        taxMinor: Value(model.calculation.taxTotalMinor),
        cgstMinor: Value(model.calculation.cgstMinor),
        sgstMinor: Value(model.calculation.sgstMinor),
        igstMinor: Value(model.calculation.igstMinor),
        chargesMinor: Value(model.calculation.additionalChargeTotalMinor),
        roundOffMinor: Value(model.calculation.roundOffMinor),
        grandTotalMinor: Value(model.calculation.grandTotalMinor),
        paidAmountMinor: Value(model.calculation.paidAmountMinor),
        balanceMinor: Value(model.calculation.balanceDueMinor),
        notes: Value(model.notes),
        terms: Value(model.terms),
        createdAt: Value(model.createdAt),
        updatedAt: Value(model.updatedAt),
      );
      late final int invoiceId;
      if (model.id == null) {
        invoiceId = await database.into(database.invoices).insert(invoice);
      } else {
        invoiceId = model.id!;
        await (database.update(
          database.invoices,
        )..where((table) => table.id.equals(invoiceId))).write(invoice);
      }

      await (database.delete(
        database.invoiceItems,
      )..where((table) => table.invoiceId.equals(invoiceId))).go();
      await (database.delete(
        database.invoiceCharges,
      )..where((table) => table.invoiceId.equals(invoiceId))).go();
      for (var index = 0; index < model.items.length; index++) {
        final item = model.items[index];
        final result = model.calculation.items[index];
        await database
            .into(database.invoiceItems)
            .insert(
              InvoiceItemsCompanion.insert(
                invoiceId: invoiceId,
                productId: Value(item.productId),
                name: item.name,
                description: Value(item.description),
                quantityScaled: item.quantityScaled,
                unit: item.unit,
                rateMinor: item.rateMinor,
                hsnSac: Value(item.hsnSac),
                taxRateBasisPoints: item.taxRateBasisPoints,
                discountType: item.discount.type.name,
                discountValue: Value(discountStorageValue(item.discount)),
                baseAmountMinor: result.baseMinor,
                discountAmountMinor: result.discountMinor,
                taxableAmountMinor: result.taxableMinor,
                taxAmountMinor: result.taxMinor,
                totalMinor: result.totalMinor,
                sortOrder: index,
              ),
            );
      }
      for (var index = 0; index < model.charges.length; index++) {
        final charge = model.charges[index];
        await database
            .into(database.invoiceCharges)
            .insert(
              InvoiceChargesCompanion.insert(
                invoiceId: invoiceId,
                title: charge.title,
                amountMinor: charge.amountMinor,
                sortOrder: index,
              ),
            );
      }
      return (await getById(invoiceId))!;
    });
  }

  Future<InvoiceModel> _load(Invoice row) async {
    final itemRows =
        await (database.select(database.invoiceItems)
              ..where((table) => table.invoiceId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final chargeRows =
        await (database.select(database.invoiceCharges)
              ..where((table) => table.invoiceId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final discountType = DiscountType.values.byName(row.discountType);
    return InvoiceModel(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
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
      invoiceDate: row.invoiceDate,
      dueDate: row.dueDate,
      status: InvoiceStatus.values.byName(row.status),
      taxType: TaxType.values.byName(row.taxType),
      invoiceDiscount: discountFromStorage(discountType, row.discountValue),
      items: itemRows
          .map(
            (item) => InvoiceItemModel(
              localId: 'saved-${item.id}',
              id: item.id,
              productId: item.productId,
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
            ),
          )
          .toList(),
      charges: chargeRows
          .map(
            (charge) => InvoiceChargeModel(
              title: charge.title,
              amountMinor: charge.amountMinor,
            ),
          )
          .toList(),
      calculation: InvoiceCalculationResult(
        items: itemRows
            .map(
              (item) => InvoiceCalculationItemResult(
                id: 'saved-${item.id}',
                baseMinor: item.baseAmountMinor,
                discountMinor: item.discountAmountMinor,
                taxableMinor: item.taxableAmountMinor,
                taxMinor: item.taxAmountMinor,
                totalMinor: item.totalMinor,
              ),
            )
            .toList(),
        subtotalMinor: row.subtotalMinor,
        itemDiscountTotalMinor: row.itemDiscountMinor,
        invoiceDiscountMinor: row.invoiceDiscountMinor,
        taxableTotalMinor: row.taxableMinor,
        taxTotalMinor: row.taxMinor,
        cgstMinor: row.cgstMinor,
        sgstMinor: row.sgstMinor,
        igstMinor: row.igstMinor,
        additionalChargeTotalMinor: row.chargesMinor,
        roundOffMinor: row.roundOffMinor,
        grandTotalMinor: row.grandTotalMinor,
        paidAmountMinor: row.paidAmountMinor,
        balanceDueMinor: row.balanceMinor,
        paymentStatus: row.paidAmountMinor == 0
            ? InvoicePaymentStatus.unpaid
            : row.balanceMinor == 0
            ? InvoicePaymentStatus.paid
            : InvoicePaymentStatus.partiallyPaid,
      ),
      notes: row.notes,
      terms: row.terms,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
