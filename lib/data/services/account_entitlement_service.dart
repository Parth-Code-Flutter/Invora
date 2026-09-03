import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_auth_service.dart';
import 'account_phone.dart';

class AccountEntitlementService {
  AccountEntitlementService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static const defaultPlanId = 'default';

  Future<void> syncAfterLogin(AccountAuthService auth) async {
    if (auth is SkipAccountAuthService) return;
    final phone = auth.e164Mobile;
    if (phone == null || phone.isEmpty) {
      throw AccountAuthException('Could not verify this number.');
    }
    final doc = _db.collection('entitlements').doc(AccountPhone.toDocId(phone));
    final existing = await doc.get();
    if (existing.exists) return;

    final planSnap = await _db.collection('plans').doc(defaultPlanId).get();
    if (!planSnap.exists) {
      throw AccountAuthException('Subscription plans are not set up yet.');
    }
    final days = (planSnap.data()?['trialDays'] as num?)?.toInt() ?? 90;
    final ends = DateTime.now().toUtc().add(Duration(days: days));
    await doc.set({
      'mobile': phone,
      'status': 'trial',
      'planId': defaultPlanId,
      'trialStartedAt': FieldValue.serverTimestamp(),
      'trialEndsAt': Timestamp.fromDate(ends),
      'source': 'otp',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
