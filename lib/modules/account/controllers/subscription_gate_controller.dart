import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/routes/startup_navigator.dart';
import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/entitlement_policy.dart';

class SubscriptionGateController extends GetxController {
  final working = false.obs;
  final errorMessage = ''.obs;

  AccountEntitlementService get _entitlements =>
      Get.find<AccountEntitlementService>();

  EntitlementAccess get access => _entitlements.lastAccess;

  EntitlementSnapshot? get snapshot => _entitlements.lastSnapshot;

  bool get needsNetwork => access == EntitlementAccess.needsNetwork;

  Future<void> subscribe() => retry();

  Future<void> retry() async {
    errorMessage.value = '';
    working.value = true;
    try {
      await StartupNavigator.continueSession();
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
    } finally {
      working.value = false;
    }
  }

  Future<void> useDifferentNumber() async {
    final auth = Get.find<AccountAuthService>();
    await auth.signOut();
    Get.offAllNamed<void>(AppRoutes.accountOtp);
  }
}
