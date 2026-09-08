import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum BillingResult { active, pending, cancelled, notActive }

class BillingAccess {
  const BillingAccess({
    required this.active,
    this.expiresAt,
    this.isSandbox = false,
  });
  final bool active;
  final DateTime? expiresAt;
  final bool isSandbox;
}

abstract class StoreBilling {
  bool get configured;
  String? get priceLabel;
  Future<void> loadOffer();
  Future<BillingAccess> access({bool refresh = false});
  Future<BillingResult> purchase();
  Future<BillingResult> restore();
  Future<void> manage();
  Future<void> resetIdentity();
}

/// Public SDK keys only. Never put RevenueCat secret keys in a mobile build.
class RevenueCatBilling implements StoreBilling {
  @override
  Future<void> manage() async {
    await _identify();
    final url = (await Purchases.getCustomerInfo()).managementURL;
    if (url == null ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      throw StateError(
        'Open subscriptions in your App Store or Google Play account settings.',
      );
    }
  }

  static const entitlementId = String.fromEnvironment(
    'RC_ENTITLEMENT',
    defaultValue: 'creovo_pro',
  );
  static const _appleKey = String.fromEnvironment('RC_APPLE_API_KEY');
  static const _googleKey = String.fromEnvironment('RC_GOOGLE_API_KEY');
  static const _testKey = String.fromEnvironment('RC_TEST_API_KEY');
  String? _boundUid;
  Future<void>? _binding;
  Package? _annual;

  String get _key {
    if (kIsWeb) return '';
    if (!kReleaseMode && _testKey.startsWith('test_')) return _testKey;
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _appleKey,
      TargetPlatform.android => _googleKey,
      _ => '',
    };
    if (key.startsWith('test_')) return '';
    return key;
  }

  @override
  bool get configured => _key.isNotEmpty;
  @override
  String? get priceLabel => _annual?.storeProduct.priceString;

  Future<void> _identify() async {
    if (!configured) {
      throw StateError('Store billing is not configured for this build.');
    }
    if (_binding != null) await _binding;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Verify your account before subscribing.');
    }
    if (_boundUid == uid) return;
    final operation = _bind(uid);
    _binding = operation;
    try {
      await operation;
    } finally {
      _binding = null;
    }
  }

  Future<void> _bind(String uid) async {
    if (await Purchases.isConfigured) {
      await Purchases.logIn(uid);
    } else {
      await Purchases.configure(PurchasesConfiguration(_key)..appUserID = uid);
    }
    _annual = null;
    _boundUid = uid;
  }

  @override
  Future<void> loadOffer() async {
    await _identify();
    _annual = (await Purchases.getOfferings()).current?.annual;
    if (_annual == null) {
      throw StateError('The yearly plan is not available from the store yet.');
    }
  }

  static BillingAccess fromInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[entitlementId];
    final expires = DateTime.tryParse(entitlement?.expirationDate ?? '');
    return BillingAccess(
      active:
          entitlement != null &&
          (expires == null || expires.isAfter(DateTime.now())),
      expiresAt: expires,
      isSandbox: entitlement?.isSandbox ?? false,
    );
  }

  @override
  Future<BillingAccess> access({bool refresh = false}) async {
    await _identify();
    if (refresh) await Purchases.invalidateCustomerInfoCache();
    return fromInfo(await Purchases.getCustomerInfo());
  }

  @override
  Future<BillingResult> purchase() async {
    await _identify();
    if (_annual == null) await loadOffer();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(_annual!));
      return fromInfo(result.customerInfo).active
          ? BillingResult.active
          : BillingResult.pending;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return BillingResult.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return BillingResult.pending;
      }
      rethrow;
    }
  }

  @override
  Future<BillingResult> restore() async {
    await _identify();
    final info = await Purchases.restorePurchases();
    return fromInfo(info).active
        ? BillingResult.active
        : BillingResult.notActive;
  }

  @override
  Future<void> resetIdentity() async {
    _boundUid = null;
    _annual = null;
    _binding = null;
    if (await Purchases.isConfigured) {
      await Purchases.logOut();
    }
  }
}
