import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';

import '../../app/constants/app_storage_key_const.dart';
import 'app_storage.dart';

class AppLockService extends GetxService {
  AppLockService(this._storage);

  final AppStorage _storage;
  final enabled = false.obs;
  final unlocked = true.obs;

  bool get isEnabled => enabled.value;
  bool get isUnlocked => !isEnabled || unlocked.value;

  void load() {
    enabled.value =
        (_storage.getBool(AppStorageKeyConst.appLockEnabled) ?? false) &&
        _hasCredentials;
    unlocked.value = !enabled.value;
  }

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = _createSalt();
    await _storage.setString(AppStorageKeyConst.appLockPinSalt, salt);
    await _storage.setString(
      AppStorageKeyConst.appLockPinHash,
      _hash(pin, salt),
    );
    await _storage.setBool(AppStorageKeyConst.appLockEnabled, true);
    enabled.value = true;
    unlocked.value = true;
  }

  bool verifyPin(String pin) {
    if (!_hasCredentials || !RegExp(r'^\d{4}$').hasMatch(pin)) return false;
    final salt = _storage.getString(AppStorageKeyConst.appLockPinSalt)!;
    return _constantTimeEquals(
      _hash(pin, salt),
      _storage.getString(AppStorageKeyConst.appLockPinHash)!,
    );
  }

  bool unlock(String pin) {
    final valid = verifyPin(pin);
    if (valid) unlocked.value = true;
    return valid;
  }

  void lock() {
    if (enabled.value) unlocked.value = false;
  }

  Future<bool> disable(String currentPin) async {
    if (!verifyPin(currentPin)) return false;
    await _storage.remove(AppStorageKeyConst.appLockEnabled);
    await _storage.remove(AppStorageKeyConst.appLockPinHash);
    await _storage.remove(AppStorageKeyConst.appLockPinSalt);
    enabled.value = false;
    unlocked.value = true;
    return true;
  }

  bool get _hasCredentials =>
      (_storage.getString(AppStorageKeyConst.appLockPinHash)?.isNotEmpty ??
          false) &&
      (_storage.getString(AppStorageKeyConst.appLockPinSalt)?.isNotEmpty ??
          false);

  String _createSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256)));
  }

  String _hash(String pin, String salt) {
    List<int> value = utf8.encode('$salt:$pin');
    // Deliberately make offline guessing more expensive than one SHA operation.
    for (var index = 0; index < 12000; index++) {
      value = sha256.convert(value).bytes;
    }
    return base64UrlEncode(value);
  }

  bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain four digits');
    }
  }
}
