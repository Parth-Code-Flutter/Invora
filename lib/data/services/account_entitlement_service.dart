import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants/app_storage_key_const.dart';
import 'account_auth_service.dart';
import 'account_phone.dart';
import 'app_storage.dart';
import 'entitlement_policy.dart';
import 'network_status.dart';

class AccountEntitlementService {
  AccountEntitlementService({
    this.storage,
    this.network = const DnsNetworkStatus(),
    this.clock,
    this.firestore,
  });

  final AppStorage? storage;
  final NetworkStatus network;
  final DateTime Function()? clock;
  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  AppStorage? get _storage => storage;

  DateTime get _now => clock?.call() ?? DateTime.now().toUtc();

  static const defaultPlanId = 'default';
  static const _serverGet = GetOptions(source: Source.server);
  static const _timeout = Duration(seconds: 8);

  String lastSyncError = '';
  EntitlementAccess lastAccess = EntitlementAccess.active;
  EntitlementSnapshot? lastSnapshot;

  Future<void> syncAfterLogin(AccountAuthService auth) async {
    await resolve(auth);
  }

  Future<EntitlementAccess> resolve(AccountAuthService auth) async {
    if (auth is SkipAccountAuthService) {
      lastSyncError = '';
      lastAccess = EntitlementAccess.active;
      lastSnapshot = null;
      return lastAccess;
    }
    final phone = auth.e164Mobile;
    if (phone == null || phone.isEmpty) {
      throw AccountAuthException('Could not verify this number.');
    }

    final online = await network.isOnline;
    EntitlementSnapshot? remote;
    var usedServer = false;
    if (online) {
      try {
        remote = await fetchFromServer(phone);
        usedServer = remote != null;
        lastSyncError = '';
      } on AccountAuthException catch (error) {
        lastSyncError = error.message;
        if (_readCache(phone) == null) rethrow;
      } on FirebaseException catch (error) {
        final mapped = mapEntitlementFailure(
          code: error.code,
          message: error.message,
        );
        lastSyncError = mapped.message;
        if (_readCache(phone) == null) throw mapped;
      } on TimeoutException {
        final mapped = mapEntitlementFailure(
          code: 'unavailable',
          message: 'Failed to get document because the client is offline.',
        );
        lastSyncError = mapped.message;
        if (_readCache(phone) == null) throw mapped;
      } catch (error) {
        final mapped = mapEntitlementFailure(
          code: '',
          message: error.toString(),
        );
        lastSyncError = mapped.message;
        if (_readCache(phone) == null) throw mapped;
      }
    }

    final snapshot = remote ?? _readCache(phone);
    if (usedServer && snapshot != null) {
      await _persist(snapshot, _now);
    } else if (!online) {
      await _touchLastSeen();
    }

    lastSnapshot = snapshot;
    lastAccess = EntitlementPolicy.decide(
      online: usedServer,
      now: _now,
      snapshot: snapshot,
      lastSeenAt: _lastSeenAt(),
    );
    if (lastAccess == EntitlementAccess.needsNetwork && snapshot == null) {
      lastSyncError =
          'Turn on internet to check your subscription plan for this number.';
    }
    return lastAccess;
  }

