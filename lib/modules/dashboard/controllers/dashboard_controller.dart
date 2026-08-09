import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository);

  final BusinessRepository _repository;
  final profile = Rxn<BusinessProfileModel>();

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    profile.value = await _repository.getProfile();
  }
}
