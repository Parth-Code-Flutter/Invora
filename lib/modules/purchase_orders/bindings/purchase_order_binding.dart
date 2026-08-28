import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/services/purchase_order_pdf_service.dart';
import '../controllers/purchase_order_controller.dart';

class PurchaseOrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PurchaseOrderListController(Get.find<PurchaseOrderRepository>()),
    );
  }
}

class PurchaseOrderFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PurchaseOrderFormController(
        Get.find<PurchaseOrderRepository>(),
        Get.find<PurchaseRepository>(),
      ),
    );
  }
}

class PurchaseOrderDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PurchaseOrderDetailsController(
        Get.find<PurchaseOrderRepository>(),
        Get.find<BusinessRepository>(),
        Get.find<PurchaseOrderPdfService>(),
      ),
    );
  }
}

class PurchaseOrderConvertBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PurchaseOrderConvertController(Get.find<PurchaseOrderRepository>()),
    );
  }
}
