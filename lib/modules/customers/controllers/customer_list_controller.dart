import 'dart:async';

import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/business_repository.dart';

class CustomerListController extends GetxController {
  CustomerListController(this._repository, this._invoices, this._business);

  final CustomerRepository _repository;
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final customers = <CustomerModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final billedByCustomer = <int, int>{}.obs;
  final balanceByCustomer = <int, int>{}.obs;
  final invoiceCountByCustomer = <int, int>{}.obs;
  final currencySymbol = '₹'.obs;
  StreamSubscription<List<CustomerModel>>? _subscription;
  StreamSubscription<List<InvoiceSummaryModel>>? _invoiceSubscription;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _bindCustomers();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    _invoiceSubscription = _invoices.watchSummaries().listen(
      _aggregateInvoices,
    );
    _searchWorker = debounce<String>(
      searchQuery,
      (_) => _bindCustomers(),
      time: const Duration(milliseconds: 300),
    );
  }

  void updateSearch(String value) => searchQuery.value = value;

  Future<void> deleteCustomer(CustomerModel customer) async {
    final id = customer.id;
    if (id == null) return;
    await _repository.softDelete(id);
  }

  int billedFor(CustomerModel customer) => billedByCustomer[customer.id] ?? 0;
  int balanceFor(CustomerModel customer) => balanceByCustomer[customer.id] ?? 0;
  int invoiceCountFor(CustomerModel customer) =>
      invoiceCountByCustomer[customer.id] ?? 0;

  void _aggregateInvoices(List<InvoiceSummaryModel> values) {
    final billed = <int, int>{};
    final balance = <int, int>{};
    final counts = <int, int>{};
    for (final invoice in values) {
      final customerId = invoice.customerId;
      if (customerId == null ||
          invoice.status == InvoiceStatus.draft ||
          invoice.status == InvoiceStatus.cancelled) {
        continue;
      }
      billed[customerId] = (billed[customerId] ?? 0) + invoice.grandTotalMinor;
      balance[customerId] = (balance[customerId] ?? 0) + invoice.balanceMinor;
      counts[customerId] = (counts[customerId] ?? 0) + 1;
    }
    billedByCustomer.assignAll(billed);
    balanceByCustomer.assignAll(balance);
    invoiceCountByCustomer.assignAll(counts);
  }

  void _bindCustomers() {
    isLoading.value = true;
    _subscription?.cancel();
    _invoiceSubscription?.cancel();
    _subscription = _repository.watchCustomers(query: searchQuery.value).listen(
      (items) {
        customers.assignAll(items);
        isLoading.value = false;
      },
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    _subscription?.cancel();
    super.onClose();
  }
}
