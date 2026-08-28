import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/delivery_challan_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/delivery_challans/controllers/delivery_challan_controller.dart';
import 'package:creovo_invoice/modules/delivery_challans/screens/delivery_challan_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'create delivery challan composer shows customer, items, and draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final invoices = InvoiceRepository(database);
      Get.put(
        DeliveryChallanFormController(
          DeliveryChallanRepository(database, invoices),
          CustomerRepository(database),
          invoices,
        ),
      );
      addTearDown(() async {
        Get.reset();
        await database.close();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const DeliveryChallanFormScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('Create delivery challan'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Who is this challan for?'), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Add first item'), findsOneWidget);
      expect(find.text('Issue challan'), findsNothing);
      expect(find.text('Save draft'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
