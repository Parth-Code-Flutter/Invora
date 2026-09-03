import 'account_phone.dart';

class AccountAuthException implements Exception {
  AccountAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

AccountAuthException mapPhoneAuthFailure({
  required String code,
  String? message,
}) {
  final detail = (message ?? '').toLowerCase();
  final regionBlocked =
      detail.contains('region') ||
      detail.contains('17006') ||
      detail.contains('sms unable to be sent');
  if (regionBlocked) {
    return AccountAuthException(
      'SMS to India is not allowed yet. In Firebase, enable Phone sign-in and allow India in SMS region policy.',
    );
  }
  switch (code) {
    case 'invalid-phone-number':
      return AccountAuthException(
        'Enter a valid mobile number for this country.',
      );
    case 'invalid-verification-code':
      return AccountAuthException('That OTP is incorrect. Try again.');
    case 'session-expired':
      return AccountAuthException('OTP expired. Send a new one.');
    case 'too-many-requests':
      return AccountAuthException(
        'Too many attempts. Wait a minute and try again.',
      );
    case 'network-request-failed':
      return AccountAuthException(
        'No internet. Connect once to verify this number.',
      );
    case 'missing-client-identifier':
      return AccountAuthException(
        'Phone OTP is not set up for this Android build yet.',
      );
    case 'operation-not-allowed':
      return AccountAuthException(
        'Phone sign-in is off. Enable Phone in Firebase Authentication → Sign-in method.',
      );
    default:
      return AccountAuthException(
        message == null || message.isEmpty
            ? 'Could not verify this number.'
            : message,
      );
  }
}

AccountAuthException mapEntitlementFailure({
  required String code,
  String? message,
}) {
  final detail = '$code ${message ?? ''}'.toLowerCase();
  final apiOff =
      detail.contains('firestore.googleapis.com') ||
      detail.contains('has not been used') ||
      detail.contains('it is disabled');
  if (apiOff ||
      code == 'unavailable' ||
      detail.contains('client is offline') ||
      detail.contains('failed to get document')) {
    return AccountAuthException(
      'Cloud Firestore is off. In Firebase, create a Firestore database for creovobilling, wait a minute, then tap Verify again.',
    );
  }
  if (code == 'permission-denied') {
    return AccountAuthException(
      'Plan storage denied this number. Deploy Firestore rules for creovobilling, then tap Verify again.',
    );
  }
  return AccountAuthException(
    message == null || message.isEmpty
        ? 'Could not start the plan for this number.'
        : message,
  );
}

abstract class AccountAuthService {
  bool get isVerified;

  String? get e164Mobile;

  Future<void> sendOtp(String phone);

  Future<void> verifyOtp(String smsCode);

  Future<void> signOut();
}

/// Used by widget tests and any run without Firebase config.
class SkipAccountAuthService implements AccountAuthService {
  SkipAccountAuthService({this.isVerified = true});

  @override
  bool isVerified;

  String? _e164;

  @override
  String? get e164Mobile => _e164;

  @override
  Future<void> sendOtp(String phone) async {
    final e164 = phone.trim().startsWith('+')
        ? phone.trim()
        : AccountPhone.toE164(phone);
    final digits = AccountPhone.digitsOnly(e164);
    if (digits.length < 8 || digits.length > 15) {
      throw AccountAuthException(
        'Indian mobiles are 10 digits and start with 6, 7, 8 or 9.',
      );
    }
    _e164 = e164;
  }

  @override
  Future<void> verifyOtp(String smsCode) async {
    final code = smsCode.trim();
    if (code.length != 6) {
      throw AccountAuthException('Enter the 6-digit OTP.');
    }
    if (_e164 == null) {
      throw AccountAuthException('Send the OTP first.');
    }
    isVerified = true;
  }

  @override
  Future<void> signOut() async {
    isVerified = false;
    _e164 = null;
  }
}

class UnconfiguredAccountAuthService implements AccountAuthService {
  @override
  bool get isVerified => false;

  @override
  String? get e164Mobile => null;

  @override
  Future<void> sendOtp(String phone) async {
    throw AccountAuthException(
      'Firebase is not configured yet. Add google-services.json and try again.',
    );
  }

  @override
  Future<void> verifyOtp(String smsCode) async {
    throw AccountAuthException(
      'Firebase is not configured yet. Add google-services.json and try again.',
    );
  }

  @override
  Future<void> signOut() async {}
}
