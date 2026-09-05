import 'package:get/get.dart';

import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/entitlement_policy.dart';

class PlanController extends GetxController {
  PlanController(this._auth, this._entitlements);

  final AccountAuthService _auth;
  final AccountEntitlementService _entitlements;

  final refreshing = false.obs;
  final errorMessage = ''.obs;

  EntitlementSnapshot? get snapshot => _entitlements.lastSnapshot;

  EntitlementAccess get access => _entitlements.lastAccess;

  String? get accountMobile => snapshot?.mobile ?? _auth.e164Mobile;

  @override
  void onReady() {
    super.onReady();
    refreshPlan(silent: true);
  }

  Future<void> refreshPlan({bool silent = false}) async {
    if (_auth is SkipAccountAuthService) return;
    if (!silent) {
      errorMessage.value = '';
      refreshing.value = true;
    }
    try {
      await _entitlements.resolve(_auth);
      update();
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
      update();
    } finally {
      refreshing.value = false;
    }
  }
}
