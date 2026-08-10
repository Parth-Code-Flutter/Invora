import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/report_summary_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

class ReportController extends GetxController {
  ReportController(this._invoices, this._business);
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final report = const ReportSummaryModel().obs;
  final currencySymbol = '₹'.obs;
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  StreamSubscription<ReportSummaryModel>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    _watchMonth();
  }

  bool get canMoveNext {
    final now = DateTime.now();
    return selectedMonth.value.isBefore(DateTime(now.year, now.month));
  }

  void previousMonth() => selectMonth(
    DateTime(selectedMonth.value.year, selectedMonth.value.month - 1),
  );

  void nextMonth() {
    if (!canMoveNext) return;
    selectMonth(
      DateTime(selectedMonth.value.year, selectedMonth.value.month + 1),
    );
  }

  void selectMonth(DateTime value) {
    selectedMonth.value = DateTime(value.year, value.month);
    _watchMonth();
  }

  void _watchMonth() {
    _subscription?.cancel();
    _subscription = _invoices
        .watchMonthlyReport(selectedMonth.value)
        .listen((value) => report.value = value);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
