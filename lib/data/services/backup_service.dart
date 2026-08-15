import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants/db_constants.dart';
import '../../app/constants/app_storage_key_const.dart';
import '../repositories/business_repository.dart';
import 'app_database.dart';
import 'app_storage.dart';

class BackupService {
  BackupService(
    this._database,
    this._business,
    this._storage, {
    Future<File> Function()? databaseFileProvider,
    Future<Directory> Function()? outputDirectoryProvider,
  }) : _databaseFileProvider = databaseFileProvider ?? appDatabaseFile,
       _outputDirectoryProvider =
           outputDirectoryProvider ?? getTemporaryDirectory;
  final AppDatabase _database;
  final BusinessRepository _business;
  final AppStorage _storage;
  final Future<File> Function() _databaseFileProvider;
  final Future<Directory> Function() _outputDirectoryProvider;

  DateTime? get lastBackupAt => DateTime.tryParse(
    _storage.getString(AppStorageKeyConst.lastBackupAt) ?? '',
  )?.toLocal();

  int get reminderDays =>
      _storage.getInt(AppStorageKeyConst.backupReminderDays) ?? 7;

  bool get isBackupDue {
    if (reminderDays <= 0) return false;
    final created = lastBackupAt;
    if (created == null) return true;
    return DateTime.now().difference(created).inDays >= reminderDays;
  }

  Future<void> setReminderDays(int days) async {
    if (![0, 7, 14, 30].contains(days)) {
      throw ArgumentError('Unsupported backup reminder interval.');
    }
    await _storage.setInt(AppStorageKeyConst.backupReminderDays, days);
  }

