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

  Future<bool> isBillNumberAvailable(String number, {int? excludingId}) async {
    final normalized = number.trim().toLowerCase();
    final rows = await database.select(database.purchaseBills).get();
    return !rows.any(
      (bill) =>
          bill.id != excludingId &&
          bill.billNumber.trim().toLowerCase() == normalized,
    );
  }

  Stream<PurchaseDashboardSummary> watchDashboard() =>
      database.select(database.purchaseBills).watch().asyncMap((bills) async {
        final supplierCount =
            await (database.selectOnly(database.suppliers)
                  ..addColumns([database.suppliers.id.count()])
                  ..where(database.suppliers.isDeleted.equals(false)))
                .map((r) => r.read(database.suppliers.id.count()) ?? 0)
                .getSingle();
        final now = DateTime.now();
        return PurchaseDashboardSummary(
          totalSpendMinor: bills.fold(0, (s, b) => s + b.totalMinor),
          paidMinor: bills.fold(0, (s, b) => s + b.paidMinor),
          payableMinor: bills.fold(0, (s, b) => s + b.balanceMinor),
          overdueMinor: bills
              .where(
                (b) =>
                    b.balanceMinor > 0 &&
                    b.dueDate != null &&
                    b.dueDate!.isBefore(DateTime(now.year, now.month, now.day)),
              )
              .fold(0, (s, b) => s + b.balanceMinor),
          billCount: bills.length,
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
              rateMinor: i.rateMinor,
              taxRate: i.taxRateBasisPoints / 100,
            ),
          )
          .toList(),
      paidMinor: bill.paidMinor,
      notes: bill.notes,
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
                    note: p.note,
                    paidAt: p.paidAt,
                  ),
                )
                .toList(),
          );

  Future<int> saveBill(PurchaseBillModel model) =>
      database.transaction(() async {
        final status = _status(model.balanceMinor, model.dueDate);
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
          paidMinor: Value(model.paidMinor.clamp(0, model.totalMinor)),
          balanceMinor: Value(model.balanceMinor),
          status: Value(status),
          notes: Value(model.notes),
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
    String? note,
  }) => database.transaction(() async {
    final bill = await (database.select(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).getSingle();
    if (amountMinor <= 0 || amountMinor > bill.balanceMinor) {
      throw ArgumentError('Payment must be within the outstanding balance.');
    }
    await database
        .into(database.purchasePayments)
        .insert(
          PurchasePaymentsCompanion.insert(
            purchaseBillId: billId,
            amountMinor: amountMinor,
            method: Value(method),
            note: Value(note),
            paidAt: DateTime.now(),
          ),
        );
    final paid = bill.paidMinor + amountMinor;
    final balance = bill.totalMinor - paid;
    await (database.update(
      database.purchaseBills,
    )..where((t) => t.id.equals(billId))).write(
      PurchaseBillsCompanion(
        paidMinor: Value(paid),
        balanceMinor: Value(balance),
        status: Value(_status(balance, bill.dueDate)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<void> deleteBill(int id) => (database.delete(
    database.purchaseBills,
  )..where((t) => t.id.equals(id))).go();

  String _status(int balance, DateTime? dueDate) {
    if (balance <= 0) return 'paid';
    final today = DateTime.now();
    if (dueDate != null &&
        dueDate.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'overdue';
    }
    return 'unpaid';
  }

  SupplierModel _supplier(Supplier s) => SupplierModel(
    id: s.id,
    name: s.name,
    companyName: s.companyName,
    mobile: s.mobile,
    email: s.email,
    gstin: s.gstin,
    address: s.address,
    isDeleted: s.isDeleted,
    createdAt: s.createdAt,
    updatedAt: s.updatedAt,
  );
  PurchaseBillSummary _summary(PurchaseBill b) => PurchaseBillSummary(
    id: b.id,
    billNumber: b.billNumber,
    supplierName: b.supplierName,
    billDate: b.billDate,
    dueDate: b.dueDate,
    totalMinor: b.totalMinor,
    paidMinor: b.paidMinor,
    balanceMinor: b.balanceMinor,
    status: b.status,
  );
}
