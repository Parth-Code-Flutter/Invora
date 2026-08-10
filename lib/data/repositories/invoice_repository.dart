import 'package:drift/drift.dart';

import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../models/invoice_calculation_models.dart';
import '../models/invoice_model.dart';
import '../models/invoice_payment_model.dart';
import '../models/report_summary_model.dart';
import '../services/app_database.dart';
import '../services/invoice_validation_service.dart';
import 'base_repository.dart';

class InvoiceRepository extends BaseRepository {
  const InvoiceRepository(super.database);

  static const _validator = InvoiceValidationService();

  Stream<ReportSummaryModel> watchCurrentMonthReport() =>
      watchMonthlyReport(DateTime.now());

  Stream<ReportSummaryModel> watchMonthlyReport(DateTime selectedMonth) {
    return database.select(database.invoices).watch().map((rows) {
      final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
      final current = rows.where(
        (row) =>
            row.documentType == DocumentType.invoice.name &&
            row.invoiceDate.year == monthStart.year &&
            row.invoiceDate.month == monthStart.month &&
            row.status != InvoiceStatus.draft.name &&
            row.status != InvoiceStatus.cancelled.name,
      );
      var sales = 0;
      var received = 0;
      var outstanding = 0;
      var count = 0;
      var paid = 0;
      var pending = 0;
      final monthStarts = List.generate(6, (index) {
        final offset = 5 - index;
        return DateTime(monthStart.year, monthStart.month - offset);
      });
      final monthlySales = monthStarts
          .map((month) => MonthlySalesPoint(month: month, amountMinor: 0))
          .toList();
      for (final row in rows.where(
        (row) =>
            row.documentType == DocumentType.invoice.name &&
            row.status != InvoiceStatus.draft.name &&
            row.status != InvoiceStatus.cancelled.name,
      )) {
        final index = monthStarts.indexWhere(
          (month) =>
              month.year == row.invoiceDate.year &&
              month.month == row.invoiceDate.month,
        );
        if (index >= 0) {
          monthlySales[index] = MonthlySalesPoint(
            month: monthStarts[index],
            amountMinor: monthlySales[index].amountMinor + row.grandTotalMinor,
          );
        }
      }
      for (final row in current) {
        sales += row.grandTotalMinor;
        received += row.paidAmountMinor;
        outstanding += row.balanceMinor;
        count++;
        if (row.status == InvoiceStatus.paid.name) {
          paid++;
        } else {
          pending++;
        }
      }
      return ReportSummaryModel(
        totalSalesMinor: sales,
        totalReceivedMinor: received,
        outstandingMinor: outstanding,
        invoiceCount: count,
        paidCount: paid,
        pendingCount: pending,
        monthlySales: monthlySales,
      );
    });
  }

  Stream<List<InvoiceSummaryModel>> watchSummaries({
    String query = '',
    InvoiceListFilter filter = InvoiceListFilter.all,
    InvoiceSort sort = InvoiceSort.newest,
    DocumentType documentType = DocumentType.invoice,
  }) {
    final statement = database.select(database.invoices)
      ..where((table) => table.documentType.equals(documentType.name));
    return statement.watch().map((rows) {
      final search = query.trim().toLowerCase();
      final now = DateTime.now();
      final results = rows
          .map(
            (row) => InvoiceSummaryModel(
              id: row.id,
              invoiceNumber: row.invoiceNumber,
              customerName: row.customerName,
              companyName: row.customerCompany,
              invoiceDate: row.invoiceDate,
              dueDate: row.dueDate,
              status: InvoiceStatus.values.byName(row.status),
              grandTotalMinor: row.grandTotalMinor,
              balanceMinor: row.balanceMinor,
            ),
          )
          .where((invoice) {
            final matchesSearch =
                search.isEmpty ||
                invoice.invoiceNumber.toLowerCase().contains(search) ||
                invoice.customerName.toLowerCase().contains(search) ||
                (invoice.companyName?.toLowerCase().contains(search) ?? false);
            if (!matchesSearch) return false;
            final status = invoice.effectiveStatus(now);
            return switch (filter) {
              InvoiceListFilter.all => true,
              InvoiceListFilter.draft => status == InvoiceStatus.draft,
              InvoiceListFilter.unpaid =>
                status == InvoiceStatus.unpaid ||
                    status == InvoiceStatus.partiallyPaid,
              InvoiceListFilter.paid => status == InvoiceStatus.paid,
              InvoiceListFilter.overdue => status == InvoiceStatus.overdue,
              InvoiceListFilter.sent => status == InvoiceStatus.sent,
              InvoiceListFilter.accepted => status == InvoiceStatus.accepted,
              InvoiceListFilter.rejected => status == InvoiceStatus.rejected,
              InvoiceListFilter.expired => status == InvoiceStatus.expired,
            };
          })
          .toList();
      results.sort(
        (left, right) => switch (sort) {
          InvoiceSort.newest => right.invoiceDate.compareTo(left.invoiceDate),
          InvoiceSort.oldest => left.invoiceDate.compareTo(right.invoiceDate),
          InvoiceSort.highestAmount => right.grandTotalMinor.compareTo(
            left.grandTotalMinor,
          ),
          InvoiceSort.lowestAmount => left.grandTotalMinor.compareTo(
            right.grandTotalMinor,
          ),
        },
      );
      return results;
    });
  }

