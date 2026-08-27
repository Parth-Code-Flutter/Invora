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
import 'package:creovo_invoice/app/widgets/app_constrained_action.dart';
import 'package:creovo_invoice/app/widgets/app_main_navigation.dart';
import 'package:creovo_invoice/app/widgets/app_shell.dart';
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
    expect(find.text('This month'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(Get.find<AppController>().themeMode.value, ThemeMode.dark);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Estimates'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Create invoice'), findsNothing);
    expect(find.text('Needs follow-up'), findsNothing);
    expect(find.text('Recent invoices'), findsNothing);
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

  testWidgets('onboarding fills tablet portrait without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = await AppStorage.create();
    Get.put(OnboardingController(storage));

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
    expect(find.text('Show me more'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet dashboard uses a two-pane home without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
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
    final now = DateTime(2026, 8, 12);
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Genz Clothes',
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

    expect(find.text('Genz Clothes'), findsWidgets);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Estimates'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Create invoice'), findsNothing);
    expect(find.text('Recent invoices'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('app shell uses a rail on tablet and the dock on phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> render(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AppShell(
            salesDestination: MainDestination.home,
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
    }

    await render(const Size(390, 844));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppMainNavigation), findsOneWidget);

    await render(const Size(834, 1194));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AppMainNavigation), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet action footer does not collapse the page body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: Center(child: Text('Page body stays visible')),
          bottomNavigationBar: AppConstrainedAction(
            child: SizedBox(height: 56, width: double.infinity),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Page body stays visible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
