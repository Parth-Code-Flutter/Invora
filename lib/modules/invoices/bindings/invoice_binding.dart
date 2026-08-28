import 'package:get/get.dart';

import '../controllers/credit_note_create_controller.dart';
import '../controllers/credit_note_details_controller.dart';
import '../controllers/invoice_create_controller.dart';
import '../controllers/invoice_details_controller.dart';
import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_preview_controller.dart';
import '../controllers/payment_receipt_controller.dart';
import '../scan/product_scan_controller.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/delivery_challan_repository.dart';
import '../../../data/services/invoice_defaults_service.dart';

class InvoiceListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InvoiceListController>()) {
      Get.put(InvoiceListController(Get.find(), Get.find()), permanent: true);
    }
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
      tag: InvoiceListController.quotationTag,
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
        defaults: Get.find<InvoiceDefaultsService>(),
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
        defaults: Get.find<InvoiceDefaultsService>(),
        documentType: DocumentType.quotation,
      ),
    );
  }
}

class InvoiceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoiceDetailsController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        challans: Get.find<DeliveryChallanRepository>(),
      ),
    );
  }
}

class CreditNoteCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreditNoteCreateController(Get.find(), Get.find()));
  }
}

class CreditNoteDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CreditNoteDetailsController(Get.find(), Get.find(), Get.find()),
    );
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

class PaymentReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PaymentReceiptController(Get.find(), Get.find(), Get.find()),
    );
  }
}

class ProductScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductScanController(Get.find(), Get.find()));
  }
}
