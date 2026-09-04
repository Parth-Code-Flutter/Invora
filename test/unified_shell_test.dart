import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets(
    'splash-to-home dock covers documents, products, parties, and pay',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        AppStorageKeyConst.onboardingCompleted: true,
        AppStorageKeyConst.businessSetupCompleted: true,
        AppStorageKeyConst.backupReminderDays: 0,
      });
      final storage = await AppStorage.create();
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final databaseService = LocalDatabaseService(database);
      await databaseService.initialize();
      addTearDown(database.close);

      final now = DateTime(2026, 9, 4);
      await BusinessRepository(database).saveProfile(
        BusinessProfileModel(
          businessName: 'Unified Shop',
          currencySymbol: '₹',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final purchases = PurchaseRepository(database);
      final supplier = await purchases.saveSupplier(
        SupplierModel(name: 'Paper Vendor', createdAt: now, updatedAt: now),
      );
      await purchases.saveBill(
        PurchaseBillModel(
          billNumber: 'PB-100',
          supplierId: supplier.id,
          supplierName: supplier.name,
          billDate: now.subtract(const Duration(days: 10)),
          dueDate: now.subtract(const Duration(days: 2)),
          items: const [
            PurchaseItemModel(
              name: 'Paper',
              quantity: 1,
              unit: 'box',
              rateMinor: 50000,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        CreovoInvoiceApp(appStorage: storage, databaseService: databaseService),
      );
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text('Unified Shop'), findsWidgets);
      expect(find.text('To pay'), findsOneWidget);
      expect(find.text('Switch workspace'), findsNothing);
      expect(find.text('Change workspace'), findsNothing);

      await tester.tap(find.byIcon(Symbols.receipt_long_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Invoices'), findsWidgets);

      await tester.tap(find.text('Purchases'));
      await tester.pumpAndSettle();
      expect(find.text('Purchase bills'), findsWidgets);
      expect(find.text('PB-100'), findsWidgets);

      await tester.tap(find.byIcon(Symbols.groups_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Customers'), findsWidgets);
      expect(find.text('Suppliers'), findsWidgets);

      await tester.tap(find.text('Suppliers'));
      await tester.pumpAndSettle();
      expect(find.text('Paper Vendor'), findsWidgets);

      await tester.tap(find.byIcon(Symbols.package_2_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Products & services'), findsOneWidget);
      expect(find.text('Create new'), findsNothing);

      await tester.tap(find.byIcon(Symbols.apps_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Products & services'), findsOneWidget);
      expect(find.text('Change workspace'), findsNothing);
      expect(find.text('Sales'), findsNothing);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
