import 'package:get/get.dart';

import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../controllers/customer_details_controller.dart';
import '../controllers/customer_form_controller.dart';
import '../controllers/customer_list_controller.dart';

class CustomerListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerListController>(
      () => CustomerListController(Get.find<CustomerRepository>()),
    );
  }
}

class CustomerFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerFormController>(
      () => CustomerFormController(Get.find<CustomerRepository>()),
    );
  }
}

class CustomerDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerDetailsController>(
      () => CustomerDetailsController(
        Get.find<CustomerRepository>(),
        Get.find<InvoiceRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}
