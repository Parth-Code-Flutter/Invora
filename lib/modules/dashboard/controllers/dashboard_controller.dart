import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/report_summary_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/services/backup_service.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../invoices/controllers/invoice_list_controller.dart';

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
  final invoices = <InvoiceSummaryModel>[].obs;
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
          invoices.assignAll(values);
          recentInvoices.assignAll(values.take(5));
          recentLoading.value = false;
        }, onError: (_) => recentLoading.value = false);
  }

  void refreshBackupStatus() => backupDue.value = _backupService.isBackupDue;

  List<InvoiceSummaryModel> overdueInvoices([DateTime? now]) {
    final today = now ?? DateTime.now();
    final items = invoices
        .where(
          (invoice) => invoice.effectiveStatus(today) == InvoiceStatus.overdue,
        )
        .toList();
    items.sort((left, right) {
      final leftDue = left.dueDate ?? left.invoiceDate;
      final rightDue = right.dueDate ?? right.invoiceDate;
      return leftDue.compareTo(rightDue);
    });
    return items;
  }

  List<InvoiceSummaryModel> dueSoonInvoices([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final weekEnd = today.add(const Duration(days: 7));
    final items = invoices.where((invoice) {
      final status = invoice.effectiveStatus(current);
      if (invoice.balanceMinor <= 0) return false;
      if (status == InvoiceStatus.overdue ||
          status == InvoiceStatus.draft ||
          status == InvoiceStatus.cancelled ||
          status == InvoiceStatus.paid) {
        return false;
      }
      final due = invoice.dueDate;
      if (due == null) return false;
      final dueDay = DateTime(due.year, due.month, due.day);
      return !dueDay.isBefore(today) && dueDay.isBefore(weekEnd);
    }).toList();
    items.sort((left, right) => left.dueDate!.compareTo(right.dueDate!));
    return items;
  }

  List<InvoiceSummaryModel> followUpInvoices([DateTime? now]) =>
      [...overdueInvoices(now), ...dueSoonInvoices(now)].take(5).toList();

  int overdueAmount([DateTime? now]) => overdueInvoices(
    now,
  ).fold<int>(0, (sum, invoice) => sum + invoice.balanceMinor);

  int dueSoonAmount([DateTime? now]) => dueSoonInvoices(
    now,
  ).fold<int>(0, (sum, invoice) => sum + invoice.balanceMinor);

  void openInvoiceList([InvoiceListFilter filter = InvoiceListFilter.all]) {
    if (Get.isRegistered<InvoiceListController>()) {
      Get.find<InvoiceListController>().selectFilter(filter);
    }
    Get.offAllNamed<void>(AppRoutes.invoices, arguments: filter);
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
