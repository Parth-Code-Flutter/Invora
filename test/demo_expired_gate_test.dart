import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/demo_access_service.dart';
import 'package:creovo_invoice/data/services/demo_build_config.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('expired demo APK blocks the app with the sales contact dialog', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final databaseService = LocalDatabaseService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await databaseService.initialize();
    addTearDown(databaseService.database.close);

    await tester.pumpWidget(
      CreovoInvoiceApp(
        appStorage: storage,
        databaseService: databaseService,
        demoAccess: DemoAccessService(
          config: DemoBuildConfig(
            expiresAt: DateTime(2026, 8, 12),
            buildTime: DateTime(2026, 8, 5),
            clientName: 'Sharma Traders',
          ),
          storage: storage,
          clock: () => DateTime(2026, 8, 19),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Please contact your sales person'), findsWidgets);
    expect(find.textContaining('Sharma Traders'), findsWidgets);
    expect(
      find.text('Your invoice, ready in minutes').hitTestable(),
      findsNothing,
    );
  });

  testWidgets('a valid demo day still opens the normal app', (tester) async {
    final storage = await AppStorage.create();
    final databaseService = LocalDatabaseService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await databaseService.initialize();
    addTearDown(databaseService.database.close);

    await tester.pumpWidget(
      CreovoInvoiceApp(
        appStorage: storage,
        databaseService: databaseService,
        demoAccess: DemoAccessService(
          config: DemoBuildConfig(
            expiresAt: DateTime(2026, 8, 26),
            buildTime: DateTime(2026, 8, 19),
          ),
          storage: storage,
          clock: () => DateTime(2026, 8, 19, 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Please contact your sales person'), findsNothing);
    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
  });
}
