import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'account_auth_service.dart';
import 'account_phone.dart';

class FirebaseAccountAuthService implements AccountAuthService {
  FirebaseAccountAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;

  @override
  bool get isVerified =>
      _auth.currentUser != null && _auth.currentUser!.phoneNumber != null;

  @override
  String? get e164Mobile => _auth.currentUser?.phoneNumber;

  @override
  Future<void> sendOtp(String phone) async {
    final e164 = phone.trim().startsWith('+')
        ? phone.trim()
        : AccountPhone.toE164(phone);
    if (AccountPhone.digitsOnly(e164).length < 8) {
      throw AccountAuthException(
        'Indian mobiles are 10 digits and start with 6, 7, 8 or 9.',
      );
    }
    final done = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          if (!done.isCompleted) done.complete();
        } catch (error) {
          if (!done.isCompleted) {
            done.completeError(_mapAuthError(error));
          }
        }
      },
      verificationFailed: (error) {
        if (!done.isCompleted) {
          done.completeError(_mapAuthError(error));
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!done.isCompleted) done.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    await done.future;
  }

  @override
  Future<void> verifyOtp(String smsCode) async {
    final code = smsCode.trim();
    if (code.length != 6) {
      throw AccountAuthException('Enter the 6-digit OTP.');
    }
    final verificationId = _verificationId;
    if (verificationId == null) {
      if (isVerified) return;
      throw AccountAuthException('Send the OTP first.');
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _auth.signInWithCredential(credential);
    } catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AccountAuthException _mapAuthError(Object error) {
    if (error is AccountAuthException) return error;
    if (error is FirebaseAuthException) {
      switch (error.code) {
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
        default:
          return AccountAuthException(
            error.message ?? 'Could not verify this number.',
          );
      }
    }
    return AccountAuthException('Could not verify this number.');
  }
}
