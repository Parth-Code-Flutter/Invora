import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';

class MoreController extends GetxController {
  MoreController(this._business);

  final BusinessRepository _business;
  final profile = Rxn<BusinessProfileModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    profile.value = await _business.getProfile();
    isLoading.value = false;
  }

  Future<void> editBusiness() async {
    await Get.toNamed<void>(AppRoutes.businessSetup);
    await loadProfile();
  }
}
