import 'package:drift/native.dart';
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
import 'package:flutter/material.dart';

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

  testWidgets('asks for a backup password before creating a file', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: BackupScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Backup recommended'), findsOneWidget);
    expect(find.textContaining('Password protected'), findsOneWidget);

    final createButton = find.widgetWithText(
      AppButton,
      'Create and share backup',
    );
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Create encrypted backup'), findsOneWidget);
    expect(find.text('Backup password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Create backup'), findsOneWidget);
  });

  testWidgets('asks twice before erasing, including typing ERASE', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GetMaterialApp(home: BackupScreen()));
    await tester.pumpAndSettle();

    final eraseButton = find.byIcon(
      Icons.delete_forever_outlined,
      skipOffstage: false,
    );
    await tester.ensureVisible(eraseButton);
    await tester.pumpAndSettle();
    expect(find.text('Erase all data'), findsWidgets);
    await tester.tap(eraseButton);
    await tester.pumpAndSettle();

    expect(find.text('Erase all data?'), findsOneWidget);
    expect(find.textContaining('This cannot be undone'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Type ERASE to confirm'), findsOneWidget);
    expect(
      find.text('Type ERASE in capital letters to confirm.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Erase all data'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField), 'erase');
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Erase all data'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField), 'ERASE');
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Erase all data'))
          .onPressed,
      isNotNull,
    );
  });
}
