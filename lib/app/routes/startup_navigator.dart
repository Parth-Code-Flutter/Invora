import 'package:get/get.dart';

import '../../data/repositories/business_repository.dart';
import '../../data/services/account_auth_service.dart';
import '../../data/services/app_storage.dart';
import '../../data/services/business_workspace_service.dart';
import '../constants/app_storage_key_const.dart';
import 'app_routes.dart';

abstract final class StartupNavigator {
  static Future<void> continueSession({bool holdSplash = false}) async {
    final delay = holdSplash
        ? Future<void>.delayed(const Duration(milliseconds: 1600))
        : Future<void>.value();
    final account = Get.find<AccountAuthService>();
    if (!account.isVerified) {
      await delay;
      Get.offAllNamed<void>(AppRoutes.accountOtp);
      return;
    }

    final storage = Get.find<AppStorage>();
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
    final workspace = Get.find<BusinessWorkspaceService>();
    Get.offAllNamed<void>(
      workspace.isPurchases ? AppRoutes.purchases : AppRoutes.dashboard,
    );
  }
}
