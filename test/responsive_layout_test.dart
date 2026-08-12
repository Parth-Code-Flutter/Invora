import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:drift/native.dart';
import 'package:creovo_invoice/app/utils/responsive_utils.dart';
import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/controllers/app_controller.dart';
import 'package:creovo_invoice/app/routes/app_routes.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/main.dart';
import 'package:creovo_invoice/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:creovo_invoice/modules/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  testWidgets('responsive helpers distinguish phone and tablet layouts', (
    tester,
  ) async {
    AppDeviceType? type;
    int? columns;

    Future<void> render(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              type = ResponsiveUtils.deviceType(context);
              columns = ResponsiveUtils.gridColumns(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    await render(const Size(390, 844));
    expect(type, AppDeviceType.phone);
    expect(columns, 1);

    await render(const Size(834, 1194));
    expect(type, AppDeviceType.tablet);
    expect(columns, 2);

    await render(const Size(1194, 834));
    expect(type, AppDeviceType.largeTablet);
    expect(columns, 3);
  });

  testWidgets('onboarding renders without overflow on tablet landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    final storage = await AppStorage.create();
    Get.put(OnboardingController(storage));

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard remains usable on a small phone in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.onboardingCompleted: true,
      AppStorageKeyConst.businessSetupCompleted: true,
      AppStorageKeyConst.isDarkMode: true,
      AppStorageKeyConst.backupReminderDays: 0,
    });
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final databaseService = LocalDatabaseService(database);
    await databaseService.initialize();
    addTearDown(database.close);
    final now = DateTime(2026, 8, 12);
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo QA',
        currencySymbol: '₹',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      CreovoInvoiceApp(appStorage: storage, databaseService: databaseService),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Creovo QA'), findsOneWidget);
    expect(find.text('Business overview'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(Get.find<AppController>().themeMode.value, ThemeMode.dark);
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Create invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('invoice create route resolves the non-null defaults service', (
    tester,
  ) async {
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
    final now = DateTime(2026, 8, 12);
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Route QA',
        currencySymbol: '₹',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      CreovoInvoiceApp(appStorage: storage, databaseService: databaseService),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    Get.toNamed<void>(AppRoutes.invoiceCreate);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('New invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
