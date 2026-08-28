import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/purchase_order_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/purchase_orders/controllers/purchase_order_controller.dart';
import 'package:creovo_invoice/modules/purchase_orders/screens/purchase_order_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'create purchase order composer shows supplier, items, and draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final purchases = PurchaseRepository(database);
      Get.put(
        PurchaseOrderFormController(
          PurchaseOrderRepository(database, purchases),
          purchases,
        ),
      );
      addTearDown(() async {
        Get.reset();
        await database.close();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const PurchaseOrderFormScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('Create purchase order'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Who is this purchase order for?'), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Add first item'), findsWidgets);
      expect(find.text('Issue purchase order'), findsNothing);
      expect(find.text('Save draft'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
