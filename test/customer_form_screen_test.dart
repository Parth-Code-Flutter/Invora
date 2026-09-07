import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/customers/controllers/customer_form_controller.dart';
import 'package:creovo_invoice/modules/customers/screens/customer_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('create customer matches the Figma Add Customer layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    Get.put(CustomerFormController(CustomerRepository(database)));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const CustomerFormScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('CORE DETAILS'), findsOneWidget);
    expect(find.text('FAST BILLING'), findsOneWidget);
    expect(find.text('Customer / Shop Name *'), findsOneWidget);
    expect(find.text('e.g. Ramesh Patel or Acme Traders'), findsOneWidget);
    expect(find.text('Phone Number *'), findsOneWidget);
    expect(find.text('98765 43210'), findsOneWidget);
    expect(find.text('GSTIN & Billing Address'), findsOneWidget);
    expect(find.text('Optional for B2B tax invoicing'), findsOneWidget);
    expect(find.text('B2B Ready'), findsOneWidget);
    expect(find.text('GSTIN (Goods and Services Tax ID)'), findsOneWidget);
    expect(find.text('24AAAAA0000A1Z5'), findsOneWidget);
    expect(find.text('Registered business name'), findsOneWidget);
    expect(
      find.text('Shop/Office no., building, street, area...'),
      findsOneWidget,
    );
    expect(find.text('Pincode'), findsOneWidget);
    expect(find.text('Save Customer'), findsOneWidget);
    expect(
      find.text('Save and create new invoice immediately'),
      findsOneWidget,
    );
    expect(
      find.text('Instant offline save • Stays on this device'),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsNothing);
    expect(find.textContaining('govt portal'), findsNothing);
    expect(find.textContaining('Auto-syncs'), findsNothing);
    expect(
      find.text('Shipping address is the same as billing address'),
      findsNothing,
    );

    tester.view.physicalSize = const Size(320, 720);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Save Customer'), findsOneWidget);
  });
}
