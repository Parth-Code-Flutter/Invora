import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/routes/startup_navigator.dart';
import 'package:creovo_invoice/data/services/account_auth_service.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';

class _LeftoverPhoneAuth implements AccountAuthService {
  @override
  bool isVerified = true;

  @override
  String? e164Mobile = '+919876543210';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'fresh install signs out a leftover phone session from Keychain',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final account = _LeftoverPhoneAuth();

      await StartupNavigator.forgetAuthFromPreviousInstall(account, storage);

      expect(account.isVerified, isFalse);
      expect(account.e164Mobile, isNull);
      expect(
        storage.getBool(AppStorageKeyConst.accountSessionBoundToInstall),
        isTrue,
      );
    },
  );

  test(
    'later launches on the same install keep the verified session',
    () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeyConst.accountSessionBoundToInstall: true,
      });
      final storage = await AppStorage.create();
      final account = _LeftoverPhoneAuth();

      await StartupNavigator.forgetAuthFromPreviousInstall(account, storage);

      expect(account.isVerified, isTrue);
      expect(account.e164Mobile, '+919876543210');
    },
  );

  test('app update with an existing shop keeps the verified session', () async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.onboardingCompleted: true,
      AppStorageKeyConst.businessSetupCompleted: true,
    });
    final storage = await AppStorage.create();
    final account = _LeftoverPhoneAuth();

    await StartupNavigator.forgetAuthFromPreviousInstall(account, storage);

    expect(account.isVerified, isTrue);
    expect(account.e164Mobile, '+919876543210');
    expect(
      storage.getBool(AppStorageKeyConst.accountSessionBoundToInstall),
      isTrue,
    );
  });

  test(
    'widget-test SkipAccountAuth is not signed out on first launch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final account = SkipAccountAuthService(isVerified: true);

      await StartupNavigator.forgetAuthFromPreviousInstall(account, storage);

      expect(account.isVerified, isTrue);
      expect(
        storage.getBool(AppStorageKeyConst.accountSessionBoundToInstall),
        isNull,
      );
    },
  );
}
