import 'account_phone.dart';

class AccountAuthException implements Exception {
  AccountAuthException(this.message);

  final String message;

  @override
  String toString() => message;
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
