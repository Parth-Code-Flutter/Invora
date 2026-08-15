import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/business_workspace_service.dart';

class OnboardingController extends GetxController {
  OnboardingController(
    this._storage, [
    BusinessWorkspaceService? workspaceService,
  ]) : _workspaceService =
           workspaceService ?? BusinessWorkspaceService(_storage);

  final AppStorage _storage;
  final BusinessWorkspaceService _workspaceService;
  final pageController = PageController();
  final currentPage = 0.obs;
  final selectedWorkspace = BusinessWorkspace.sales.obs;

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
    Get.offAllNamed<void>(AppRoutes.workspaceSetup);
  }

  Future<void> selectWorkspace(BusinessWorkspace workspace) async {
    await _workspaceService.setInitial(workspace);
    await _storage.setBool(AppStorageKeyConst.onboardingCompleted, true);
    Get.offAllNamed<void>(AppRoutes.businessSetup);
  }

  void previewWorkspace(BusinessWorkspace workspace) {
    selectedWorkspace.value = workspace;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
