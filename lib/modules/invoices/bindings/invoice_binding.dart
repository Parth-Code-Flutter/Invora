import 'package:get/get.dart';

import '../controllers/invoice_create_controller.dart';
import '../controllers/invoice_details_controller.dart';
import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_preview_controller.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InvoiceListController(Get.find(), Get.find()));
  }
}

class QuotationListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoiceListController(
        Get.find(),
        Get.find(),
        documentType: DocumentType.quotation,
      ),
    );
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

class QuotationCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoiceCreateController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        documentType: DocumentType.quotation,
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

class InvoicePreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoicePreviewController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
    );
  }
}
