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
}