  Future<EntitlementSnapshot?> fetchFromServer(String phone) async {
    final doc = _db.collection('entitlements').doc(AccountPhone.toDocId(phone));
    final existing = await doc.get(_serverGet).timeout(_timeout);
    Map<String, dynamic>? data;
    if (existing.exists) {
      data = existing.data();
    } else {
      final planSnap = await _db
          .collection('plans')
          .doc(defaultPlanId)
          .get(_serverGet)
          .timeout(_timeout);
      if (!planSnap.exists) {
        throw AccountAuthException('Subscription plans are not set up yet.');
      }
      final days = (planSnap.data()?['trialDays'] as num?)?.toInt() ?? 90;
      final ends = _now.add(Duration(days: days));
      await doc
          .set({
            'mobile': phone,
            'status': 'trial',
            'planId': defaultPlanId,
            'trialStartedAt': FieldValue.serverTimestamp(),
            'trialEndsAt': Timestamp.fromDate(ends),
            'source': 'otp',
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_timeout);
      data = {
        'mobile': phone,
        'status': 'trial',
        'planId': defaultPlanId,
        'trialEndsAt': Timestamp.fromDate(ends),
      };
    }

    final planId = (data?['planId'] as String?)?.trim().isNotEmpty == true
        ? data!['planId'] as String
        : defaultPlanId;
    var title = 'Creovo Billing';
    var priceInr = 0;
    var period = 'yearly';
    try {
      final planSnap = await _db
          .collection('plans')
          .doc(planId)
          .get(_serverGet)
          .timeout(_timeout);
      final plan = planSnap.data();
      if (plan != null) {
        title = (plan['title'] as String?)?.trim().isNotEmpty == true
            ? plan['title'] as String
            : title;
        priceInr = (plan['priceInr'] as num?)?.toInt() ?? 0;
        period = (plan['period'] as String?)?.trim().isNotEmpty == true
            ? plan['period'] as String
            : period;
      }
    } catch (_) {}

    return EntitlementSnapshot(
      mobile: phone,
      status: (data?['status'] as String?)?.trim().isNotEmpty == true
          ? data!['status'] as String
          : 'trial',
      planId: planId,
      trialEndsAt: _timestamp(data?['trialEndsAt']),
      planTitle: title,
      priceInr: priceInr,
      period: period,
    );
  }

  EntitlementSnapshot? _readCache(String phone) {
    final stored = _storage;
    if (stored == null) return null;
    final cachedMobile = stored.getString(AppStorageKeyConst.entitlementMobile);
    if (cachedMobile != phone) return null;
    final status = stored.getString(AppStorageKeyConst.entitlementStatus);
    if (status == null || status.isEmpty) return null;
    final endsMs = stored.getInt(AppStorageKeyConst.entitlementTrialEndsAtMs);
    return EntitlementSnapshot(
      mobile: phone,
      status: status,
      planId:
          stored.getString(AppStorageKeyConst.entitlementPlanId) ??
          defaultPlanId,
      trialEndsAt: endsMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endsMs, isUtc: true),
      planTitle:
          stored.getString(AppStorageKeyConst.entitlementPlanTitle) ??
          'Creovo Billing',
      priceInr: stored.getInt(AppStorageKeyConst.entitlementPlanPriceInr) ?? 0,
      period:
          stored.getString(AppStorageKeyConst.entitlementPlanPeriod) ??
          'yearly',
    );
  }

  DateTime? _lastSeenAt() {
    final ms = _storage?.getInt(AppStorageKeyConst.entitlementLastSeenAtMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> _persist(EntitlementSnapshot snapshot, DateTime now) async {
    final stored = _storage;
    if (stored == null) return;
    await stored.setString(
      AppStorageKeyConst.entitlementMobile,
      snapshot.mobile,
    );
    await stored.setString(
      AppStorageKeyConst.entitlementStatus,
      snapshot.status,
    );
    await stored.setString(
      AppStorageKeyConst.entitlementPlanId,
      snapshot.planId,
    );
    await stored.setString(
      AppStorageKeyConst.entitlementPlanTitle,
      snapshot.planTitle,
    );
    await stored.setInt(
      AppStorageKeyConst.entitlementPlanPriceInr,
      snapshot.priceInr,
    );
    await stored.setString(
      AppStorageKeyConst.entitlementPlanPeriod,
      snapshot.period,
    );
    if (snapshot.trialEndsAt != null) {
      await stored.setInt(
        AppStorageKeyConst.entitlementTrialEndsAtMs,
        snapshot.trialEndsAt!.toUtc().millisecondsSinceEpoch,
      );
    }
    final ms = now.toUtc().millisecondsSinceEpoch;
    await stored.setInt(AppStorageKeyConst.entitlementLastCheckedAtMs, ms);
    await stored.setInt(AppStorageKeyConst.entitlementLastSeenAtMs, ms);
  }

  Future<void> _touchLastSeen() async {
    final stored = _storage;
    if (stored == null) return;
    final existing = stored.getInt(AppStorageKeyConst.entitlementLastSeenAtMs);
    if (existing == null) return;
    final now = _now.millisecondsSinceEpoch;
    if (now >= existing) {
      await stored.setInt(AppStorageKeyConst.entitlementLastSeenAtMs, now);
    }
  }

  static DateTime? _timestamp(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }
}
