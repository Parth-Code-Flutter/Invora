import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/backup_service.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/modules/backup_restore/controllers/backup_controller.dart';
import 'package:creovo_invoice/modules/backup_restore/screens/backup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final storage = await AppStorage.create();
    Get.put(
      BackupController(
        BackupService(database, BusinessRepository(database), storage),
      ),
    );
  });

  tearDown(() async {
    await database.close();
    Get.reset();
  });

  testWidgets('warns about sensitive unencrypted data before backup', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: BackupScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Backup recommended'), findsOneWidget);

    final createButton = find.widgetWithText(AppButton, 'Create and share ZIP');
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Create sensitive-data backup?'), findsOneWidget);
    expect(find.textContaining('unencrypted ZIP'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create backup'), findsOneWidget);
  });
}
