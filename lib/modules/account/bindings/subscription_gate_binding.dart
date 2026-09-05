import 'package:get/get.dart';

import '../controllers/subscription_gate_controller.dart';

class SubscriptionGateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionGateController>(SubscriptionGateController.new);
  }
}
