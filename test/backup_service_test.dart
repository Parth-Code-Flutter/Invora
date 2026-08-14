import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late BackupService service;
  late Directory temporaryDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = BackupService(
      database,
      BusinessRepository(database),
      await AppStorage.create(),
    );
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'creovo_backup_test_',
    );
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('rejects a backup whose embedded database is corrupted', () async {
    final file = await _backupFile(
      temporaryDirectory,
      schemaVersion: 7,
      databaseBytes: utf8.encode('not a sqlite database'),
    );

    final result = await service.validate(file);
    expect(result.isValid, isFalse);
    expect(result.message, contains('damaged'));
  });

  test('accepts an older SQLite backup for migration after restore', () async {
    final file = await _backupFile(
      temporaryDirectory,
      schemaVersion: 5,
      databaseBytes: [
        ...utf8.encode('SQLite format 3\u0000'),
        ...List<int>.filled(100, 0),
      ],
    );

    final result = await service.validate(file);
    expect(result.isValid, isTrue);
  });

  test('rejects backup metadata without a valid schema version', () async {
    final file = await _backupFile(
      temporaryDirectory,
      schemaVersion: 0,
      databaseBytes: [
        ...utf8.encode('SQLite format 3\u0000'),
        ...List<int>.filled(100, 0),
      ],
    );

    final result = await service.validate(file);
    expect(result.isValid, isFalse);
    expect(result.message, contains('version'));
  });

  test('rejects incomplete and newer-version backups', () async {
    final incomplete = File('${temporaryDirectory.path}/incomplete.zip');
    final incompleteArchive = Archive()
      ..addFile(
        ArchiveFile.string(
          'metadata.json',
          jsonEncode({
            'format': 'creovo-invoice-backup',
            'version': 1,
            'schemaVersion': 8,
          }),
        ),
      );
    await incomplete.writeAsBytes(ZipEncoder().encode(incompleteArchive));
    expect((await service.validate(incomplete)).message, contains('missing'));

    final newer = await _backupFile(
      temporaryDirectory,
      schemaVersion: 999,
      databaseBytes: _sqliteBytes('newer'),
    );
    expect((await service.validate(newer)).message, contains('newer'));
  });

  test('failed restore puts the original database file back', () async {
    final target = File('${temporaryDirectory.path}/active.sqlite');
    final original = _sqliteBytes('original customer data');
    await target.writeAsBytes(original);
    service = BackupService(
      database,
      BusinessRepository(database),
      await AppStorage.create(),
      databaseFileProvider: () async => target,
    );
    final backup = await _backupFile(
      temporaryDirectory,
      schemaVersion: 8,
      databaseBytes: _sqliteBytes('replacement data'),
      settingsBytes: utf8.encode('{invalid settings'),
    );

    await expectLater(service.restore(backup), throwsA(isA<FormatException>()));
    expect(await target.readAsBytes(), original);
    expect(await File('${target.path}.before_restore').exists(), isFalse);
  });

  test('successful restore replaces data and records restart state', () async {
    final target = File('${temporaryDirectory.path}/active.sqlite');
    await target.writeAsBytes(_sqliteBytes('old'));
    final storage = await AppStorage.create();
    service = BackupService(
      database,
      BusinessRepository(database),
      storage,
      databaseFileProvider: () async => target,
    );
    final replacement = _sqliteBytes('restored');
    final backup = await _backupFile(
      temporaryDirectory,
      schemaVersion: 8,
      databaseBytes: replacement,
    );

    final result = await service.restore(backup);

    expect(await target.readAsBytes(), replacement);
    expect(result.mediaPaths.values, everyElement(isNull));
    expect(storage.getBool(AppStorageKeyConst.restoreCompleted), isTrue);
  });

  test('restores portable media into current device asset paths', () async {
    final target = File('${temporaryDirectory.path}/active.sqlite');
    await target.writeAsBytes(_sqliteBytes('old'));
    service = BackupService(
      database,
      BusinessRepository(database),
      await AppStorage.create(),
      databaseFileProvider: () async => target,
    );
    final backup = await _backupFile(
      temporaryDirectory,
      schemaVersion: 8,
      databaseBytes: _sqliteBytes('restored'),
      media: {
        'logo.jpg': [1, 2, 3],
        'payment_qr.png': [4, 5],
      },
    );

    final result = await service.restore(backup);

    final logo = File(result.mediaPaths['logo']!);
    final qr = File(result.mediaPaths['payment_qr']!);
    expect(logo.path, contains('business_assets'));
    expect(await logo.readAsBytes(), [1, 2, 3]);
    expect(await qr.readAsBytes(), [4, 5]);
    expect(result.mediaPaths['signature'], isNull);
  });

  test('stores a validated local reminder interval', () async {
    expect(service.reminderDays, 7);
    expect(service.isBackupDue, isTrue);

    await service.setReminderDays(14);
    expect(service.reminderDays, 14);
    await service.setReminderDays(0);
    expect(service.isBackupDue, isFalse);
    await expectLater(service.setReminderDays(2), throwsArgumentError);
  });
}

Future<File> _backupFile(
  Directory directory, {
  required int schemaVersion,
  required List<int> databaseBytes,
  List<int>? settingsBytes,
  Map<String, List<int>> media = const {},
}) async {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'metadata.json',
        jsonEncode({
          'format': 'creovo-invoice-backup',
          'version': 1,
          'schemaVersion': schemaVersion,
        }),
      ),
    )
    ..addFile(
      ArchiveFile(
        'data/creovo_invoice.sqlite',
        databaseBytes.length,
        databaseBytes,
      ),
    );
  for (final entry in media.entries) {
    archive.addFile(
      ArchiveFile('media/${entry.key}', entry.value.length, entry.value),
    );
  }
  if (settingsBytes != null) {
    archive.addFile(
      ArchiveFile('settings.json', settingsBytes.length, settingsBytes),
    );
  }
  final file = File('${directory.path}/backup_$schemaVersion.zip');
  await file.writeAsBytes(ZipEncoder().encode(archive), flush: true);
  return file;
}

List<int> _sqliteBytes(String content) => [
  ...utf8.encode('SQLite format 3\u0000'),
  ...utf8.encode(content),
  ...List<int>.filled(100, 0),
];
