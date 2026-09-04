import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/stock_ledger.dart';
import '../../../data/services/product_image_service.dart';
import '../controllers/product_details_controller.dart';
import '../controllers/product_form_controller.dart';
import '../controllers/product_list_controller.dart';

class ProductListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProductListController>()) {
      Get.put<ProductListController>(
        ProductListController(
          Get.find<ProductRepository>(),
          Get.find<BusinessRepository>(),
        ),
        permanent: true,
      );
    }
  }
}

class ProductFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductFormController>(
      () => ProductFormController(
        Get.find<ProductRepository>(),
        Get.find<BusinessRepository>(),
        Get.find(),
        Get.find(),
        Get.isRegistered<StockLedger>() ? Get.find<StockLedger>() : null,
        Get.isRegistered<ProductImageService>()
            ? Get.find<ProductImageService>()
            : null,
      ),
    );
  }
}

class ProductDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductDetailsController>(
      () => ProductDetailsController(
        Get.find<ProductRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}
