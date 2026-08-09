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
  StreamSubscription<ReportSummaryModel>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    _subscription = _invoices.watchCurrentMonthReport().listen(
      (value) => report.value = value,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
