import 'package:get/get.dart';

import '../../../data/services/app_storage.dart';
import '../../../data/services/business_workspace_service.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(
        Get.find<AppStorage>(),
        Get.find<BusinessWorkspaceService>(),
      ),
    );
  }
}
