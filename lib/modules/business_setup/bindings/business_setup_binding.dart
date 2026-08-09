import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/image_storage_service.dart';
import '../controllers/business_setup_controller.dart';

class BusinessSetupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImageStorageService>(ImageStorageService.new);
    Get.lazyPut<BusinessSetupController>(
      () => BusinessSetupController(
        Get.find<BusinessRepository>(),
        Get.find<AppStorage>(),
        Get.find<ImageStorageService>(),
      ),
    );
  }
}
