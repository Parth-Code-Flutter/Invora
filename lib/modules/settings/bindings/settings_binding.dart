import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../controllers/more_controller.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/services/unit_service.dart';
import '../controllers/unit_settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController(Get.find()));
  }
}

class MoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MoreController(Get.find<BusinessRepository>()));
  }
}

class UnitSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UnitSettingsController(Get.find<UnitService>()));
  }
}
