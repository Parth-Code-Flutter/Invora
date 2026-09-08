import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/business_repository.dart';
import '../../data/services/account_auth_service.dart';
import '../../data/services/account_entitlement_service.dart';
import '../../data/services/app_storage.dart';
import '../../data/services/entitlement_policy.dart';
import '../constants/app_storage_key_const.dart';
import 'app_routes.dart';

abstract final class StartupNavigator {
  static Future<void> continueSession({bool holdSplash = false}) async {
    final delay = holdSplash
        ? Future<void>.delayed(const Duration(milliseconds: 1600))
        : Future<void>.value();
    final account = Get.find<AccountAuthService>();
    final storage = Get.find<AppStorage>();
    await forgetAuthFromPreviousInstall(account, storage);
    if (!account.isVerified) {
      await delay;
      Get.offAllNamed<void>(AppRoutes.accountOtp);
      return;
    }

    try {
      final access = await Get.find<AccountEntitlementService>().resolve(
        account,
      );
      if (access != EntitlementAccess.active) {
        await delay;
        Get.offAllNamed<void>(AppRoutes.subscription);
        return;
      }
    } on AccountAuthException {
      await delay;
      Get.offAllNamed<void>(AppRoutes.accountOtp);
      return;
    }

    final onboardingCompleted =
        storage.getBool(AppStorageKeyConst.onboardingCompleted) ?? false;
    if (!onboardingCompleted) {
      await delay;
      Get.offAllNamed<void>(AppRoutes.onboarding);
      return;
    }

    final setupCompleted =
        storage.getBool(AppStorageKeyConst.businessSetupCompleted) ?? false;
    final profile = await Get.find<BusinessRepository>().getProfile();
    if (!setupCompleted || profile == null) {
      await delay;
      Get.offAllNamed<void>(AppRoutes.businessSetup);
      return;
    }
    await delay;
    Get.offAllNamed<void>(AppRoutes.dashboard);
  }

  /// iOS Keychain can keep Firebase Phone Auth after uninstall. Shared
  /// Preferences do not. Drop that leftover session so a reinstall asks for
  /// the subscription mobile again. Same-install launches keep the session.
  @visibleForTesting
  static Future<void> forgetAuthFromPreviousInstall(
    AccountAuthService account,
    AppStorage storage,
  ) async {
    if (account is SkipAccountAuthService) return;
    final bound =
        storage.getBool(AppStorageKeyConst.accountSessionBoundToInstall) ??
        false;
    if (bound) return;
    final existingShop =
        (storage.getBool(AppStorageKeyConst.onboardingCompleted) ?? false) ||
        (storage.getBool(AppStorageKeyConst.businessSetupCompleted) ?? false);
    if (existingShop) {
      await storage.setBool(
        AppStorageKeyConst.accountSessionBoundToInstall,
        true,
      );
      return;
    }
    if (account.isVerified) {
      if (Get.isRegistered<AccountEntitlementService>()) {
        await Get.find<AccountEntitlementService>().resetStoreIdentity();
      }
      await account.signOut();
    }
    await storage.setBool(
      AppStorageKeyConst.accountSessionBoundToInstall,
      true,
    );
  }
}
