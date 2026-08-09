import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomerDetailsController extends GetxController {
  CustomerDetailsController(this._repository);

  final CustomerRepository _repository;
  final customer = Rxn<CustomerModel>();
  final isLoading = true.obs;

  int get customerId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    refreshCustomer();
  }

  Future<void> refreshCustomer() async {
    isLoading.value = true;
    customer.value = await _repository.getById(customerId);
    isLoading.value = false;
  }
}
