import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/modules/invoices/controllers/invoice_create_controller.dart';
import 'package:creovo_invoice/modules/invoices/screens/invoice_create_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  Future<InvoiceCreateController> pumpComposer(
    WidgetTester tester, {
    required AppDatabase database,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    Get.put(ProductSettingsService(storage));
    final controller = Get.put(
      InvoiceCreateController(
        InvoiceRepository(database),
        BusinessRepository(database),
        CustomerRepository(database),
        ProductRepository(database),
        const InvoiceCalculationService(),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const InvoiceCreateScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    return controller;
  }

  Future<void> dismissCustomerPrompt(WidgetTester tester) async {
    expect(find.text('Who is this invoice for?'), findsOneWidget);
    Get.back<void>();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('create invoice matches the Figma empty composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 9, 7);
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo Studio',
        gstRegistered: true,
        gstin: '24AAAAA0000A1Z5',
        currencySymbol: '₹',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await pumpComposer(tester, database: database);
    await dismissCustomerPrompt(tester);

    expect(find.text('#INV-0001'), findsOneWidget);
    expect(find.text('Creovo Studio • GST Tax Invoice'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Who is this invoice for?'), findsNothing);
    expect(find.text('DATE'), findsNothing);
    expect(find.text('TERMS'), findsNothing);
    expect(find.text('Invoice Items'), findsOneWidget);
    expect(find.text('Add Item'), findsNothing);
    expect(find.text('No items added yet'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Add Service'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('PAYMENT & TAX BREAKDOWN'), findsNothing);
    expect(find.text('MARK INVOICE AS'), findsNothing);
    expect(find.text('Invoice Notes & Terms'), findsOneWidget);
    expect(find.text('INVOICE NOTES & TERMS'), findsNothing);
    expect(find.text('Add items to continue'), findsOneWidget);
    expect(
      find.text('Saved offline on phone • Ready for PDF & WhatsApp share'),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsNothing);
    expect(find.text('New invoice'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    tester.view.physicalSize = const Size(320, 720);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Add items to continue'), findsOneWidget);
  });

  testWidgets('create invoice shows review CTA after an item is added', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = await pumpComposer(tester, database: database);
    await dismissCustomerPrompt(tester);
    controller.addProduct(
      ProductServiceModel(
        id: 8,
        name: 'MDF Circle',
        type: ItemType.product,
        unit: 'pcs',
        salePriceMinor: 18200,
        hsnSac: '4410',
        taxRateBasisPoints: 1800,
        createdAt: DateTime(2026, 9, 7),
        updatedAt: DateTime(2026, 9, 7),
      ),
    );
    await tester.pump();

    expect(find.text('MDF Circle'), findsOneWidget);
    expect(find.text('Add items to continue'), findsNothing);
    expect(find.text('Review invoice'), findsOneWidget);
    expect(find.text('No items added yet'), findsNothing);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Add Product'), findsNothing);
    expect(find.text('PAYMENT & TAX BREAKDOWN'), findsOneWidget);
    expect(find.text('MARK INVOICE AS'), findsOneWidget);
    expect(find.text('INVOICE NOTES & TERMS'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('TERMS'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byTooltip('Edit item details'), findsNothing);
    expect(find.byTooltip('Remove item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
