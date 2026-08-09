import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/services/app_storage.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(
        Get.find<AppStorage>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}
