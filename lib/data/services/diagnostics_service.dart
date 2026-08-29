import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants/app_constants.dart';
import '../../app/constants/app_storage_key_const.dart';
import '../../app/constants/db_constants.dart';
import 'app_database.dart';
import 'app_storage.dart';

class DiagnosticsReport {
  const DiagnosticsReport({
    required this.generatedAt,
    required this.appVersion,
    required this.buildNumber,
    required this.schemaVersion,
    required this.platform,
    required this.osVersion,
    required this.appLockEnabled,
    required this.lastBackupAt,
    required this.counts,
  });

  final DateTime generatedAt;
  final String appVersion;
  final String buildNumber;
  final int schemaVersion;
  final String platform;
  final String osVersion;
  final bool appLockEnabled;
  final DateTime? lastBackupAt;
  final Map<String, int> counts;

  String get fileName =>
      'Creovo_diagnostics_${generatedAt.toIso8601String().replaceAll(':', '-')}.txt';

  String toShareText() {
    final buffer = StringBuffer()
      ..writeln('${AppConstants.appName} diagnostics')
      ..writeln('Generated ${generatedAt.toIso8601String()}')
      ..writeln()
      ..writeln(
        'This file contains versions and record counts only. It is not a backup and does not include names, GSTIN, amounts, invoices, or passwords.',
      )
      ..writeln()
      ..writeln('App')
      ..writeln('- Version: $appVersion ($buildNumber)')
      ..writeln('- Schema: $schemaVersion')
      ..writeln('- Platform: $platform')
      ..writeln('- OS: $osVersion')
      ..writeln('- App lock: ${appLockEnabled ? 'On' : 'Off'}')
      ..writeln('- Last backup: ${lastBackupAt?.toIso8601String() ?? 'Never'}')
      ..writeln()
      ..writeln('Counts');
    for (final entry in counts.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}

class DiagnosticsService {
  const DiagnosticsService(this._database, this._storage);

  final AppDatabase _database;
  final AppStorage _storage;

  Future<DiagnosticsReport> collect({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String osVersion,
    required bool appLockEnabled,
    DateTime? generatedAt,
  }) async {
    return DiagnosticsReport(
      generatedAt: generatedAt ?? DateTime.now(),
      appVersion: appVersion,
      buildNumber: buildNumber,
      schemaVersion: DbConstants.schemaVersion,
      platform: platform,
      osVersion: osVersion,
      appLockEnabled: appLockEnabled,
      lastBackupAt: DateTime.tryParse(
        _storage.getString(AppStorageKeyConst.lastBackupAt) ?? '',
      ),
      counts: {
        'Customers': await _count('customers'),
        'Products and services': await _count('product_services'),
        'Invoices': await _count(
          'invoices',
          where: "document_type = 'invoice'",
        ),
        'Quotations': await _count(
          'invoices',
          where: "document_type = 'quotation'",
        ),
        'Suppliers': await _count('suppliers'),
        'Purchase bills': await _count('purchase_bills'),
        'Purchase orders': await _count('purchase_orders'),
        'Delivery challans': await _count('delivery_challans'),
        'Expenses': await _count('expenses'),
        'Stock movements': await _count('stock_movements'),
      },
    );
  }

  Future<void> share(DiagnosticsReport report) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, report.fileName),
    );
    await file.writeAsString(report.toShareText(), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: report.fileName),
    );
  }

  Future<String?> save(DiagnosticsReport report) async {
    final bytes = Uint8List.fromList(utf8.encode(report.toShareText()));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save diagnostics',
      fileName: report.fileName,
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      bytes: bytes,
    );
    if (path != null && !await File(path).exists()) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  Future<int> _count(String table, {String? where}) async {
    try {
      final sql = where == null
          ? 'SELECT COUNT(*) AS c FROM $table'
          : 'SELECT COUNT(*) AS c FROM $table WHERE $where';
      final row = await _database.customSelect(sql).getSingle();
      return row.read<int>('c');
    } catch (_) {
      return 0;
    }
  }
}
