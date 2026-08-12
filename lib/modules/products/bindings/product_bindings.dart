import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../controllers/product_details_controller.dart';
import '../controllers/product_form_controller.dart';
import '../controllers/product_list_controller.dart';

class ProductListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductListController>(
      () => ProductListController(
        Get.find<ProductRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
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
