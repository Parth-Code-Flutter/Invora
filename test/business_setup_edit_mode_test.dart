import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/image_storage_service.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/modules/business_setup/controllers/business_setup_controller.dart';
import 'package:creovo_invoice/modules/business_setup/screens/business_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('existing business opens in edit mode with a back action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = BusinessRepository(database);
    final now = DateTime(2026, 8, 13);
    await repository.saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo MDF',
        ownerName: 'Harsh Mandavia',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final controller = Get.put(
      BusinessSetupController(
        repository,
        storage,
        ImageStorageService(),
        ProductSettingsService(storage),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const BusinessSetupScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Business Profile'), findsOneWidget);
    expect(find.text('Business Profile'), findsNothing);
    expect(find.text('Receipt & Invoice Branding'), findsOneWidget);
    expect(find.text('Identity & Brand'), findsOneWidget);
    expect(find.text('Preview bill'), findsOneWidget);
    expect(find.text('Let’s make it yours'), findsNothing);
    expect(find.text('Business identity'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Creovo MDF'), findsWidgets);
    expect(find.text('CM'), findsWidgets);
    expect(find.text('Save & update invoices'), findsOneWidget);
    expect(find.text('Next: invoice details'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Contact on Invoices'), findsOneWidget);
    expect(controller.validateEmail(''), isNull);
    expect(controller.validateEmail('invalid-email'), isNotNull);
  });

  testWidgets('first launch starts with the Figma business profile form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    Get.put(
      BusinessSetupController(
        BusinessRepository(database),
        storage,
        ImageStorageService(),
        ProductSettingsService(storage),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const BusinessSetupScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Business Profile'), findsOneWidget);
    expect(find.text('Edit Business Profile'), findsNothing);
    expect(find.text('Let’s make it yours'), findsNothing);
    expect(
      find.text('Type your shop name to start. Logo and extras can wait.'),
      findsNothing,
    );
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('Business Name'), findsOneWidget);
    expect(find.text('Store Category'), findsOneWidget);
    expect(find.text('Store Logo'), findsOneWidget);
    expect(find.text('General Business'), findsWidgets);
    expect(find.text('Your business'), findsOneWidget);
    expect(find.text('INVOICE'), findsOneWidget);
    expect(find.text('YB'), findsWidgets);
    expect(find.text('Save & start invoicing'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Your business')).dy,
      lessThan(tester.getTopLeft(find.text('Business Name')).dy),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Creovo Studio');
    await tester.pump();
    expect(find.text('Creovo Studio'), findsWidgets);
    expect(find.text('CS'), findsWidgets);

    await tester.tap(find.text('General Business').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grocery / Kirana').last);
    await tester.pumpAndSettle();
    expect(find.text('Grocery / Kirana'), findsWidgets);
  });
}