  Stream<List<InvoiceSummaryModel>> watchCustomerInvoices(int customerId) {
    final statement = database.select(database.invoices)
      ..where(
        (table) =>
            table.documentType.equals(DocumentType.invoice.name) &
            table.customerId.equals(customerId),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.invoiceDate)]);
    return statement.watch().map(
      (rows) => rows
          .map(
            (row) => InvoiceSummaryModel(
              id: row.id,
              invoiceNumber: row.invoiceNumber,
              customerName: row.customerName,
              companyName: row.customerCompany,
              invoiceDate: row.invoiceDate,
              dueDate: row.dueDate,
              status: InvoiceStatus.values.byName(row.status),
              grandTotalMinor: row.grandTotalMinor,
              balanceMinor: row.balanceMinor,
            ),
          )
          .toList(),
    );
  }

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

  Future<InvoiceModel?> latestDraft() =>
      latestDraftOfType(DocumentType.invoice);

  Future<InvoiceModel?> latestDraftOfType(DocumentType documentType) async {
    final row =
        await (database.select(database.invoices)
              ..where(
                (table) =>
                    table.status.equals(InvoiceStatus.draft.name) &
                    table.documentType.equals(documentType.name),
              )
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

  Future<List<InvoicePaymentModel>> getPayments(int invoiceId) async {
    final rows =
        await (database.select(database.invoicePayments)
              ..where((table) => table.invoiceId.equals(invoiceId))
              ..orderBy([(table) => OrderingTerm.desc(table.paidAt)]))
            .get();
    return rows
        .map(
          (row) => InvoicePaymentModel(
            id: row.id,
            invoiceId: row.invoiceId,
            amountMinor: row.amountMinor,
            paidAt: row.paidAt,
            method: row.method,
            reference: row.reference,
            note: row.note,
          ),
        )
        .toList();
  }

  Future<void> recordPayment({
    required int invoiceId,
    required int amountMinor,
    required DateTime paidAt,
    String? method,
    String? reference,
    String? note,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    await database.transaction(() async {
      final invoice = await getById(invoiceId);
      if (invoice == null) throw StateError('Invoice not found.');
      if (invoice.status == InvoiceStatus.cancelled) {
        throw StateError('A cancelled invoice cannot receive payments.');
      }
      if (amountMinor > invoice.calculation.balanceDueMinor) {
        throw ArgumentError('Payment cannot exceed the remaining balance.');
      }
      await database
          .into(database.invoicePayments)
          .insert(
            InvoicePaymentsCompanion.insert(
              invoiceId: invoiceId,
              amountMinor: amountMinor,
              paidAt: paidAt,
              method: Value(_optional(method)),
              reference: Value(_optional(reference)),
              note: Value(_optional(note)),
            ),
          );
      await _writePaymentTotal(
        invoice,
        invoice.calculation.paidAmountMinor + amountMinor,
      );
    });
  }

  Future<void> updatePayment(int id, int paidAmountMinor) async {
    final invoice = await getById(id);
    if (invoice == null) throw StateError('Invoice not found.');
    if (invoice.status == InvoiceStatus.cancelled) {
      throw StateError('A cancelled invoice cannot receive payments.');
    }
    if (paidAmountMinor < 0 ||
        paidAmountMinor > invoice.calculation.grandTotalMinor) {
      throw ArgumentError('Payment must be between zero and the grand total.');
    }
    final difference = paidAmountMinor - invoice.calculation.paidAmountMinor;
    await database.transaction(() async {
      if (difference != 0) {
        await database
            .into(database.invoicePayments)
            .insert(
              InvoicePaymentsCompanion.insert(
                invoiceId: id,
                amountMinor: difference,
                paidAt: DateTime.now(),
                method: const Value('Adjustment'),
                note: const Value('Payment total adjusted'),
              ),
            );
      }
      await _writePaymentTotal(invoice, paidAmountMinor);
    });
  }

  Future<void> _writePaymentTotal(
    InvoiceModel invoice,
    int paidAmountMinor,
  ) async {
    final balance = invoice.calculation.grandTotalMinor - paidAmountMinor;
    final status = paidAmountMinor == 0
        ? InvoiceStatus.unpaid
        : balance == 0
        ? InvoiceStatus.paid
        : InvoiceStatus.partiallyPaid;
    await (database.update(
      database.invoices,
    )..where((table) => table.id.equals(invoice.id!))).write(
      InvoicesCompanion(
        paidAmountMinor: Value(paidAmountMinor),
        balanceMinor: Value(balance),
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> cancel(int id) async {
    await (database.update(
      database.invoices,
    )..where((table) => table.id.equals(id))).write(
      InvoicesCompanion(
        status: Value(InvoiceStatus.cancelled.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateStatus(int id, InvoiceStatus status) async {
    await (database.update(
      database.invoices,
    )..where((table) => table.id.equals(id))).write(
      InvoicesCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<InvoiceModel> convertQuotationToInvoice({
    required int quotationId,
    required String invoiceNumber,
  }) async {
    final converted = await duplicate(
      id: quotationId,
      newInvoiceNumber: invoiceNumber,
    );
    await (database.update(
      database.invoices,
    )..where((table) => table.id.equals(converted.id!))).write(
      InvoicesCompanion(
        documentType: Value(DocumentType.invoice.name),
        status: Value(InvoiceStatus.unpaid.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await updateStatus(quotationId, InvoiceStatus.accepted);
    return (await getById(converted.id!))!;
  }

  Future<void> delete(int id) async {
    await (database.delete(
      database.invoices,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<InvoiceModel> duplicate({
    required int id,
    required String newInvoiceNumber,
  }) async {
    final source = await getById(id);
    if (source == null) throw StateError('Invoice not found.');
    final now = DateTime.now();
    final copiedCalculation = InvoiceCalculationResult(
      items: source.calculation.items,
      subtotalMinor: source.calculation.subtotalMinor,
      itemDiscountTotalMinor: source.calculation.itemDiscountTotalMinor,
      invoiceDiscountMinor: source.calculation.invoiceDiscountMinor,
      taxableTotalMinor: source.calculation.taxableTotalMinor,
      taxTotalMinor: source.calculation.taxTotalMinor,
      cgstMinor: source.calculation.cgstMinor,
      sgstMinor: source.calculation.sgstMinor,
      igstMinor: source.calculation.igstMinor,
      additionalChargeTotalMinor: source.calculation.additionalChargeTotalMinor,
      roundOffMinor: source.calculation.roundOffMinor,
      grandTotalMinor: source.calculation.grandTotalMinor,
      paidAmountMinor: 0,
      balanceDueMinor: source.calculation.grandTotalMinor,
      paymentStatus: InvoicePaymentStatus.unpaid,
    );
    return save(
      InvoiceModel(
        documentType: source.documentType,
        invoiceNumber: newInvoiceNumber,
        customer: source.customer,
        invoiceDate: now,
        status: InvoiceStatus.draft,
        taxType: source.taxType,
        invoiceDiscount: source.invoiceDiscount,
        items: source.items
            .map(
              (item) => InvoiceItemModel(
                localId: 'copy-${item.localId}',
                productId: item.productId,
                name: item.name,
                description: item.description,
                quantityScaled: item.quantityScaled,
                unit: item.unit,
                rateMinor: item.rateMinor,
                hsnSac: item.hsnSac,
                taxRateBasisPoints: item.taxRateBasisPoints,
                discount: item.discount,
              ),
            )
            .toList(),
        charges: source.charges,
        calculation: copiedCalculation,
        notes: source.notes,
        terms: source.terms,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<InvoiceModel> save(InvoiceModel model) async {
    if (_validator.requiresCompleteDocument(model)) {
      final validation = _validator.validateRequired(model);
      if (validation != null) throw ArgumentError(validation);
    }
    return database.transaction(() async {
      final invoice = InvoicesCompanion(
        id: model.id == null ? const Value.absent() : Value(model.id!),
        invoiceNumber: Value(model.invoiceNumber),
        documentType: Value(model.documentType.name),
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

      // Keep the append-only ledger aligned with older create/edit flows that
      // still submit a cumulative paid amount as part of the invoice model.
      final ledgerRows = await (database.select(
        database.invoicePayments,
      )..where((table) => table.invoiceId.equals(invoiceId))).get();
      final ledgerTotal = ledgerRows.fold<int>(
        0,
        (total, payment) => total + payment.amountMinor,
      );
      final paymentDifference = model.calculation.paidAmountMinor - ledgerTotal;
      if (paymentDifference != 0) {
        await database
            .into(database.invoicePayments)
            .insert(
              InvoicePaymentsCompanion.insert(
                invoiceId: invoiceId,
                amountMinor: paymentDifference,
                method: Value(
                  ledgerRows.isEmpty ? 'Opening payment' : 'Adjustment',
                ),
                note: Value(
                  ledgerRows.isEmpty
                      ? 'Recorded when the invoice was created'
                      : 'Reconciled when the invoice was updated',
                ),
                paidAt: model.updatedAt,
              ),
            );
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
      documentType: DocumentType.values.byName(row.documentType),
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
