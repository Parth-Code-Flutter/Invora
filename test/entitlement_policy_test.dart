import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/services/account_auth_service.dart';
import 'package:creovo_invoice/data/services/account_entitlement_service.dart';
import 'package:creovo_invoice/data/services/account_phone.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/entitlement_policy.dart';
import 'package:creovo_invoice/data/services/network_status.dart';

class _VerifiedAuth implements AccountAuthService {
  @override
  bool isVerified = true;

  @override
  String? e164Mobile = '+917048321663';

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp(String smsCode) async {}

  @override
  Future<void> signOut() async {
    isVerified = false;
    e164Mobile = null;
  }
}

void main() {
  final ends = DateTime.utc(2026, 9, 4, 17); // 4 Sep 2026, 22:30 IST

  EntitlementSnapshot trialAt(DateTime trialEndsAt, {String status = 'trial'}) {
    return EntitlementSnapshot(
      mobile: '+917048321663',
      status: status,
      planId: 'default',
      trialEndsAt: trialEndsAt,
    );
  }

  test('active trial stays open before the end instant', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: DateTime.utc(2026, 9, 3, 12),
        snapshot: trialAt(ends),
      ),
      EntitlementAccess.active,
    );
  });

  test('last local day without internet asks to connect', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: ends.subtract(const Duration(minutes: 1)),
        snapshot: trialAt(ends),
      ),
      EntitlementAccess.needsNetwork,
    );
  });

  test('last local day with internet stays open until trialEndsAt', () {
    expect(
      EntitlementPolicy.decide(
        online: true,
        now: ends.subtract(const Duration(minutes: 1)),
        snapshot: trialAt(ends),
      ),
      EntitlementAccess.active,
    );
  });

  test('past trialEndsAt is expired even when offline', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: DateTime.utc(2026, 9, 4, 17, 1),
        snapshot: trialAt(ends),
      ),
      EntitlementAccess.expired,
    );
  });

  test('paid status stays open after the trial date', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: DateTime.utc(2026, 9, 10),
        snapshot: trialAt(ends, status: 'paid'),
      ),
      EntitlementAccess.active,
    );
  });

  test('clock rollback offline requires a network check', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: DateTime.utc(2026, 8, 1),
        snapshot: trialAt(ends),
        lastSeenAt: DateTime.utc(2026, 9, 3),
      ),
      EntitlementAccess.needsNetwork,
    );
  });

  test('missing snapshot cannot open the shop', () {
    expect(
      EntitlementPolicy.decide(
        online: false,
        now: DateTime.utc(2026, 9, 5),
        snapshot: null,
      ),
      EntitlementAccess.needsNetwork,
    );
  });

  test('offline cached expiry blocks the account without Firestore', () async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.entitlementMobile: '+917048321663',
      AppStorageKeyConst.entitlementStatus: 'trial',
      AppStorageKeyConst.entitlementPlanId: 'default',
      AppStorageKeyConst.entitlementTrialEndsAtMs: ends.millisecondsSinceEpoch,
    });
    final storage = await AppStorage.create();
    final service = AccountEntitlementService(
      storage: storage,
      network: const FixedNetworkStatus(false),
      clock: () => DateTime.utc(2026, 9, 5, 8, 30),
    );

    expect(await service.resolve(_VerifiedAuth()), EntitlementAccess.expired);
    expect(service.lastSnapshot?.trialEndsAt, ends);
  });

  test(
    'offline last day uses the cached trial instead of skipping it',
    () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeyConst.entitlementMobile: '+917048321663',
        AppStorageKeyConst.entitlementStatus: 'trial',
        AppStorageKeyConst.entitlementTrialEndsAtMs:
            ends.millisecondsSinceEpoch,
      });
      final storage = await AppStorage.create();
      final service = AccountEntitlementService(
        storage: storage,
        network: const FixedNetworkStatus(false),
        clock: () => ends.subtract(const Duration(minutes: 1)),
      );

      expect(
        await service.resolve(_VerifiedAuth()),
        EntitlementAccess.needsNetwork,
      );
    },
  );

  test('skip auth never blocks widget tests or demo launches', () async {
    final service = AccountEntitlementService(
      network: const FixedNetworkStatus(false),
      clock: () => DateTime.utc(2026, 9, 10),
    );
    expect(
      await service.resolve(SkipAccountAuthService()),
      EntitlementAccess.active,
    );
  });

  test('default Firestore title shows as Creovo Yearly', () {
    expect(
      const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'trial',
        planId: 'default',
        planTitle: 'Default',
        priceInr: 0,
        period: 'yearly',
      ).displayTitle,
      'Creovo Yearly',
    );
    expect(
      const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'trial',
        planId: 'default',
        planTitle: 'Default',
      ).priceLine,
      'One plan · billed each year',
    );
    expect(
      const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'trial',
        planId: 'default',
      ).offerPriceInr,
      499,
    );
    expect(
      const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'trial',
        planId: 'default',
      ).offerMonthlyInr,
      41,
    );
  });

  test('trial remaining days drive the More subtitle', () {
    final snapshot = EntitlementSnapshot(
      mobile: '+917048321663',
      status: 'trial',
      planId: 'default',
      trialEndsAt: DateTime.utc(2026, 9, 10),
      planTitle: 'Default',
      priceInr: 0,
      period: 'yearly',
    );
    expect(snapshot.remainingDays(DateTime.utc(2026, 9, 5)), 5);
    expect(
      snapshot.moreSubtitle(DateTime.utc(2026, 9, 5)),
      'Trial · 5 days left',
    );
    expect(
      snapshot.moreSubtitle(DateTime.utc(2026, 9, 9)),
      'Trial · 1 day left',
    );
    expect(snapshot.licenseTotalDays, 90);
    expect(snapshot.yearlyPriceLabel, '₹499/yr');
    expect(
      snapshot.licenseProgress(DateTime.utc(2026, 9, 5)),
      closeTo(5 / 90, 0.001),
    );
    expect(
      const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'paid',
        planId: 'default',
        priceInr: 0,
        period: 'yearly',
      ).moreSubtitle(),
      'Subscribed · One plan · billed each year',
    );
  });

  test('account phone doc id matches the Firestore entitlement id', () {
    expect(AccountPhone.toDocId('+917048321663'), '917048321663');
  });

  test('entitlement cache keys stay out of the backup whitelist', () {
    const exported = {
      AppStorageKeyConst.isDarkMode,
      AppStorageKeyConst.onboardingCompleted,
      AppStorageKeyConst.businessSetupCompleted,
    };
    expect(
      exported.intersection(AppStorageKeyConst.entitlementCacheKeys),
      isEmpty,
    );
    expect(
      AppStorageKeyConst.entitlementCacheKeys.contains(
        AppStorageKeyConst.appLockPinHash,
      ),
      isFalse,
    );
  });
}
