import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_auth_service.dart';
import 'account_phone.dart';

class AccountEntitlementService {
  AccountEntitlementService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static const defaultPlanId = 'default';
  static const _serverGet = GetOptions(source: Source.server);
  static const _timeout = Duration(seconds: 20);

  String lastSyncError = '';

  Future<void> syncAfterLogin(AccountAuthService auth) async {
    if (auth is SkipAccountAuthService) {
      lastSyncError = '';
      return;
    }
    final phone = auth.e164Mobile;
    if (phone == null || phone.isEmpty) {
      throw AccountAuthException('Could not verify this number.');
    }
    try {
      final doc = _db
          .collection('entitlements')
          .doc(AccountPhone.toDocId(phone));
      final existing = await doc.get(_serverGet).timeout(_timeout);
      if (existing.exists) {
        lastSyncError = '';
        return;
      }

      final planSnap = await _db
          .collection('plans')
          .doc(defaultPlanId)
          .get(_serverGet)
          .timeout(_timeout);
      if (!planSnap.exists) {
        throw AccountAuthException('Subscription plans are not set up yet.');
      }
      final days = (planSnap.data()?['trialDays'] as num?)?.toInt() ?? 90;
      final ends = DateTime.now().toUtc().add(Duration(days: days));
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
      lastSyncError = '';
    } on AccountAuthException catch (error) {
      lastSyncError = error.message;
      rethrow;
    } on FirebaseException catch (error) {
      final mapped = mapEntitlementFailure(
        code: error.code,
        message: error.message,
      );
      lastSyncError = mapped.message;
      throw mapped;
    } on TimeoutException {
      final mapped = mapEntitlementFailure(
        code: 'unavailable',
        message: 'Failed to get document because the client is offline.',
      );
      lastSyncError = mapped.message;
      throw mapped;
    } catch (error) {
      final mapped = mapEntitlementFailure(code: '', message: error.toString());
      lastSyncError = mapped.message;
      throw mapped;
    }
  }
}
