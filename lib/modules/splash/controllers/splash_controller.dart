import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/services/app_storage.dart';

class SplashController extends GetxController {
  SplashController(this._storage, this._businessRepository);

  final AppStorage _storage;
  final BusinessRepository _businessRepository;

  @override
  void onReady() {
    super.onReady();
    resolveInitialRoute();
  }

  Future<void> resolveInitialRoute() async {
    final onboardingCompleted =
        _storage.getBool(AppStorageKeyConst.onboardingCompleted) ?? false;
    if (!onboardingCompleted) {
      Get.offAllNamed<void>(AppRoutes.onboarding);
      return;
    }

    final setupCompleted =
        _storage.getBool(AppStorageKeyConst.businessSetupCompleted) ?? false;
    final profile = await _businessRepository.getProfile();
    if (!setupCompleted || profile == null) {
      Get.offAllNamed<void>(AppRoutes.businessSetup);
      return;
    }
    Get.offAllNamed<void>(AppRoutes.dashboard);
  }
}
