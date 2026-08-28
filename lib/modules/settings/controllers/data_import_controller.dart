import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/models/data_import_models.dart';
import '../../../data/services/data_export_service.dart';
import '../../../data/services/data_import_service.dart';
import '../../../data/services/data_import_templates.dart';

class DataImportController extends GetxController {
  DataImportController(this._import, this._export);

  final DataImportService _import;
  final DataExportService _export;

  final kind = DataImportKind.customers.obs;
  final policy = DuplicateImportPolicy.skip.obs;
  final preview = Rxn<ImportPreview>();
  final lastResult = Rxn<ImportBatchResult>();
  final batches = <ImportBatchSummary>[].obs;
  final isBusy = false.obs;
  final mapping = <String, String>{}.obs;
  List<List<String>> _table = const [];
  String _fileName = '';

  ImportTemplate get template => DataImportTemplates.of(kind.value);

  @override
  void onInit() {
    super.onInit();
    refreshBatches();
  }

  void selectKind(DataImportKind value) {
    kind.value = value;
    preview.value = null;
    lastResult.value = null;
    mapping.clear();
  }

  Future<void> refreshBatches() async {
    batches.assignAll(await _import.recentBatches());
  }

  Future<void> downloadTemplate({required bool share}) async {
    final artifact = _import.templateArtifact(kind.value);
    if (share) {
      await _export.share(artifact);
    } else {
      final path = await _export.save(artifact);
      if (path != null) {
        AppNotification.success('Template saved', artifact.fileName);
      }
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt', 'xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    isBusy.value = true;
    try {
      _fileName = file.name;
      _table = _import.parseSpreadsheet(bytes: bytes, fileName: file.name);
      mapping.assignAll(_import.autoMap(template, _table.first));
      _rebuildPreview();
    } on FormatException catch (error) {
      AppNotification.error('Cannot read file', error.message);
    } catch (_) {
      AppNotification.error(
        'Cannot read file',
        'Use a CSV template or save the Excel sheet as CSV.',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void mapColumn(String key, String header) {
    mapping[key] = header;
    if (_table.isNotEmpty) _rebuildPreview();
  }

  void _rebuildPreview() {
    try {
      preview.value = _import.preview(
        kind: kind.value,
        sourceFileName: _fileName,
        table: _table,
        mapping: Map<String, String>.from(mapping),
      );
      lastResult.value = null;
    } on FormatException catch (error) {
      preview.value = null;
      AppNotification.warning('Check column mapping', error.message);
    }
  }

  Future<void> importRows() async {
    final current = preview.value;
    if (current == null) return;
    isBusy.value = true;
    try {
      lastResult.value = await _import.commit(
        preview: current,
        policy: policy.value,
      );
      await refreshBatches();
      AppNotification.success(
        'Import finished',
        '${lastResult.value!.importedCount} rows saved offline.',
      );
    } catch (_) {
      AppNotification.error(
        'Import failed',
        'Nothing was saved. Fix the file and try again.',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> shareErrors() async {
    final result = lastResult.value;
    if (result == null || result.errors.isEmpty) return;
    await _export.share(_import.errorArtifact(result));
  }

  Future<void> reverse(ImportBatchSummary batch) async {
    isBusy.value = true;
    try {
      await _import.reverseBatch(batch.id);
      await refreshBatches();
      AppNotification.success(
        'Import reversed',
        'Imported rows from ${batch.sourceFileName} were removed.',
      );
    } catch (_) {
      AppNotification.error(
        'Could not reverse',
        'Later edits or payments may be using these records.',
      );
    } finally {
      isBusy.value = false;
    }
  }
}