  Future<File> createBackup() async {
    // Flush WAL pages first so the copied SQLite file is self-contained.
    await _database.customStatement('PRAGMA wal_checkpoint(FULL)');
    final databaseFile = await _databaseFileProvider();
    final archive = Archive();
    final dbBytes = await databaseFile.readAsBytes();
    archive.addFile(
      ArchiveFile('data/creovo_invoice.sqlite', dbBytes.length, dbBytes),
    );

    final profile = await _business.getProfile();
    final media = <String, String?>{
      'logo': profile?.logoPath,
      'signature': profile?.signaturePath,
      'payment_qr': profile?.paymentQrPath,
    };
    for (final entry in media.entries) {
      final path = entry.value;
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(
          'media/${entry.key}${p.extension(path)}',
          bytes.length,
          bytes,
        ),
      );
    }
    final metadata = jsonEncode({
      'format': 'creovo-invoice-backup',
      'version': 1,
      'schemaVersion': DbConstants.schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    archive.addFile(ArchiveFile.string('metadata.json', metadata));
    final settings = jsonEncode({
      AppStorageKeyConst.isDarkMode: _storage.getBool(
        AppStorageKeyConst.isDarkMode,
      ),
      AppStorageKeyConst.onboardingCompleted: _storage.getBool(
        AppStorageKeyConst.onboardingCompleted,
      ),
      AppStorageKeyConst.businessSetupCompleted: _storage.getBool(
        AppStorageKeyConst.businessSetupCompleted,
      ),
      AppStorageKeyConst.defaultWorkspace: _storage.getString(
        AppStorageKeyConst.defaultWorkspace,
      ),
      AppStorageKeyConst.activeWorkspace: _storage.getString(
        AppStorageKeyConst.activeWorkspace,
      ),
      AppStorageKeyConst.selectedInvoiceTemplate: _storage.getString(
        AppStorageKeyConst.selectedInvoiceTemplate,
      ),
      AppStorageKeyConst.customUnits: _storage.getStringList(
        AppStorageKeyConst.customUnits,
      ),
      AppStorageKeyConst.managedUnits: _storage.getStringList(
        AppStorageKeyConst.managedUnits,
      ),
      AppStorageKeyConst.defaultUnit: _storage.getString(
        AppStorageKeyConst.defaultUnit,
      ),
      AppStorageKeyConst.defaultDueDays: _storage.getInt(
        AppStorageKeyConst.defaultDueDays,
      ),
      AppStorageKeyConst.defaultTaxType: _storage.getString(
        AppStorageKeyConst.defaultTaxType,
      ),
      AppStorageKeyConst.defaultGstRateBasisPoints: _storage.getInt(
        AppStorageKeyConst.defaultGstRateBasisPoints,
      ),
      AppStorageKeyConst.defaultInvoiceNotes: _storage.getString(
        AppStorageKeyConst.defaultInvoiceNotes,
      ),
      AppStorageKeyConst.defaultInvoiceTerms: _storage.getString(
        AppStorageKeyConst.defaultInvoiceTerms,
      ),
      AppStorageKeyConst.defaultPaymentMethod: _storage.getString(
        AppStorageKeyConst.defaultPaymentMethod,
      ),
      AppStorageKeyConst.businessCategory: _storage.getString(
        AppStorageKeyConst.businessCategory,
      ),
      AppStorageKeyConst.enabledProductFields: _storage.getStringList(
        AppStorageKeyConst.enabledProductFields,
      ),
      AppStorageKeyConst.customProductFields: _storage.getString(
        AppStorageKeyConst.customProductFields,
      ),
      AppStorageKeyConst.preferredUnits: _storage.getStringList(
        AppStorageKeyConst.preferredUnits,
      ),
      AppStorageKeyConst.showProductAttributesOnInvoice: _storage.getBool(
        AppStorageKeyConst.showProductAttributesOnInvoice,
      ),
      AppStorageKeyConst.backupReminderDays: _storage.getInt(
        AppStorageKeyConst.backupReminderDays,
      ),
    });
    archive.addFile(ArchiveFile.string('settings.json', settings));
    final bytes = ZipEncoder().encode(archive);
    final now = DateTime.now();
    final name =
        'creovo_billing_backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.zip';
    final directory = await _outputDirectoryProvider();
    final output = File(p.join(directory.path, name));
    await output.writeAsBytes(bytes, flush: true);
    await _storage.setString(
      AppStorageKeyConst.lastBackupAt,
      now.toUtc().toIso8601String(),
    );
    return output;
  }

  Future<void> shareBackup(File backup) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backup.path)],
        subject: 'Creovo Billing backup',
      ),
    );
  }

  Future<File?> pickBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  Future<BackupValidation> validate(File file) async {
    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      final metadataFile = archive.findFile('metadata.json');
      final databaseFile =
          archive.findFile('data/creovo_invoice.sqlite') ??
          archive.findFile('data/invora.sqlite');
      if (metadataFile == null || databaseFile == null) {
        return const BackupValidation.invalid(
          'Required backup files are missing.',
        );
      }
      final metadata =
          jsonDecode(utf8.decode(metadataFile.content as List<int>))
              as Map<String, dynamic>;
      final format = metadata['format'];
      final supportedFormat =
          format == 'creovo-invoice-backup' || format == 'invora-backup';
      if (!supportedFormat || metadata['version'] != 1) {
        return const BackupValidation.invalid('Unsupported backup format.');
      }
      final schema = metadata['schemaVersion'] as int? ?? 0;
      final databaseBytes = databaseFile.content as List<int>;
      if (!_looksLikeSqlite(databaseBytes)) {
        return const BackupValidation.invalid(
          'The backup database is damaged or unreadable.',
        );
      }
      if (schema <= 0) {
        return const BackupValidation.invalid(
          'The backup database version is missing or invalid.',
        );
      }
      if (schema > DbConstants.schemaVersion) {
        return const BackupValidation.invalid(
          'This backup was created by a newer Creovo Billing version.',
        );
      }
      return BackupValidation.valid(archive);
    } catch (_) {
      return const BackupValidation.invalid(
        'The backup is damaged or unreadable.',
      );
    }
  }

  bool _looksLikeSqlite(List<int> bytes) {
    const signature = <int>[
      0x53,
      0x51,
      0x4c,
      0x69,
      0x74,
      0x65,
      0x20,
      0x66,
      0x6f,
      0x72,
      0x6d,
      0x61,
      0x74,
      0x20,
      0x33,
      0x00,
    ];
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  Future<BackupRestoreResult> restore(File file) async {
    final validation = await validate(file);
    if (!validation.isValid) throw StateError(validation.message);
    final archive = validation.archive!;
    final databaseEntry =
        archive.findFile('data/creovo_invoice.sqlite') ??
        archive.findFile('data/invora.sqlite')!;
    final target = await _databaseFileProvider();
    final rollback = File('${target.path}.before_restore');
    if (await target.exists()) await target.copy(rollback.path);
    try {
      await _database.close();
      await target.writeAsBytes(
        databaseEntry.content as List<int>,
        flush: true,
      );
      final mediaPaths = await _restoreMedia(archive, target.parent);
      await _restoreSettings(archive);
      await _storage.setBool(AppStorageKeyConst.restoreCompleted, true);
      return BackupRestoreResult(mediaPaths);
    } catch (_) {
      if (await rollback.exists()) await rollback.copy(target.path);
      rethrow;
    } finally {
      if (await rollback.exists()) await rollback.delete();
    }
  }

  Future<Map<String, String?>> _restoreMedia(
    Archive archive,
    Directory support,
  ) async {
    final restored = <String, String?>{
      'logo': null,
      'signature': null,
      'payment_qr': null,
    };
    final assets = Directory(p.join(support.path, 'business_assets'));
    await assets.create(recursive: true);
    for (final file in archive.files.where(
      (entry) => entry.isFile && entry.name.startsWith('media/'),
    )) {
      final key = p.basenameWithoutExtension(file.name);
      if (!restored.containsKey(key)) continue;
      final extension = p.extension(file.name).toLowerCase();
      final output = File(
        p.join(
          assets.path,
          'restored_$key${extension.isEmpty ? '.jpg' : extension}',
        ),
      );
      await output.writeAsBytes(file.content as List<int>, flush: true);
      restored[key] = output.path;
    }
    return restored;
  }

  Future<void> _restoreSettings(Archive archive) async {
    final file = archive.findFile('settings.json');
    if (file == null) return;
    final values =
        jsonDecode(utf8.decode(file.content as List<int>))
            as Map<String, dynamic>;
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is bool) await _storage.setBool(entry.key, value);
      if (value is int) await _storage.setInt(entry.key, value);
      if (value is String) await _storage.setString(entry.key, value);
      if (value is List) {
        await _storage.setStringList(
          entry.key,
          value.whereType<String>().toList(),
        );
      }
    }
  }
}

class BackupRestoreResult {
  const BackupRestoreResult(this.mediaPaths);

  final Map<String, String?> mediaPaths;
}

class BackupValidation {
  const BackupValidation.valid(this.archive) : isValid = true, message = '';
  const BackupValidation.invalid(this.message)
    : isValid = false,
      archive = null;
  final bool isValid;
  final String message;
  final Archive? archive;
}
