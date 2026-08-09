import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invora/data/services/app_storage.dart';
import 'package:invora/data/services/app_database.dart';
import 'package:invora/data/services/local_database_service.dart';
import 'package:invora/main.dart';
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
      InvoraApp(appStorage: storage, databaseService: databaseService),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invoices in seconds'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your business'), findsOneWidget);
  });
}
