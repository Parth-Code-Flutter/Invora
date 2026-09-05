import 'package:get/get.dart';

import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../controllers/plan_controller.dart';

class PlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanController>(
      () => PlanController(
        Get.find<AccountAuthService>(),
        Get.find<AccountEntitlementService>(),
      ),
    );
  }
}
