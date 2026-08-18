import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
  test(
    'purchase records remain isolated and support bill/payment lifecycle',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = PurchaseRepository(database);
      final now = DateTime(2026, 8, 15);
      final supplier = await repository.saveSupplier(
        SupplierModel(
          name: 'Paper Vendor',
          mobile: '9999999999',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final billId = await repository.saveBill(
        PurchaseBillModel(
          billNumber: 'PB-001',
          supplierId: supplier.id,
          supplierName: supplier.name,
          billDate: now,
          dueDate: now.add(const Duration(days: 7)),
          items: const [
            PurchaseItemModel(
              name: 'Paper',
              quantity: 2,
              unit: 'box',
              rateMinor: 10000,
              taxRate: 18,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(await repository.isBillNumberAvailable('pb-001'), isFalse);
      expect(
        await repository.isBillNumberAvailable('PB-001', excludingId: billId),
        isTrue,
      );

      var bill = await repository.getBill(billId);
      expect(bill?.totalMinor, 23600);
      expect(bill?.balanceMinor, 23600);
      await repository.recordPayment(billId, 3600, method: 'UPI');
      await expectLater(
        repository.recordPayment(billId, 999999),
        throwsArgumentError,
      );
      bill = await repository.getBill(billId);
      expect(bill?.paidMinor, 3600);
      expect(bill?.balanceMinor, 20000);
      expect(await repository.watchPayments(billId).first, hasLength(1));
      await repository.saveBill(
        PurchaseBillModel(
          id: bill!.id,
          billNumber: bill.billNumber,
          supplierId: bill.supplierId,
          supplierName: bill.supplierName,
          billDate: bill.billDate,
          dueDate: bill.dueDate,
          items: bill.items,
          paidMinor: bill.paidMinor,
          notes: 'Edited without replacing the ledger',
          createdAt: bill.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      expect(await repository.watchPayments(billId).first, hasLength(1));
      expect(await database.select(database.invoices).get(), isEmpty);
      expect(await database.select(database.customers).get(), isEmpty);
      expect(
        (await repository.watchBills().first).single.supplierId,
        supplier.id,
      );
      await repository.deleteSupplier(supplier.id!);
      expect(await repository.watchSuppliers().first, isEmpty);
      expect(await repository.watchBills().first, isNotEmpty);
      await database.close();
    },
  );
}
