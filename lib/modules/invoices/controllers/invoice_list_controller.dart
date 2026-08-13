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
  int _bindingGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    refreshInvoices();
    _searchWorker = debounce(
      searchQuery,
      (_) => refreshInvoices(),
      time: const Duration(milliseconds: 300),
    );
    _filterWorker = ever(selectedFilter, (_) => refreshInvoices());
    _sortWorker = ever(selectedSort, (_) => refreshInvoices());
  }

  void updateSearch(String value) => searchQuery.value = value;
  void selectFilter(InvoiceListFilter value) => selectedFilter.value = value;
  void selectSort(InvoiceSort value) => selectedSort.value = value;

  Future<void> _loadCurrency() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
  }

  /// Rebinds the live database query when the list route becomes visible.
  ///
  /// GetX can reuse this controller while replacing a create/preview route
  /// stack. Explicit rebinding prevents a cancelled old subscription from
  /// leaving the list permanently in its loading skeleton.
  void refreshInvoices() {
    final generation = ++_bindingGeneration;
    isLoading.value = true;
    _subscription?.cancel();
    _subscription = _repository
        .watchSummaries(
          query: searchQuery.value,
          filter: selectedFilter.value,
          sort: selectedSort.value,
          documentType: documentType,
        )
        .listen(
          (values) {
            if (generation != _bindingGeneration || isClosed) return;
            invoices.assignAll(values);
            isLoading.value = false;
          },
          onError: (_) {
            if (generation != _bindingGeneration || isClosed) return;
            isLoading.value = false;
          },
        );
  }

  @override
  void onClose() {
    _bindingGeneration++;
    _subscription?.cancel();
    _searchWorker?.dispose();
    _filterWorker?.dispose();
    _sortWorker?.dispose();
    super.onClose();
  }
}
