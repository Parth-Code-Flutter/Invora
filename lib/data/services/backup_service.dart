import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../app/constants/db_constants.dart';
import '../../app/constants/app_storage_key_const.dart';
import '../repositories/business_repository.dart';
import 'app_database.dart';
import 'app_storage.dart';
import 'backup_crypto.dart';

class BackupService {
  BackupService(
    this._database,
    this._business,
    this._storage, {
    Future<File> Function()? databaseFileProvider,
    Future<Directory> Function()? outputDirectoryProvider,
    this._generationsDirectoryProvider,
    this._crypto = const BackupCrypto(),
  }) : _databaseFileProvider = databaseFileProvider ?? appDatabaseFile,
       _outputDirectoryProvider =
           outputDirectoryProvider ?? getTemporaryDirectory;
  final AppDatabase _database;
  final BusinessRepository _business;
  final AppStorage _storage;
  final Future<File> Function() _databaseFileProvider;
  final Future<Directory> Function() _outputDirectoryProvider;
  final Future<Directory> Function()? _generationsDirectoryProvider;
  final BackupCrypto _crypto;

  static const maxLocalGenerations = 5;
  static const minPasswordLength = 8;

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

  Future<File> createBackup({required String password}) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError(
        'Backup password must be at least $minPasswordLength characters.',
      );
    }
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
    var attachmentCount = 0;
    for (final entry in media.entries) {
      final path = entry.value;
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      attachmentCount++;
      archive.addFile(
        ArchiveFile(
          'media/${entry.key}${p.extension(path)}',
          bytes.length,
          bytes,
        ),
      );
    }
    final support = databaseFile.parent;
    final purchaseAttachments = Directory(
      p.join(support.path, 'purchase_attachments'),
    );
    if (await purchaseAttachments.exists()) {
      await for (final entity in purchaseAttachments.list()) {
        if (entity is! File) continue;
        final bytes = await entity.readAsBytes();
        attachmentCount++;
        archive.addFile(
          ArchiveFile(
            'purchase_attachments/${p.basename(entity.path)}',
            bytes.length,
            bytes,
          ),
        );
      }
    }
    final createdAt = DateTime.now().toUtc();
    final metadata = jsonEncode({
      'format': 'creovo-invoice-backup',
      'version': 1,
      'schemaVersion': DbConstants.schemaVersion,
      'createdAt': createdAt.toIso8601String(),
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
    final innerBytes = ZipEncoder().encode(archive);
    final payload = await _crypto.encrypt(innerBytes, password);
    final invoiceCount = await _countTable('invoices');
    final billCount = await _countTable('purchase_bills');
    String appVersion = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    final manifest = jsonEncode({
      'format': 'creovo-invoice-backup',
      'version': 2,
      'encrypted': true,
      'kdf': BackupCrypto.kdfName,
      'cipher': BackupCrypto.cipherName,
      'iterations': BackupCrypto.iterations,
      'schemaVersion': DbConstants.schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'appVersion': appVersion,
      'businessName': profile?.businessName,
      'invoiceCount': invoiceCount,
      'billCount': billCount,
      'attachmentCount': attachmentCount,
    });
    final outer = Archive()
      ..addFile(ArchiveFile.string('manifest.json', manifest))
      ..addFile(ArchiveFile('payload.bin', payload.length, payload));
    final bytes = ZipEncoder().encode(outer);
    final now = createdAt.toLocal();
    final stamp =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}_${now.millisecond.toString().padLeft(3, '0')}';
    final name = 'creovo_billing_backup_$stamp.zip';
    final generations = await _generationsDirectory();
    final output = File(p.join(generations.path, name));
    await output.writeAsBytes(bytes, flush: true);
    await _pruneGenerations(generations);
    final shareCopy = File(
      p.join((await _outputDirectoryProvider()).path, name),
    );
    if (shareCopy.path != output.path) {
      await shareCopy.writeAsBytes(bytes, flush: true);
    }
    await _storage.setString(
      AppStorageKeyConst.lastBackupAt,
      createdAt.toIso8601String(),
    );
    return shareCopy.path == output.path ? output : shareCopy;
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
      allowedExtensions: const ['zip', 'creovo'],
    );
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  Future<BackupValidation> validate(File file, {String? password}) async {
    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      final payloadFile = archive.findFile('payload.bin');
      final manifestFile = archive.findFile('manifest.json');
      if (payloadFile != null && manifestFile != null) {
        return _validateEncrypted(archive, password);
      }
      return _validateLegacy(archive);
    } on BackupPasswordException catch (error) {
      return BackupValidation.invalid(error.message);
    } catch (_) {
      return const BackupValidation.invalid(
        'The backup is damaged or unreadable.',
      );
    }
  }

  Future<BackupValidation> _validateEncrypted(
    Archive outer,
    String? password,
  ) async {
    final manifestFile = outer.findFile('manifest.json')!;
    final payloadFile = outer.findFile('payload.bin')!;
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    if (manifest['format'] != 'creovo-invoice-backup' ||
        manifest['version'] != 2) {
      return const BackupValidation.invalid('Unsupported backup format.');
    }
    final preview = BackupPreview.fromManifest(manifest, encrypted: true);
    if (password == null || password.isEmpty) {
      return BackupValidation.invalid(
        'This backup is password protected.',
        preview: preview,
      );
    }
    try {
      final innerBytes = await _crypto.decrypt(
        payloadFile.content as List<int>,
        password,
      );
      final inner = ZipDecoder().decodeBytes(innerBytes);
      final innerValidation = _validateInnerArchive(inner);
      if (!innerValidation.isValid) return innerValidation;
      return BackupValidation.valid(inner, preview: preview);
    } on BackupPasswordException catch (error) {
      return BackupValidation.invalid(error.message, preview: preview);
    }
  }

  BackupValidation _validateLegacy(Archive archive) {
    return _validateInnerArchive(archive, legacy: true);
  }

  BackupValidation _validateInnerArchive(
    Archive archive, {
    bool legacy = false,
  }) {
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
    final preview = BackupPreview(
      encrypted: false,
      legacy: legacy,
      schemaVersion: schema,
      createdAt: DateTime.tryParse('${metadata['createdAt'] ?? ''}'),
    );
    return BackupValidation.valid(archive, preview: preview);
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

  Future<BackupRestoreResult> restore(File file, {String? password}) async {
    final validation = await validate(file, password: password);
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
      await _restorePurchaseAttachments(archive, target.parent);
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

  Future<void> _restorePurchaseAttachments(
    Archive archive,
    Directory support,
  ) async {
    final folder = Directory(p.join(support.path, 'purchase_attachments'));
    await folder.create(recursive: true);
    for (final file in archive.files.where(
      (entry) => entry.isFile && entry.name.startsWith('purchase_attachments/'),
    )) {
      final name = p.basename(file.name);
      if (name.isEmpty) continue;
      await File(
        p.join(folder.path, name),
      ).writeAsBytes(file.content as List<int>, flush: true);
    }
  }

  Future<bool> isEncryptedBackup(File file) async {
    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      return archive.findFile('payload.bin') != null &&
          archive.findFile('manifest.json') != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<File>> listLocalGenerations() async {
    final directory = await _generationsDirectory();
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.zip'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    return files;
  }

  Future<Directory> _generationsDirectory() async {
    final provider = _generationsDirectoryProvider;
    if (provider != null) {
      final directory = await provider();
      await directory.create(recursive: true);
      return directory;
    }
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(docs.path, 'creovo_backups'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _pruneGenerations(Directory directory) async {
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.zip'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    for (final extra in files.skip(maxLocalGenerations)) {
      if (await extra.exists()) await extra.delete();
    }
  }

  Future<int> _countTable(String table) async {
    try {
      final row = await _database
          .customSelect('SELECT COUNT(*) AS c FROM $table')
          .getSingle();
      return row.read<int>('c');
    } catch (_) {
      return 0;
    }
  }
}

class BackupRestoreResult {
  const BackupRestoreResult(this.mediaPaths);

  final Map<String, String?> mediaPaths;
}

class RestoreBackupRequest {
  const RestoreBackupRequest({required this.path, this.password});

  final String path;
  final String? password;
}

class BackupPreview {
  const BackupPreview({
    required this.encrypted,
    this.legacy = false,
    this.businessName,
    this.createdAt,
    this.schemaVersion,
    this.appVersion,
    this.invoiceCount,
    this.billCount,
    this.attachmentCount,
  });

  factory BackupPreview.fromManifest(
    Map<String, dynamic> manifest, {
    required bool encrypted,
  }) {
    return BackupPreview(
      encrypted: encrypted,
      businessName: manifest['businessName'] as String?,
      createdAt: DateTime.tryParse('${manifest['createdAt'] ?? ''}'),
      schemaVersion: manifest['schemaVersion'] as int?,
      appVersion: manifest['appVersion'] as String?,
      invoiceCount: manifest['invoiceCount'] as int?,
      billCount: manifest['billCount'] as int?,
      attachmentCount: manifest['attachmentCount'] as int?,
    );
  }

  final bool encrypted;
  final bool legacy;
  final String? businessName;
  final DateTime? createdAt;
  final int? schemaVersion;
  final String? appVersion;
  final int? invoiceCount;
  final int? billCount;
  final int? attachmentCount;
}

class BackupValidation {
  const BackupValidation.valid(this.archive, {this.preview})
    : isValid = true,
      message = '';
  const BackupValidation.invalid(this.message, {this.preview})
    : isValid = false,
      archive = null;
  final bool isValid;
  final String message;
  final Archive? archive;
  final BackupPreview? preview;
}
