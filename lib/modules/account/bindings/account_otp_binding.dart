import 'package:get/get.dart';

import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/device_account_numbers.dart';
import '../controllers/account_otp_controller.dart';

class AccountOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountOtpController>(
      () => AccountOtpController(
        Get.find<AccountAuthService>(),
        Get.find<AccountEntitlementService>(),
        const ContactsDeviceAccountNumbers(),
      ),
    );
  }
}
