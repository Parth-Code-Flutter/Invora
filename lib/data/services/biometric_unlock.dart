import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Device biometrics used as an optional app-lock unlock method.
///
/// Inject a fake in tests so widget and service suites never open the system
/// fingerprint or Face ID prompt.
abstract class BiometricUnlock {
  Future<bool> isAvailable();

  Future<bool> authenticate({required String reason});
}

class DeviceBiometricUnlock implements BiometricUnlock {
  DeviceBiometricUnlock({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
