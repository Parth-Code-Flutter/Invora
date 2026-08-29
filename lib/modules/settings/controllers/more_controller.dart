import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/services/stock_ledger.dart';

class MoreController extends GetxController {
  MoreController(this._business, [this._ledger]);

  final BusinessRepository _business;
  final StockLedger? _ledger;
  final profile = Rxn<BusinessProfileModel>();
  final isLoading = true.obs;
  final stockEnabled = false.obs;
  StreamSubscription<bool>? _stockSubscription;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    final ledger = _ledger;
    if (ledger != null) {
      _stockSubscription = ledger.watchEnabled().listen(
        (enabled) => stockEnabled.value = enabled,
      );
    }
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

  @override
  void onClose() {
    _stockSubscription?.cancel();
    super.onClose();
  }
}
