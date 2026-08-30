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
import 'package:creovo_invoice/data/services/backup_crypto.dart';
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

  test(
    'encrypts new backups and restores them with the password',
    () async {
      final target = File('${temporaryDirectory.path}/active.sqlite');
      await target.writeAsBytes(_sqliteBytes('old live data'));
      final storage = await AppStorage.create();
      service = BackupService(
        database,
        BusinessRepository(database),
        storage,
        databaseFileProvider: () async => target,
      );
      const password = 'correct horse';
      final backup = await _encryptedBackup(
        temporaryDirectory,
        password: password,
        schemaVersion: 8,
        databaseBytes: _sqliteBytes('encrypted restored'),
        businessName: 'Creovo MDF',
      );

      expect(await service.isEncryptedBackup(backup), isTrue);
      final missing = await service.validate(backup);
      expect(missing.isValid, isFalse);
      expect(missing.message, contains('password protected'));
      expect(missing.preview?.businessName, 'Creovo MDF');

      final wrong = await service.validate(backup, password: 'wrong-pass');
      expect(wrong.isValid, isFalse);
      expect(wrong.message, contains('Wrong backup password'));

      final original = await target.readAsBytes();
      final inspected = await service.validate(backup, password: password);
      expect(inspected.isValid, isTrue);
      expect(inspected.preview?.encrypted, isTrue);
      expect(await target.readAsBytes(), original);

      await expectLater(
        service.restore(backup, password: 'wrong-pass'),
        throwsA(isA<StateError>()),
      );
      expect(await target.readAsBytes(), original);

      final result = await service.restore(backup, password: password);
      expect(await target.readAsBytes(), _sqliteBytes('encrypted restored'));
      expect(result.mediaPaths.values, everyElement(isNull));
      expect(storage.getBool(AppStorageKeyConst.restoreCompleted), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'keeps five local encrypted generations',
    () async {
      final liveDb = File('${temporaryDirectory.path}/live.sqlite');
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(liveDb));
      final generations = Directory('${temporaryDirectory.path}/generations');
      final output = Directory('${temporaryDirectory.path}/share');
      await generations.create();
      await output.create();
      service = BackupService(
        database,
        BusinessRepository(database),
        await AppStorage.create(),
        databaseFileProvider: () async => liveDb,
        outputDirectoryProvider: () async => output,
        generationsDirectoryProvider: () async => generations,
      );

      await database.customSelect('SELECT 1').get();
      for (var i = 0; i < 6; i++) {
        await service.createBackup(password: 'correct horse');
      }

      final kept = await service.listLocalGenerations();
      expect(kept, hasLength(5));
      expect(
        output.listSync().whereType<File>().length,
        greaterThanOrEqualTo(1),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('rejects a backup password shorter than eight characters', () async {
    await expectLater(
      service.createBackup(password: 'short'),
      throwsArgumentError,
    );
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

  test('restores portable purchase bill attachments', () async {
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
      schemaVersion: 11,
      databaseBytes: _sqliteBytes('restored'),
      purchaseAttachments: {
        'supplier_bill_1.pdf': [9, 8, 7, 6],
      },
    );

    await service.restore(backup);

    final restored = File(
      '${temporaryDirectory.path}/purchase_attachments/supplier_bill_1.pdf',
    );
    expect(await restored.readAsBytes(), [9, 8, 7, 6]);
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

  test(
    'eraseAllLocalData deletes sqlite, media, local generations, and prefs',
    () async {
      await database.close();
      final support = Directory('${temporaryDirectory.path}/support');
      await support.create();
      final liveDb = File('${support.path}/invora.sqlite');
      database = AppDatabase.forTesting(NativeDatabase(liveDb));
      await database.customSelect('SELECT 1').get();

      final images = Directory('${support.path}/product_images');
      await images.create();
      await File('${images.path}/cover.jpg').writeAsBytes([1, 2, 3]);
      final assets = Directory('${support.path}/business_assets');
      await assets.create();
      await File('${assets.path}/logo.png').writeAsBytes([4]);
      final attachments = Directory('${support.path}/purchase_attachments');
      await attachments.create();
      await File('${attachments.path}/bill.pdf').writeAsBytes([5]);
      final generations = Directory(
        '${temporaryDirectory.path}/creovo_backups',
      );
      await generations.create();
      final localZip = File(
        '${generations.path}/creovo_billing_backup_old.zip',
      );
      await localZip.writeAsBytes([6]);
      final sharedCopy = File('${temporaryDirectory.path}/shared_backup.zip');
      await sharedCopy.writeAsBytes([7]);

      final storage = await AppStorage.create();
      await storage.setBool(AppStorageKeyConst.onboardingCompleted, true);
      await storage.setBool(AppStorageKeyConst.appLockEnabled, true);
      await storage.setString(AppStorageKeyConst.appLockPinHash, 'abc');
      await storage.setString(AppStorageKeyConst.appLockPinSalt, 'salt');

      service = BackupService(
        database,
        BusinessRepository(database),
        storage,
        databaseFileProvider: () async => liveDb,
        generationsDirectoryProvider: () async => generations,
      );

      await service.eraseAllLocalData();

      expect(await liveDb.exists(), isFalse);
      expect(await File('${liveDb.path}-wal').exists(), isFalse);
      expect(await images.exists(), isFalse);
      expect(await assets.exists(), isFalse);
      expect(await attachments.exists(), isFalse);
      expect(await localZip.exists(), isFalse);
      expect(await sharedCopy.exists(), isTrue);
      expect(storage.getBool(AppStorageKeyConst.onboardingCompleted), isNull);
      expect(storage.getString(AppStorageKeyConst.appLockPinHash), isNull);
      expect(storage.getBool(AppStorageKeyConst.appLockEnabled), isNull);
    },
  );
}

Future<File> _backupFile(
  Directory directory, {
  required int schemaVersion,
  required List<int> databaseBytes,
  List<int>? settingsBytes,
  Map<String, List<int>> media = const {},
  Map<String, List<int>> purchaseAttachments = const {},
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
  for (final entry in purchaseAttachments.entries) {
    archive.addFile(
      ArchiveFile(
        'purchase_attachments/${entry.key}',
        entry.value.length,
        entry.value,
      ),
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

Future<File> _encryptedBackup(
  Directory directory, {
  required String password,
  required int schemaVersion,
  required List<int> databaseBytes,
  String? businessName,
}) async {
  final inner = await _backupFile(
    directory,
    schemaVersion: schemaVersion,
    databaseBytes: databaseBytes,
  );
  final payload = await const BackupCrypto().encrypt(
    await inner.readAsBytes(),
    password,
  );
  final outer = Archive()
    ..addFile(
      ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'format': 'creovo-invoice-backup',
          'version': 2,
          'encrypted': true,
          'schemaVersion': schemaVersion,
          'createdAt': '2026-08-26T10:00:00.000Z',
          'businessName': businessName,
          'invoiceCount': 3,
          'billCount': 1,
          'attachmentCount': 0,
        }),
      ),
    )
    ..addFile(ArchiveFile('payload.bin', payload.length, payload));
  final file = File('${directory.path}/encrypted_$schemaVersion.zip');
  await file.writeAsBytes(ZipEncoder().encode(outer), flush: true);
  return file;
}

List<int> _sqliteBytes(String content) => [
  ...utf8.encode('SQLite format 3\u0000'),
  ...utf8.encode(content),
  ...List<int>.filled(100, 0),
];
