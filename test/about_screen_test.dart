import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_lock_service.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/diagnostics_service.dart';
import 'package:creovo_invoice/modules/settings/controllers/about_controller.dart';
import 'package:creovo_invoice/modules/settings/screens/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('about screen shows version, schema, and diagnostics actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final seed = DiagnosticsReport(
      generatedAt: DateTime.utc(2026, 8, 29),
      appVersion: '1.0.0',
      buildNumber: '1',
      schemaVersion: 22,
      platform: 'android',
      osVersion: '16',
      appLockEnabled: false,
      lastBackupAt: null,
      counts: const {'Customers': 0, 'Invoices': 2},
    );
    Get.put(
      AboutController(
        DiagnosticsService(database, storage),
        AppLockService(storage)..load(),
        seed: seed,
      ),
    );
    addTearDown(() async {
      Get.reset();
      await database.close();
    });

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Creovo Billing'), findsOneWidget);
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    expect(find.text('Schema 22'), findsOneWidget);
    expect(find.text('How this app works'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Share diagnostics'), findsOneWidget);
    expect(find.text('Save diagnostics'), findsOneWidget);
    expect(find.text('Customers: 0'), findsOneWidget);
    expect(find.text('Last backup: Never'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
