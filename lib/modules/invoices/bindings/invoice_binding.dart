import 'package:get/get.dart';

import '../controllers/invoice_create_controller.dart';
import '../controllers/invoice_details_controller.dart';
import '../controllers/invoice_list_controller.dart';

class InvoiceListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InvoiceListController(Get.find(), Get.find()));
  }
}

class InvoiceCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoiceCreateController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
    );
  }
}

class InvoiceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InvoiceDetailsController(Get.find(), Get.find()));
  }
}
