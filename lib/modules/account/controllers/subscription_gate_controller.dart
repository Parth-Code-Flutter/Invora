import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../app/widgets/app_dialog.dart';

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

  Future<void> subscribe(BuildContext context) async {
    if (working.value) return;
    working.value = true;
    errorMessage.value = '';
    try {
      final online = await _entitlements.network.isOnline;
      if (!context.mounted) return;
      if (!online) {
        await showAppNoticeDialog(
          context: context,
          title: 'Connect to the internet',
          message:
              'Please turn on Wi-Fi or mobile data to complete your subscription. Your saved data is safe on this phone. Once connected, tap Subscribe again.',
          actionLabel: 'Got it',
          tone: AppDialogTone.warning,
          icon: Icons.wifi_off_rounded,
        );
        return;
      }
      await StartupNavigator.continueSession();
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
    } finally {
      working.value = false;
    }
  }

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
