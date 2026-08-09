import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/report_summary_model.dart';
import '../../../data/models/invoice_model.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository, this._invoiceRepository);

  final BusinessRepository _repository;
  final InvoiceRepository _invoiceRepository;
  final profile = Rxn<BusinessProfileModel>();
  final report = const ReportSummaryModel().obs;
  final recentInvoices = <InvoiceSummaryModel>[].obs;
  StreamSubscription<ReportSummaryModel>? _reportSubscription;
  StreamSubscription<List<InvoiceSummaryModel>>? _recentSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
    _reportSubscription = _invoiceRepository.watchCurrentMonthReport().listen(
      (value) => report.value = value,
    );
    _recentSubscription = _invoiceRepository
        .watchSummaries(sort: InvoiceSort.newest)
        .listen((values) => recentInvoices.assignAll(values.take(5)));
  }

  Future<void> _loadProfile() async {
    profile.value = await _repository.getProfile();
  }

  @override
  void onClose() {
    _reportSubscription?.cancel();
    _recentSubscription?.cancel();
    super.onClose();
  }
}
