import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

class InvoiceListController extends GetxController {
  InvoiceListController(
    this._repository,
    this._businessRepository, {
    this.documentType = DocumentType.invoice,
  });

  final InvoiceRepository _repository;
  final BusinessRepository _businessRepository;
  final DocumentType documentType;
  final invoices = <InvoiceSummaryModel>[].obs;
  final searchQuery = ''.obs;
  final selectedFilter = InvoiceListFilter.all.obs;
  final selectedSort = InvoiceSort.newest.obs;
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;
  StreamSubscription<List<InvoiceSummaryModel>>? _subscription;
  Worker? _searchWorker;
  Worker? _filterWorker;
  Worker? _sortWorker;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    _bindInvoices();
    _searchWorker = debounce(
      searchQuery,
      (_) => _bindInvoices(),
      time: const Duration(milliseconds: 300),
    );
    _filterWorker = ever(selectedFilter, (_) => _bindInvoices());
    _sortWorker = ever(selectedSort, (_) => _bindInvoices());
  }

  void updateSearch(String value) => searchQuery.value = value;
  void selectFilter(InvoiceListFilter value) => selectedFilter.value = value;
  void selectSort(InvoiceSort value) => selectedSort.value = value;

  Future<void> _loadCurrency() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
  }

  void _bindInvoices() {
    isLoading.value = true;
    _subscription?.cancel();
    _subscription = _repository
        .watchSummaries(
          query: searchQuery.value,
          filter: selectedFilter.value,
          sort: selectedSort.value,
          documentType: documentType,
        )
        .listen((values) {
          invoices.assignAll(values);
          isLoading.value = false;
        });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _searchWorker?.dispose();
    _filterWorker?.dispose();
    _sortWorker?.dispose();
    super.onClose();
  }
}
