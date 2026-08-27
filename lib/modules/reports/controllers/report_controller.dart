import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/gst_export_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/report_summary_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../widgets/report_charts.dart';

class ReportController extends GetxController {
  ReportController(this._invoices, this._business);
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final report = const ReportSummaryModel().obs;
  final currencySymbol = '₹'.obs;
  final preset = GstExportPeriodPreset.thisMonth.obs;
  final from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final to = DateTime.now().obs;
  final chartStyle = ReportChartStyle.trend.obs;
  final highlightIndex = 0.obs;
  StreamSubscription<ReportSummaryModel>? _subscription;
  int _watchId = 0;

  @override
  void onInit() {
    super.onInit();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    applyPreset(GstExportPeriodPreset.thisMonth);
  }

  bool get isMonthPreset =>
      preset.value == GstExportPeriodPreset.thisMonth ||
      preset.value == GstExportPeriodPreset.lastMonth;

  void applyPreset(GstExportPeriodPreset value) {
    final period = GstExportPeriod.fromPreset(
      value,
      customFrom: from.value,
      customTo: to.value,
    );
    preset.value = value;
    from.value = period.from;
    to.value = period.to;
    _watch();
  }

  void setFrom(DateTime value) {
    from.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    if (from.value.isAfter(to.value)) to.value = from.value;
    _watch();
  }

  void setTo(DateTime value) {
    to.value = GstExportPeriod.dateOnly(value);
    preset.value = GstExportPeriodPreset.custom;
    if (to.value.isBefore(from.value)) from.value = to.value;
    _watch();
  }

  void selectChartStyle(ReportChartStyle value) => chartStyle.value = value;

  void selectPoint(int index) => highlightIndex.value = index;

  void openPaid() => _openInvoices(InvoiceListFilter.paid);

  void openPending() => _openInvoices(InvoiceListFilter.unpaid);

  void openAgeing() => Get.toNamed<void>(AppRoutes.ageing);

  void openGst() => Get.toNamed<void>(AppRoutes.gstExport);

  void openExport() => Get.toNamed<void>(AppRoutes.dataExport);

  DateTime _shift(DateTime value, {required int years, required int months}) {
    final target = DateTime(value.year + years, value.month + months, 1);
    final last = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, value.day.clamp(1, last));
  }

  void _watch() {
    final id = ++_watchId;
    highlightIndex.value = -1;
    final yearShift =
        preset.value == GstExportPeriodPreset.thisFy ||
            preset.value == GstExportPeriodPreset.lastFy
        ? 1
        : 0;
    final monthShift = yearShift == 1 ? 0 : 1;
    _subscription?.cancel();
    _subscription = _invoices
        .watchPeriodReport(
          from: from.value,
          to: to.value,
          previousFrom: _shift(
            from.value,
            years: -yearShift,
            months: -monthShift,
          ),
          previousTo: _shift(to.value, years: -yearShift, months: -monthShift),
        )
        .listen((value) {
          if (id != _watchId) return;
          report.value = value;
          if (highlightIndex.value < 0 ||
              highlightIndex.value >= value.monthlySales.length) {
            highlightIndex.value = value.monthlySales.isEmpty
                ? 0
                : value.monthlySales.length - 1;
          }
        });
  }

  void _openInvoices(InvoiceListFilter filter) {
    Get.toNamed<void>(AppRoutes.invoices, arguments: filter);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
