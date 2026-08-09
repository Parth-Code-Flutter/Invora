import 'package:get/get.dart';

import '../controllers/invoice_create_controller.dart';

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
