import 'package:get/get.dart';

import '../../../data/services/app_storage.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(Get.find<AppStorage>()),
    );
  }
}
