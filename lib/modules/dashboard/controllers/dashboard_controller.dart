import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/report_summary_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/services/backup_service.dart';

class DashboardController extends GetxController {
  DashboardController(
    this._repository,
    this._invoiceRepository,
    this._backupService,
  );

  final BusinessRepository _repository;
  final InvoiceRepository _invoiceRepository;
  final BackupService _backupService;
  final profile = Rxn<BusinessProfileModel>();
  final report = const ReportSummaryModel().obs;
  final recentInvoices = <InvoiceSummaryModel>[].obs;
  final backupDue = false.obs;
  final reportLoading = true.obs;
  final recentLoading = true.obs;
  StreamSubscription<ReportSummaryModel>? _reportSubscription;
  StreamSubscription<List<InvoiceSummaryModel>>? _recentSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
    refreshBackupStatus();
    _reportSubscription = _invoiceRepository.watchCurrentMonthReport().listen((
      value,
    ) {
      report.value = value;
      reportLoading.value = false;
    }, onError: (_) => reportLoading.value = false);
    _recentSubscription = _invoiceRepository
        .watchSummaries(sort: InvoiceSort.newest)
        .listen((values) {
          recentInvoices.assignAll(values.take(5));
          recentLoading.value = false;
        }, onError: (_) => recentLoading.value = false);
  }

  void refreshBackupStatus() => backupDue.value = _backupService.isBackupDue;

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
