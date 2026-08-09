import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/app_storage.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._storage);

  final AppStorage _storage;
  final pageController = PageController();
  final currentPage = 0.obs;

  void onPageChanged(int page) => currentPage.value = page;

  Future<void> next() async {
    if (currentPage.value < 2) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await complete();
  }

  Future<void> complete() async {
    await _storage.setBool(AppStorageKeyConst.onboardingCompleted, true);
    Get.offAllNamed<void>(AppRoutes.businessSetup);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
