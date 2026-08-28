import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/services/data_export_service.dart';

class DataExportController extends GetxController {
  DataExportController(this._service);

  final DataExportService _service;
  final from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final to = DateTime.now().obs;
  final busyExport = Rxn<DataExportType>();
  final isBuildingPdf = false.obs;

  void setFrom(DateTime value) => from.value = value;
  void setTo(DateTime value) => to.value = value;

  Future<void> exportCsv(DataExportType type, {required bool share}) async {
    if (!_validRange()) return;
    busyExport.value = type;
    try {
      final artifact = await _service.buildCsv(
        type,
        from: from.value,
        to: to.value,
      );
      if (share) {
        await _service.share(artifact);
      } else {
        final path = await _service.save(artifact);
        if (path != null) {
          AppNotification.success('Export saved', artifact.fileName);
        }
      }
    } catch (_) {
      AppNotification.error(
        'Export failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyExport.value = null;
    }
  }

  Future<void> exportReportPdf({required bool share}) async {
    if (!_validRange()) return;
    isBuildingPdf.value = true;
    try {
      final artifact = await _service.buildReportPdf(
        from: from.value,
        to: to.value,
      );
      if (share) {
        await _service.share(artifact);
      } else {
        final path = await _service.save(artifact);
        if (path != null) {
          AppNotification.success('Report saved', artifact.fileName);
        }
      }
    } catch (_) {
      AppNotification.error(
        'Report export failed',
        'The report could not be created. Please try again.',
      );
    } finally {
      isBuildingPdf.value = false;
    }
  }

  Future<void> exportAllZip({required bool share}) async {
    if (!_validRange()) return;
    busyExport.value = DataExportType.report;
    try {
      final artifact = await _service.buildAllCsvZip(
        from: from.value,
        to: to.value,
      );
      if (share) {
        await _service.share(artifact);
      } else {
        final path = await _service.save(artifact);
        if (path != null) {
          AppNotification.success('Export saved', artifact.fileName);
        }
      }
    } catch (_) {
      AppNotification.error(
        'Export failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyExport.value = null;
    }
  }

  bool _validRange() {
    if (!from.value.isAfter(to.value)) return true;
    AppNotification.warning(
      'Check date range',
      'The From date must be on or before the To date.',
    );
    return false;
  }
}
