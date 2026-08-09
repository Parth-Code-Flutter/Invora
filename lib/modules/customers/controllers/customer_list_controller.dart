import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomerListController extends GetxController {
  CustomerListController(this._repository);

  final CustomerRepository _repository;
  final customers = <CustomerModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  StreamSubscription<List<CustomerModel>>? _subscription;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _bindCustomers();
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

  void _bindCustomers() {
    isLoading.value = true;
    _subscription?.cancel();
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
