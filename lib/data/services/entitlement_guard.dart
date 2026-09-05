import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import 'account_auth_service.dart';
import 'account_entitlement_service.dart';
import 'entitlement_policy.dart';

class EntitlementGuard extends GetxService with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(recheck());
    }
  }

  Future<void> recheck() async {
    if (!Get.isRegistered<AccountAuthService>() ||
        !Get.isRegistered<AccountEntitlementService>()) {
      return;
    }
    final auth = Get.find<AccountAuthService>();
    if (auth is SkipAccountAuthService || !auth.isVerified) return;
    final route = Get.currentRoute;
    if (route == AppRoutes.splash ||
        route == AppRoutes.accountOtp ||
        route == AppRoutes.subscription) {
      return;
    }
    try {
      final access = await Get.find<AccountEntitlementService>().resolve(auth);
      if (access == EntitlementAccess.active) return;
      Get.offAllNamed<void>(AppRoutes.subscription);
    } on AccountAuthException {
      Get.offAllNamed<void>(AppRoutes.accountOtp);
    }
  }
}
