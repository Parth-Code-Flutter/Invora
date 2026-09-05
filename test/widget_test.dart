import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:creovo_invoice/app/controllers/app_controller.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch routes from onboarding to business setup', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final databaseService = LocalDatabaseService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await databaseService.initialize();
    addTearDown(databaseService.database.close);

    await tester.pumpWidget(
      CreovoInvoiceApp(appStorage: storage, databaseService: databaseService),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Business Profile'), findsOneWidget);

    final context = tester.element(find.text('Business Profile'));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Open overlay')),
    );
    await tester.pumpAndSettle();
    await Get.find<AppController>().setDarkMode(true);
    await tester.pumpAndSettle();

    expect(find.text('Open overlay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
