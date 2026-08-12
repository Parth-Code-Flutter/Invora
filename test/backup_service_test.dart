import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

Future<File> _backupFile(
  Directory directory, {
  required int schemaVersion,
  required List<int> databaseBytes,
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
  final file = File('${directory.path}/backup_$schemaVersion.zip');
  await file.writeAsBytes(ZipEncoder().encode(archive), flush: true);
  return file;
}
