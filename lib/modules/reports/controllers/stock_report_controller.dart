import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/gst_export_model.dart';
import '../../../data/models/stock_report_model.dart';
import '../../../data/services/data_export_service.dart';
import '../../../data/services/stock_report_service.dart';

class StockReportController extends GetxController {
  StockReportController(this._service);

  final StockReportService _service;
  final kind = StockReportKind.onHand.obs;
  final asOf = GstExportPeriod.dateOnly(DateTime.now()).obs;
  final preset = GstExportPeriodPreset.thisMonth.obs;
  final from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final to = DateTime.now().obs;
  final pack = Rxn<StockReportPack>();
  final isLoading = false.obs;
  final busyKey = RxnString();
  final pdfBytes = Rxn<Uint8List>();
  int _loadId = 0;

  @override
  void onInit() {
    super.onInit();
    final period = GstExportPeriod.fromPreset(GstExportPeriodPreset.thisMonth);
    preset.value = period.preset;
    from.value = period.from;
    to.value = period.to;
    reload();
  }

  void selectKind(StockReportKind value) {
    if (kind.value == value) return;
    kind.value = value;
    reload();
  }

  void setAsOf(DateTime value) {
    asOf.value = GstExportPeriod.dateOnly(value);
    reload();
  }

  void applyPreset(GstExportPeriodPreset value) {
    final period = GstExportPeriod.fromPreset(
      value,
      customFrom: from.value,
      customTo: to.value,
    );
    preset.value = value;
    from.value = period.from;
    to.value = period.to;
    if (kind.value == StockReportKind.movements) reload();
  }

  void setFrom(DateTime value) {
    from.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    if (from.value.isAfter(to.value)) to.value = from.value;
    reload();
  }

  void setTo(DateTime value) {
    to.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    if (to.value.isBefore(from.value)) from.value = to.value;
    reload();
  }

  Future<void> reload() async {
    if (kind.value == StockReportKind.movements &&
        from.value.isAfter(to.value)) {
      AppNotification.warning(
        'Check date range',
        'The From date must be on or before the To date.',
      );
      return;
    }
    final id = ++_loadId;
    isLoading.value = true;
    pdfBytes.value = null;
    try {
      final next = kind.value == StockReportKind.onHand
          ? await _service.buildOnHand(asOf.value)
          : await _service.buildMovements(
              GstExportPeriod(
                from: from.value,
                to: to.value,
                preset: preset.value,
              ),
            );
      if (id != _loadId) return;
      pack.value = next;
    } catch (_) {
      if (id != _loadId) return;
      AppNotification.error(
        'Stock report failed',
        'The stock report could not be prepared. Please try again.',
      );
    } finally {
      if (id == _loadId) isLoading.value = false;
    }
  }

  Future<Uint8List> buildPdf() async {
    final cached = pdfBytes.value;
    if (cached != null) return cached;
    final current = pack.value;
    if (current == null) {
      throw StateError('Stock report is not ready.');
    }
    final artifact = await _service.buildPdf(current);
    pdfBytes.value = artifact.bytes;
    return artifact.bytes;
  }

  Future<void> exportCsv({required bool share}) async {
    await _run('csv', share, _service.buildCsv);
  }

  Future<void> exportPdf({required bool share}) async {
    await _run('pdf', share, _service.buildPdf);
  }

  Future<void> printPdf() async {
    final current = pack.value;
    if (current == null || !current.enabled || busyKey.value != null) {
      return;
    }
    busyKey.value = 'print';
    try {
      await _service.printPdf(await _service.buildPdf(current));
    } catch (_) {
      AppNotification.error(
        'Stock report failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }

  void openAddProduct() => Get.toNamed<void>(AppRoutes.productAdd);

  Future<void> _run(
    String key,
    bool share,
    Future<ExportArtifact> Function(StockReportPack pack) build,
  ) async {
    final current = pack.value;
    if (current == null || !current.enabled || busyKey.value != null) {
      return;
    }
    busyKey.value = key;
    try {
      final artifact = await build(current);
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
        'Stock report failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }
}
