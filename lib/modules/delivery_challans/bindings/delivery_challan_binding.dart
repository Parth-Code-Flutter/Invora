import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/delivery_challan_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/delivery_challan_pdf_service.dart';
import '../../../data/services/invoice_defaults_service.dart';
import '../controllers/delivery_challan_controller.dart';

class DeliveryChallanListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () =>
          DeliveryChallanListController(Get.find<DeliveryChallanRepository>()),
    );
  }
}

class DeliveryChallanFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DeliveryChallanFormController(
        Get.find<DeliveryChallanRepository>(),
        Get.find<CustomerRepository>(),
        Get.find<InvoiceRepository>(),
      ),
    );
  }
}

class DeliveryChallanDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DeliveryChallanDetailsController(
        Get.find<DeliveryChallanRepository>(),
        Get.find<BusinessRepository>(),
        Get.find<DeliveryChallanPdfService>(),
      ),
    );
  }
}

class DeliveryChallanConvertBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DeliveryChallanConvertController(
        Get.find<DeliveryChallanRepository>(),
        Get.find<InvoiceRepository>(),
        Get.find<BusinessRepository>(),
        defaults: Get.find<InvoiceDefaultsService>(),
      ),
    );
  }
}
