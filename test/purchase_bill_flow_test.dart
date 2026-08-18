import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/purchases/screens/purchase_screens.dart';

void main() {
  testWidgets(
    'new purchase bill requires supplier selection before bill entry',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = PurchaseRepository(database);
      Get.put<PurchaseRepository>(repository);
      addTearDown(() async {
        Get.reset();
        await database.close();
      });
      final now = DateTime.now();
      await repository.saveSupplier(
        SupplierModel(name: 'Demo Supplier', createdAt: now, updatedAt: now),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const PurchaseBillFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Who supplied this purchase?'), findsOneWidget);
      expect(find.text('Supplier bill number *'), findsNothing);
      await tester.tap(find.text('Demo Supplier'));
      await tester.pumpAndSettle();
      expect(find.text('Supplier bill number *'), findsOneWidget);
      expect(find.text('Purchased items'), findsOneWidget);
      expect(find.text('Choose a supplier'), findsNothing);
      expect(find.text('Add item'), findsWidgets);
      expect(find.text('NO ITEMS YET'), findsOneWidget);

      await tester.tap(find.text('Add item').first);
      await tester.pumpAndSettle();
      expect(find.text('Choose saved item'), findsOneWidget);
      expect(find.text('Scan barcodes'), findsOneWidget);
      expect(find.text('Create custom item'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
