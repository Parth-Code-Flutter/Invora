import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/constants/db_constants.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AppStorage storage;
  late DiagnosticsService diagnostics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await AppStorage.create();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    diagnostics = DiagnosticsService(database, storage);
  });

  tearDown(() => database.close());

  test('reports counts and versions without party or tax identity', () async {
    await CustomerRepository(database).save(
      CustomerModel(
        name: 'Secret Party LLP',
        gstin: '24AAAAA0000A1Z5',
        mobile: '9876543210',
        createdAt: DateTime(2026, 8, 29),
        updatedAt: DateTime(2026, 8, 29),
      ),
    );
    await storage.setString(
      AppStorageKeyConst.lastBackupAt,
      DateTime(2026, 8, 28, 9).toIso8601String(),
    );

    final report = await diagnostics.collect(
      appVersion: '1.0.0',
      buildNumber: '1',
      platform: 'android',
      osVersion: '16',
      appLockEnabled: true,
      generatedAt: DateTime.utc(2026, 8, 29, 1, 5),
    );
    final text = report.toShareText();

    expect(report.schemaVersion, DbConstants.schemaVersion);
    expect(report.counts['Customers'], 1);
    expect(report.appLockEnabled, isTrue);
    expect(text, contains('Schema: ${DbConstants.schemaVersion}'));
    expect(text, contains('Customers: 1'));
    expect(text, contains('App lock: On'));
    expect(text, contains('Last backup: 2026-08-28T09:00:00.000'));
    expect(text, contains('record counts only'));
    expect(text, isNot(contains('Secret Party LLP')));
    expect(text, isNot(contains('24AAAAA0000A1Z5')));
    expect(text, isNot(contains('9876543210')));
  });
}
