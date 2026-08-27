import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/gst_export_model.dart';
import '../../../data/services/data_export_service.dart';
import '../../../data/services/gst_export_service.dart';

class GstExportController extends GetxController {
  GstExportController(this._service);

  final GstExportService _service;
  final preset = GstExportPeriodPreset.thisMonth.obs;
  final from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final to = DateTime.now().obs;
  final pack = Rxn<GstExportPack>();
  final isLoading = false.obs;
  final busyKey = RxnString();
  final registerTab = GstExportPreviewTab.sales.obs;
  final pdfBytes = Rxn<Uint8List>();
  int _loadId = 0;

  @override
  void onInit() {
    super.onInit();
    applyPreset(GstExportPeriodPreset.thisMonth);
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
    reload();
  }

  void setFrom(DateTime value) {
    from.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    reload();
  }

  void setTo(DateTime value) {
    to.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    reload();
  }

  void selectRegister(GstExportPreviewTab tab) => registerTab.value = tab;

  Future<void> reload() async {
    if (from.value.isAfter(to.value)) {
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
      final next = await _service.build(
        GstExportPeriod(from: from.value, to: to.value, preset: preset.value),
      );
      if (id != _loadId) return;
      pack.value = next;
    } catch (_) {
      if (id != _loadId) return;
      AppNotification.error(
        'GST export failed',
        'The registers could not be prepared. Please try again.',
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
      throw StateError('GST pack is not ready.');
    }
    final artifact = await _service.buildPdf(current);
    pdfBytes.value = artifact.bytes;
    return artifact.bytes;
  }

  Future<void> exportPack({required bool share}) async {
    await _run('pack', share, (current) => _service.buildZip(current));
  }

  Future<void> exportVisibleRegister({required bool share}) async {
    await exportCsv(_kindForTab(registerTab.value), share: share);
  }

  Future<void> printPdf() async {
    final current = pack.value;
    if (current == null || busyKey.value != null) return;
    busyKey.value = 'print';
    try {
      await _service.printPdf(await _service.buildPdf(current));
    } catch (_) {
      AppNotification.error(
        'GST export failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }

  Future<void> exportCsv(GstExportKind kind, {required bool share}) async {
    await _run(kind.name, share, (current) => _service.buildCsv(kind, current));
  }

  Future<void> openSource(GstExportSource source, int? id) async {
    if (id == null) return;
    final route = switch (source) {
      GstExportSource.invoice => AppRoutes.invoiceDetails,
      GstExportSource.creditNote => AppRoutes.creditNoteDetails,
      GstExportSource.purchase => AppRoutes.purchaseBillDetails,
    };
    await Get.toNamed<void>(route, arguments: id);
    await reload();
  }

  Future<void> _run(
    String key,
    bool share,
    Future<ExportArtifact> Function(GstExportPack pack) build,
  ) async {
    final current = pack.value;
    if (current == null || busyKey.value != null) return;
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
        'GST export failed',
        'The file could not be created. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }

  GstExportKind _kindForTab(GstExportPreviewTab tab) => switch (tab) {
    GstExportPreviewTab.sales => GstExportKind.sales,
    GstExportPreviewTab.creditNotes => GstExportKind.creditNotes,
    GstExportPreviewTab.purchases => GstExportKind.purchases,
    GstExportPreviewTab.hsn => GstExportKind.hsn,
    GstExportPreviewTab.exceptions => GstExportKind.exceptions,
  };
}
