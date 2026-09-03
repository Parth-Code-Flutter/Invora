import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/startup_navigator.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/services/account_auth_service.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/account_phone.dart';
import '../../../data/services/device_account_numbers.dart';

class AccountOtpController extends GetxController {
  AccountOtpController(
    this._auth,
    this._entitlements, [
    this._deviceNumbers = const EmptyDeviceAccountNumbers(),
  ]);

  final AccountAuthService _auth;
  final AccountEntitlementService _entitlements;
  final DeviceAccountNumbers _deviceNumbers;

  final mobile = TextEditingController();
  final otp = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final waitingForOtp = false.obs;
  final isWorking = false.obs;
  final errorMessage = ''.obs;
  final country = AccountCountry.india.obs;
  final deviceNumbers = <DeviceAccountNumber>[].obs;

  String get formattedMobile =>
      '${country.value.e164Prefix} ${AccountPhone.nationalNumber(mobile.text, country: country.value)}';

  String get mobileHint => country.value.indianLeadingDigit
      ? '10 digits, starting with 6–9'
      : 'Mobile number';

  @override
  void onInit() {
    super.onInit();
    final e164 = _auth.e164Mobile;
    if (_auth.isVerified && e164 != null) {
      final imported = AccountPhone.parseImported(e164);
      if (imported != null) applyDeviceNumber(imported);
      waitingForOtp.value = true;
    }
    if (_entitlements.lastSyncError.isNotEmpty) {
      errorMessage.value = _entitlements.lastSyncError;
    }
  }

  @override
  void onClose() {
    mobile.dispose();
    otp.dispose();
    super.onClose();
  }

  String? validateMobile(String? value) =>
      AccountPhone.validateNational(value, country: country.value);

  void selectCountry(AccountCountry selected) {
    country.value = selected;
    if (mobile.text.trim().isNotEmpty) {
      formKey.currentState?.validate();
    }
  }

  void applyDeviceNumber(DeviceAccountNumber number) {
    country.value = number.country;
    mobile
      ..text = number.national
      ..selection = TextSelection.collapsed(offset: number.national.length);
    errorMessage.value = '';
    formKey.currentState?.validate();
  }

  Future<void> loadDeviceNumbers() async {
    try {
      final found = await _deviceNumbers.load();
      deviceNumbers.assignAll(found);
    } catch (_) {
      deviceNumbers.clear();
    }
  }

  Future<void> pickFromThisPhone() async {
    errorMessage.value = '';
    try {
      final picked = await _deviceNumbers.pickFromContacts();
      if (picked == null) {
        if (deviceNumbers.isEmpty) await loadDeviceNumbers();
        return;
      }
      applyDeviceNumber(picked);
    } on DeviceAccountNumbersException catch (error) {
      AppNotification.warning(error.title, error.message);
    }
  }

  Future<void> sendOtp() async {
    errorMessage.value = '';
    if (!(formKey.currentState?.validate() ?? false)) return;
    isWorking.value = true;
    try {
      await _auth.sendOtp(
        AccountPhone.toE164(mobile.text, country: country.value),
      );
      if (_auth.isVerified) {
        await _finish();
        return;
      }
      waitingForOtp.value = true;
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> verifyOtp() async {
    errorMessage.value = '';
    if (!_auth.isVerified) {
      final code = otp.text.trim();
      if (code.length != 6) {
        errorMessage.value = 'Enter the 6-digit OTP.';
        return;
      }
    }
    isWorking.value = true;
    try {
      if (!_auth.isVerified) {
        await _auth.verifyOtp(otp.text.trim());
      }
      await _finish();
    } on AccountAuthException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> resendOtp() async {
    otp.clear();
    await sendOtp();
  }

  Future<void> editNumber() async {
    waitingForOtp.value = false;
    otp.clear();
    errorMessage.value = '';
    if (_auth.isVerified) {
      await _auth.signOut();
    }
  }

  Future<void> _finish() async {
    await _entitlements.syncAfterLogin(_auth);
    await StartupNavigator.continueSession();
  }
}
