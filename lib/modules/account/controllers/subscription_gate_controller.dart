import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../app/widgets/app_dialog.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/routes/startup_navigator.dart';
import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/entitlement_policy.dart';
import '../../../data/services/store_billing_service.dart';

enum SubscriptionStage { offer, confirming, pending, success }

class SubscriptionGateController extends GetxController
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed &&
        stage.value == SubscriptionStage.pending) {
      checkPurchase();
    }
  }

  final working = false.obs;
  final errorMessage = ''.obs;
  final stage = SubscriptionStage.offer.obs;
  final storePrice = RxnString();
  StoreBilling? get billing => _entitlements.billing;

  @override
  void onReady() {
    super.onReady();
    loadOffer();
  }

  Future<void> loadOffer() async {
    if (billing?.configured != true) return;
    try {
      await billing!.loadOffer();
      storePrice.value = billing!.priceLabel;
    } catch (_) {
      errorMessage.value =
          'The store plan could not be loaded. Connect to the internet and try again.';
    }
  }

  Future<void> restore(BuildContext context) =>
      subscribe(context, restoring: true);

  Future<void> checkPurchase() async {
    if (working.value) return;
    working.value = true;
    errorMessage.value = '';
    try {
      if (!await _entitlements.network.isOnline) {
        errorMessage.value =
            'Connect to the internet to check your purchase. You do not need to pay again.';
        return;
      }
      final result = await billing?.access(refresh: true);
      if (result?.active == true) stage.value = SubscriptionStage.success;
    } catch (_) {
      errorMessage.value =
          'Confirmation is not available yet. Please try again shortly.';
    } finally {
      working.value = false;
    }
  }

  Future<void> continueAfterPurchase() async {
    if (working.value) return;
    await retry();
  }

  AccountEntitlementService get _entitlements =>
      Get.find<AccountEntitlementService>();

  EntitlementAccess get access => _entitlements.lastAccess;

  EntitlementSnapshot? get snapshot => _entitlements.lastSnapshot;

  bool get needsNetwork => access == EntitlementAccess.needsNetwork;

  bool get hasLiveStorePrice {
    final price = storePrice.value;
    return price != null && price.trim().isNotEmpty;
  }

  Future<void> subscribe(BuildContext context, {bool restoring = false}) async {
    if (working.value) return;
    working.value = true;
    errorMessage.value = '';
    try {
      final online = await _entitlements.network.isOnline;
      if (!context.mounted) return;
      if (!online) {
        await showAppNoticeDialog(
          context: context,
          title: 'Connect to the internet',
          message:
              'Please turn on Wi-Fi or mobile data to complete your subscription. Your saved data is safe on this phone. Once connected, tap Subscribe again.',
          actionLabel: 'Got it',
          tone: AppDialogTone.warning,
          icon: Icons.wifi_off_rounded,
        );
        return;
      }
      if (billing?.configured != true) {
        await showAppNoticeDialog(
          context: context,
          title: 'Subscriptions are not available yet',
          message:
              'Store billing has not been configured for this build. Please try again after the app is updated.',
          tone: AppDialogTone.warning,
          icon: Icons.storefront_outlined,
        );
        return;
      }
      if (!restoring && !hasLiveStorePrice) {
        await billing!.loadOffer();
        storePrice.value = billing!.priceLabel;
      }
      stage.value = SubscriptionStage.confirming;
      final result = restoring
          ? await billing!.restore()
          : await billing!.purchase();
      stage.value = switch (result) {
        BillingResult.active => SubscriptionStage.success,
        BillingResult.pending => SubscriptionStage.pending,
        _ => SubscriptionStage.offer,
      };
      if (result == BillingResult.notActive) {
        errorMessage.value =
            'No active subscription was found for this store account.';
      }
    } on AccountAuthException catch (error) {
      stage.value = SubscriptionStage.offer;
      errorMessage.value = error.message;
    } catch (_) {
      stage.value = SubscriptionStage.offer;
      errorMessage.value =
          'The store could not complete this request. Use Restore purchases before trying to pay again.';
    } finally {
      working.value = false;
    }
  }

  Future<void> retry() async {
    errorMessage.value = '';
    working.value = true;
    try {
      await StartupNavigator.continueSession();
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
    } finally {
      working.value = false;
    }
  }

  Future<void> useDifferentNumber() async {
    final auth = Get.find<AccountAuthService>();
    await _entitlements.resetStoreIdentity();
    await auth.signOut();
    Get.offAllNamed<void>(AppRoutes.accountOtp);
  }
}
