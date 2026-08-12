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
  BackupService(this._database, this._business, this._storage);
  final AppDatabase _database;
  final BusinessRepository _business;
  final AppStorage _storage;

  Future<File> createBackup() async {
    // Flush WAL pages first so the copied SQLite file is self-contained.
    await _database.customStatement('PRAGMA wal_checkpoint(FULL)');
    final databaseFile = await appDatabaseFile();
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
    });
    archive.addFile(ArchiveFile.string('settings.json', settings));
    final bytes = ZipEncoder().encode(archive);
    final now = DateTime.now();
    final name =
        'creovo_invoice_backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.zip';
    final directory = await getTemporaryDirectory();
    final output = File(p.join(directory.path, name));
    await output.writeAsBytes(bytes, flush: true);
    return output;
  }

  Future<void> shareBackup(File backup) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backup.path)],
        subject: 'Creovo Invoice backup',
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
          'This backup was created by a newer Creovo Invoice version.',
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

  Future<void> restore(File file) async {
    final validation = await validate(file);
    if (!validation.isValid) throw StateError(validation.message);
    final archive = validation.archive!;
    final databaseEntry =
        archive.findFile('data/creovo_invoice.sqlite') ??
        archive.findFile('data/invora.sqlite')!;
    final target = await appDatabaseFile();
    final rollback = File('${target.path}.before_restore');
    if (await target.exists()) await target.copy(rollback.path);
    try {
      await _database.close();
      await target.writeAsBytes(
        databaseEntry.content as List<int>,
        flush: true,
      );
      await _restoreMedia(archive, target.parent);
      await _restoreSettings(archive);
      await _storage.setBool('restore_completed', true);
    } catch (_) {
      if (await rollback.exists()) await rollback.copy(target.path);
      rethrow;
    } finally {
      if (await rollback.exists()) await rollback.delete();
    }
  }

  Future<void> _restoreMedia(Archive archive, Directory support) async {
    for (final file in archive.files.where(
      (entry) => entry.isFile && entry.name.startsWith('media/'),
    )) {
      final output = File(p.join(support.path, p.basename(file.name)));
      await output.writeAsBytes(file.content as List<int>, flush: true);
    }
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

class BackupValidation {
  const BackupValidation.valid(this.archive) : isValid = true, message = '';
  const BackupValidation.invalid(this.message)
    : isValid = false,
      archive = null;
  final bool isValid;
  final String message;
  final Archive? archive;
}
