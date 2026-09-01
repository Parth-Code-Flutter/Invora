import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_back_button.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/app/widgets/app_dropdown_field.dart';
import 'package:creovo_invoice/data/models/business_category_model.dart';
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

    expect(find.text('Business profile'), findsOneWidget);
    expect(find.text('Business identity'), findsOneWidget);
    expect(find.text('Let’s make it yours'), findsNothing);
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(
      find.text('Preview the header customers will see on invoices.'),
      findsOneWidget,
    );
    expect(find.text('Creovo MDF'), findsNWidgets(2));
    expect(find.text('Next: invoice details'), findsOneWidget);
    expect(controller.validateEmail(''), isNull);
    expect(controller.validateEmail('invalid-email'), isNotNull);
  });

  testWidgets('first launch starts with the shop name, not the optional logo', (
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

    expect(find.text('Let’s make it yours'), findsOneWidget);
    expect(
      find.text('Type your shop name to start. Logo and extras can wait.'),
      findsOneWidget,
    );
    expect(find.text('Your identity'), findsNothing);
    expect(find.text('Add business logo'), findsNothing);
    expect(find.text('Business name *'), findsOneWidget);
    expect(find.text('What do you sell?'), findsNothing);
    expect(find.text('Kirana'), findsNothing);
    expect(find.text('Business category'), findsOneWidget);
    expect(find.text('General Business'), findsWidgets);
    expect(find.text('Add a business logo'), findsNothing);
    expect(find.text('Tap mark to add a logo'), findsNothing);
    expect(find.text('Add logo'), findsOneWidget);
    expect(find.text('Your business'), findsOneWidget);
    expect(find.text('INVOICE'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Your business')).dy,
      lessThan(tester.getTopLeft(find.text('Business name *')).dy),
    );

    await tester.enterText(find.byType(TextFormField), 'Creovo Studio');
    await tester.pump();
    expect(find.text('Creovo Studio'), findsWidgets);

    await tester.tap(find.byType(AppDropdownField<BusinessCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grocery / Kirana').last);
    await tester.pumpAndSettle();
    expect(find.text('Grocery / Kirana'), findsWidgets);

    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How can customers reach you?'), findsOneWidget);
  });
}
