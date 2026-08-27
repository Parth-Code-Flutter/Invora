import 'package:drift/drift.dart';

import '../models/purchase_models.dart';
import '../services/app_database.dart';
import 'base_repository.dart';

class PurchaseRepository extends BaseRepository {
  const PurchaseRepository(super.database);

  Stream<List<SupplierModel>> watchSuppliers({String query = ''}) {
    final statement = database.select(database.suppliers)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return statement.watch().map((rows) {
      final term = query.trim().toLowerCase();
      return rows
          .map(_supplier)
          .where(
            (s) =>
                term.isEmpty ||
                [
                  s.name,
                  s.companyName ?? '',
                  s.mobile ?? '',
                  s.gstin ?? '',
                ].join(' ').toLowerCase().contains(term),
          )
          .toList();
    });
  }

  Future<SupplierModel> saveSupplier(SupplierModel model) async {
    final companion = SuppliersCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      name: Value(model.name.trim()),
      companyName: Value(model.companyName),
      mobile: Value(model.mobile),
      email: Value(model.email),
      gstRegistrationType: Value(model.gstRegistrationType),
      gstin: Value(model.gstin),
      address: Value(model.address),
      isDeleted: Value(model.isDeleted),
      createdAt: Value(model.createdAt),
      updatedAt: Value(DateTime.now()),
    );
    final id = model.id == null
        ? await database.into(database.suppliers).insert(companion)
        : model.id!;
    if (model.id != null) {
      await (database.update(
        database.suppliers,
      )..where((table) => table.id.equals(model.id!))).write(companion);
    }
    final row = await (database.select(
      database.suppliers,
    )..where((t) => t.id.equals(model.id ?? id))).getSingle();
    return _supplier(row);
  }

  Future<List<PurchaseBillSummary>> listOpenPayables() async {
    final rows = await database.select(database.purchaseBills).get();
    return rows
        .map(_summary)
        .where((bill) => bill.status != 'cancelled' && bill.balanceMinor > 0)
        .toList();
  }

  Stream<List<PurchaseBillSummary>> watchBills({String query = ''}) {
    final statement = database.select(database.purchaseBills)
      ..orderBy([
        (t) => OrderingTerm.desc(t.billDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return statement.watch().map((rows) {
      final terms = query
          .trim()
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty);
      return rows.map(_summary).where((b) {
        final text = '${b.billNumber} ${b.supplierName} ${b.status}'
            .toLowerCase();
        return terms.every(text.contains);
      }).toList();
    });
  }

  Future<bool> isBillNumberAvailable(
    String number, {
    int? excludingId,
    int? supplierId,
    DateTime? billDate,
  }) async {
    final normalized = number.trim().toLowerCase();
    final rows = await database.select(database.purchaseBills).get();
    return !rows.any(
      (bill) =>
          bill.id != excludingId &&
          (supplierId == null || bill.supplierId == supplierId) &&
          (billDate == null ||
              _financialYear(bill.billDate) == _financialYear(billDate)) &&
          bill.billNumber.trim().toLowerCase() == normalized,
    );
  }

  Stream<PurchaseDashboardSummary> watchDashboard() =>
      database.select(database.purchaseBills).watch().asyncMap((bills) async {
        final activeBills = bills
            .where((bill) => bill.status != 'cancelled')
            .toList();
        final supplierCount =
            await (database.selectOnly(database.suppliers)
                  ..addColumns([database.suppliers.id.count()])
                  ..where(database.suppliers.isDeleted.equals(false)))
                .map((r) => r.read(database.suppliers.id.count()) ?? 0)
                .getSingle();
        final now = DateTime.now();
        return PurchaseDashboardSummary(
          totalSpendMinor: activeBills.fold(0, (s, b) => s + b.totalMinor),
          paidMinor: activeBills.fold(0, (s, b) => s + b.paidMinor),
          payableMinor: activeBills.fold(0, (s, b) => s + b.balanceMinor),
          overdueMinor: activeBills
              .where(
                (b) =>
                    b.balanceMinor > 0 &&
                    b.dueDate != null &&
                    b.dueDate!.isBefore(DateTime(now.year, now.month, now.day)),
              )
              .fold(0, (s, b) => s + b.balanceMinor),
          billCount: activeBills.length,
          supplierCount: supplierCount,
        );
      });

  Future<PurchaseBillModel?> getBill(int id) async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (bill == null) return null;
    final items =
        await (database.select(database.purchaseItems)
              ..where((t) => t.purchaseBillId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return PurchaseBillModel(
      id: bill.id,
      billNumber: bill.billNumber,
      supplierId: bill.supplierId,
      supplierName: bill.supplierName,
      billDate: bill.billDate,
      dueDate: bill.dueDate,
      items: items
          .map(
            (i) => PurchaseItemModel(
              id: i.id,
              name: i.name,
              quantity: i.quantityScaled / 1000,
              unit: i.unit,
              hsnSac: i.hsnSac,
              rateMinor: i.rateMinor,
              taxRate: i.taxRateBasisPoints / 100,
            ),
          )
          .toList(),
      paidMinor: bill.paidMinor,
      notes: bill.notes,
      status: bill.status,
      cancellationReason: bill.cancellationReason,
      cancelledAt: bill.cancelledAt,
      placeOfSupply: bill.placeOfSupply,
      taxMode: bill.taxMode,
      reverseCharge: bill.reverseCharge,
      itcEligible: bill.itcEligible,
      discountMinor: bill.discountMinor,
      additionalChargesMinor: bill.additionalChargesMinor,
      createdAt: bill.createdAt,
      updatedAt: bill.updatedAt,
    );
  }

  Stream<List<PurchasePaymentModel>> watchPayments(int billId) =>
      (database.select(database.purchasePayments)
            ..where((t) => t.purchaseBillId.equals(billId))
            ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (p) => PurchasePaymentModel(
                    id: p.id,
                    amountMinor: p.amountMinor,
                    method: p.method,
                    reference: p.reference,
                    note: p.note,
                    entryType: p.entryType,
                    reversesPaymentId: p.reversesPaymentId,
                    paidAt: p.paidAt,
                  ),
                )
                .toList(),
          );

  Stream<List<PurchaseBillAttachmentModel>> watchAttachments(int billId) =>
      (database.select(database.purchaseBillAttachments)
            ..where((t) => t.purchaseBillId.equals(billId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (file) => PurchaseBillAttachmentModel(
                    id: file.id,
                    purchaseBillId: file.purchaseBillId,
                    fileName: file.fileName,
                    localPath: file.localPath,
                    mimeType: file.mimeType,
                    sizeBytes: file.sizeBytes,
                    createdAt: file.createdAt,
                  ),
                )
                .toList(),
          );

  Future<int> addAttachment(PurchaseBillAttachmentModel attachment) => database
      .into(database.purchaseBillAttachments)
      .insert(
        PurchaseBillAttachmentsCompanion.insert(
          purchaseBillId: attachment.purchaseBillId,
          fileName: attachment.fileName,
          localPath: attachment.localPath,
          mimeType: Value(attachment.mimeType),
          sizeBytes: Value(attachment.sizeBytes),
          createdAt: Value(attachment.createdAt),
        ),
      );

  Future<void> deleteAttachment(int id) => (database.delete(
    database.purchaseBillAttachments,
  )..where((t) => t.id.equals(id))).go();

  Future<int> saveBill(PurchaseBillModel model) =>
      database.transaction(() async {
        final existingPaid = model.id == null
            ? 0
            : await _ledgerPaidMinor(model.id!);
        if (existingPaid > model.totalMinor) {
          throw StateError(
            'Bill total cannot be lower than the recorded supplier payments.',
          );
        }
        final balance = model.totalMinor - existingPaid;
        final status = model.status == 'cancelled'
            ? 'cancelled'
            : _status(balance, model.dueDate);
        final companion = PurchaseBillsCompanion(
          id: model.id == null ? const Value.absent() : Value(model.id!),
          billNumber: Value(model.billNumber.trim()),
          supplierId: Value(model.supplierId!),
          supplierName: Value(model.supplierName),
          billDate: Value(model.billDate),
          dueDate: Value(model.dueDate),
          subtotalMinor: Value(model.subtotalMinor),
          taxMinor: Value(model.taxMinor),
          totalMinor: Value(model.totalMinor),
          paidMinor: Value(existingPaid),
          balanceMinor: Value(balance),
          status: Value(status),
          notes: Value(model.notes),
          cancellationReason: Value(model.cancellationReason),
          cancelledAt: Value(model.cancelledAt),
          placeOfSupply: Value(model.placeOfSupply),
          taxMode: Value(model.taxMode),
          reverseCharge: Value(model.reverseCharge),
          itcEligible: Value(model.itcEligible),
          discountMinor: Value(model.discountMinor),
          additionalChargesMinor: Value(model.additionalChargesMinor),
          createdAt: Value(model.createdAt),
          updatedAt: Value(DateTime.now()),
        );
        final billId = model.id == null
            ? await database.into(database.purchaseBills).insert(companion)
            : model.id!;
        if (model.id != null) {
          await (database.update(
            database.purchaseBills,
          )..where((table) => table.id.equals(model.id!))).write(companion);
        }
        await (database.delete(
          database.purchaseItems,
        )..where((t) => t.purchaseBillId.equals(billId))).go();
        for (var index = 0; index < model.items.length; index++) {
          final item = model.items[index];
          await database
              .into(database.purchaseItems)
              .insert(
                PurchaseItemsCompanion.insert(
                  purchaseBillId: billId,
                  name: item.name,
                  quantityScaled: (item.quantity * 1000).round(),
                  unit: item.unit,
                  hsnSac: Value(item.hsnSac),
                  rateMinor: item.rateMinor,
                  taxRateBasisPoints: Value((item.taxRate * 100).round()),
                  totalMinor: item.totalMinor,
                  sortOrder: index,
                ),
              );
        }
        return billId;
      });

  Future<void> recordPayment(
    int billId,
    int amountMinor, {
    String? method,
    String? reference,
    String? note,
    DateTime? paidAt,
  }) => database.transaction(() async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).getSingle();
    if (bill.status == 'cancelled') {
      throw StateError('Cancelled purchase bills cannot receive payments.');
    }
    final ledgerPaid = await _ledgerPaidMinor(billId);
    final balanceBefore = bill.totalMinor - ledgerPaid;
    if (amountMinor <= 0 || amountMinor > balanceBefore) {
      throw ArgumentError('Payment must be within the outstanding balance.');
    }
    await database
        .into(database.purchasePayments)
        .insert(
          PurchasePaymentsCompanion.insert(
            purchaseBillId: billId,
            amountMinor: amountMinor,
            method: Value(method),
            reference: Value(reference),
            note: Value(note),
            paidAt: paidAt ?? DateTime.now(),
          ),
        );
    final paid = ledgerPaid + amountMinor;
    final balance = bill.totalMinor - paid;
    await (database.update(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).write(
      PurchaseBillsCompanion(
        paidMinor: Value(paid),
        balanceMinor: Value(balance),
        status: Value(_status(balance, bill.dueDate, paid: paid)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<void> reversePayment(
    int paymentId, {
    required String reason,
    DateTime? reversedAt,
  }) => database.transaction(() async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A reversal reason is required.');
    }
    final payment = await (database.select(
      database.purchasePayments,
    )..where((t) => t.id.equals(paymentId))).getSingleOrNull();
    if (payment == null || payment.entryType == 'reversal') {
      throw StateError('This supplier payment cannot be reversed.');
    }
    final existingReversal = await (database.select(
      database.purchasePayments,
    )..where((t) => t.reversesPaymentId.equals(paymentId))).getSingleOrNull();
    if (existingReversal != null) {
      throw StateError('This supplier payment is already reversed.');
    }
    await database
        .into(database.purchasePayments)
        .insert(
          PurchasePaymentsCompanion.insert(
            purchaseBillId: payment.purchaseBillId,
            amountMinor: -payment.amountMinor,
            method: Value(payment.method),
            reference: Value(payment.reference),
            note: Value(reason.trim()),
            entryType: const Value('reversal'),
            reversesPaymentId: Value(paymentId),
            paidAt: reversedAt ?? DateTime.now(),
          ),
        );
    await _reconcileBill(payment.purchaseBillId);
  });

  Future<void> cancelBill(int id, {required String reason}) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A cancellation reason is required.');
    }
    final paid = await _ledgerPaidMinor(id);
    if (paid != 0) {
      throw StateError(
        'Reverse recorded supplier payments before cancelling this bill.',
      );
    }
    await (database.update(
      database.purchaseBills,
    )..where((t) => t.id.equals(id))).write(
      PurchaseBillsCompanion(
        status: const Value('cancelled'),
        cancellationReason: Value(reason.trim()),
        cancelledAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> duplicateBill(int id) async {
    final source = await getBill(id);
    if (source == null) throw StateError('Purchase bill was not found.');
    final now = DateTime.now();
    var copyNumber = '${source.billNumber}-COPY';
    var suffix = 2;
    while (!await isBillNumberAvailable(
      copyNumber,
      supplierId: source.supplierId,
      billDate: now,
    )) {
      copyNumber = '${source.billNumber}-COPY-$suffix';
      suffix++;
    }
    return saveBill(
      PurchaseBillModel(
        billNumber: copyNumber,
        supplierId: source.supplierId,
        supplierName: source.supplierName,
        billDate: now,
        dueDate: source.dueDate == null
            ? null
            : now.add(source.dueDate!.difference(source.billDate)),
        items: source.items.map((item) => item.copyWith(id: null)).toList(),
        notes: source.notes,
        placeOfSupply: source.placeOfSupply,
        taxMode: source.taxMode,
        reverseCharge: source.reverseCharge,
        itcEligible: source.itcEligible,
        discountMinor: source.discountMinor,
        additionalChargesMinor: source.additionalChargesMinor,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<SupplierStatementEntry>> supplierStatement(
    int supplierId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final bills = await (database.select(
      database.purchaseBills,
    )..where((t) => t.supplierId.equals(supplierId))).get();
    final entries =
        <
          ({
            DateTime date,
            String title,
            String reference,
            int debit,
            int credit,
            String type,
          })
        >[];
    for (final bill in bills.where((b) => b.status != 'cancelled')) {
      entries.add((
        date: bill.billDate,
        title: 'Purchase bill',
        reference: bill.billNumber,
        debit: bill.totalMinor,
        credit: 0,
        type: 'bill',
      ));
      final payments = await (database.select(
        database.purchasePayments,
      )..where((t) => t.purchaseBillId.equals(bill.id))).get();
      for (final payment in payments) {
        entries.add((
          date: payment.paidAt,
          title: payment.entryType == 'reversal'
              ? 'Payment reversal'
              : 'Supplier payment',
          reference: payment.reference ?? bill.billNumber,
          debit: payment.entryType == 'reversal' ? -payment.amountMinor : 0,
          credit: payment.entryType == 'reversal' ? 0 : payment.amountMinor,
          type: payment.entryType,
        ));
      }
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    var balance = 0;
    return entries
        .where((entry) {
          balance += entry.debit - entry.credit;
          return (from == null || !entry.date.isBefore(from)) &&
              (to == null || !entry.date.isAfter(to));
        })
        .map(
          (entry) => SupplierStatementEntry(
            date: entry.date,
            title: entry.title,
            reference: entry.reference,
            debitMinor: entry.debit,
            creditMinor: entry.credit,
            balanceMinor: balance,
            type: entry.type,
          ),
        )
        .toList();
  }

  Future<int> _ledgerPaidMinor(int billId) async {
    final payments = await (database.select(
      database.purchasePayments,
    )..where((t) => t.purchaseBillId.equals(billId))).get();
    return payments.fold<int>(0, (sum, payment) => sum + payment.amountMinor);
  }

  Future<void> _reconcileBill(int billId) async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).getSingle();
    final paid = await _ledgerPaidMinor(billId);
    final balance = (bill.totalMinor - paid).clamp(0, bill.totalMinor);
    await (database.update(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).write(
      PurchaseBillsCompanion(
        paidMinor: Value(paid),
        balanceMinor: Value(balance),
        status: Value(_status(balance, bill.dueDate, paid: paid)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBill(int id) => database.transaction(() async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (bill == null) return;
    final paymentEntries = await (database.select(
      database.purchasePayments,
    )..where((t) => t.purchaseBillId.equals(id))).get();
    if (paymentEntries.isNotEmpty) {
      throw StateError(
        'Bills with payment history must be cancelled, not deleted.',
      );
    }
    await (database.delete(
      database.purchaseBills,
    )..where((t) => t.id.equals(id))).go();
  });

  Future<void> deleteSupplier(int id) =>
      (database.update(
        database.suppliers,
      )..where((t) => t.id.equals(id))).write(
        SuppliersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  String _status(int balance, DateTime? dueDate, {int paid = 0}) {
    if (balance <= 0) return 'paid';
    final today = DateTime.now();
    if (dueDate != null &&
        dueDate.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'overdue';
    }
    return paid > 0 ? 'partially_paid' : 'unpaid';
  }

  int _financialYear(DateTime date) =>
      date.month >= 4 ? date.year : date.year - 1;

  Future<SupplierModel?> getSupplier(int id) async {
    final row = await (database.select(
      database.suppliers,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _supplier(row);
  }

  SupplierModel _supplier(Supplier s) => SupplierModel(
    id: s.id,
    name: s.name,
    companyName: s.companyName,
    mobile: s.mobile,
    email: s.email,
    gstRegistrationType: s.gstRegistrationType,
    gstin: s.gstin,
    address: s.address,
    isDeleted: s.isDeleted,
    createdAt: s.createdAt,
    updatedAt: s.updatedAt,
  );
  PurchaseBillSummary _summary(PurchaseBill b) => PurchaseBillSummary(
    id: b.id,
    billNumber: b.billNumber,
    supplierId: b.supplierId,
    supplierName: b.supplierName,
    billDate: b.billDate,
    dueDate: b.dueDate,
    totalMinor: b.totalMinor,
    paidMinor: b.paidMinor,
    balanceMinor: b.balanceMinor,
    status: b.status,
  );
}
