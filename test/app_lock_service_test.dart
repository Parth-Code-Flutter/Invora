import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/services/app_lock_service.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/biometric_unlock.dart';
import 'package:creovo_invoice/modules/settings/screens/app_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBiometricUnlock implements BiometricUnlock {
  _FakeBiometricUnlock({this.available = true});

  bool available;
  var succeeds = true;
  var authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls += 1;
    return succeeds;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  test(
    'sets, verifies, locks, unlocks and disables a four-digit PIN',
    () async {
      final storage = await AppStorage.create();
      final service = AppLockService(storage)..load();

      expect(service.isEnabled, isFalse);
      await service.setPin('2580');

      expect(service.isEnabled, isTrue);
      expect(service.verifyPin('2580'), isTrue);
      expect(service.verifyPin('1111'), isFalse);
      expect(
        storage.getString(AppStorageKeyConst.appLockPinHash),
        isNot(contains('2580')),
      );

      service.lock();
      expect(service.isUnlocked, isFalse);
      expect(service.unlock('1111'), isFalse);
      expect(service.unlock('2580'), isTrue);
      expect(await service.disable('1111'), isFalse);
      expect(await service.disable('2580'), isTrue);
      expect(service.isEnabled, isFalse);
    },
  );

  test('restores enabled lock in a locked state', () async {
    final storage = await AppStorage.create();
    await (AppLockService(storage)..load()).setPin('1234');

    final restored = AppLockService(storage)..load();

    expect(restored.isEnabled, isTrue);
    expect(restored.isUnlocked, isFalse);
    expect(restored.unlock('1234'), isTrue);
  });

  test('enables fingerprint after a successful biometric check', () async {
    final storage = await AppStorage.create();
    final biometric = _FakeBiometricUnlock();
    final service = AppLockService(storage, biometric: biometric)..load();
    await service.setPin('1234');

    expect(
      await service.enableBiometric(reason: 'Confirm fingerprint'),
      isTrue,
    );
    expect(service.isBiometricEnabled, isTrue);
    expect(storage.getBool(AppStorageKeyConst.appLockBiometricEnabled), isTrue);
    expect(biometric.authenticateCalls, 1);

    service.lock();
    expect(service.isUnlocked, isFalse);
    expect(await service.unlockWithBiometrics(reason: 'Unlock'), isTrue);
    expect(service.isUnlocked, isTrue);
    expect(service.unlock('1234'), isTrue);

    expect(await service.disable('1234'), isTrue);
    expect(service.isBiometricEnabled, isFalse);
    expect(storage.getBool(AppStorageKeyConst.appLockBiometricEnabled), isNull);
  });

  test('does not enable fingerprint when hardware is unavailable', () async {
    final storage = await AppStorage.create();
    final service = AppLockService(
      storage,
      biometric: _FakeBiometricUnlock(available: false),
    )..load();
    await service.setPin('1234');

    expect(
      await service.enableBiometric(reason: 'Confirm fingerprint'),
      isFalse,
    );
    expect(service.isBiometricEnabled, isFalse);
  });

  test('restores fingerprint preference with the lock still closed', () async {
    final storage = await AppStorage.create();
    final biometric = _FakeBiometricUnlock();
    final original = AppLockService(storage, biometric: biometric)..load();
    await original.setPin('1234');
    await original.enableBiometric(reason: 'Confirm fingerprint');

    final restored = AppLockService(storage, biometric: biometric)..load();
    expect(restored.isEnabled, isTrue);
    expect(restored.isBiometricEnabled, isTrue);
    expect(restored.isUnlocked, isFalse);
  });

  test('skips one background lock after a fingerprint prompt', () async {
    final storage = await AppStorage.create();
    final service = AppLockService(storage, biometric: _FakeBiometricUnlock())
      ..load();
    await service.setPin('1234');
    await service.enableBiometric(reason: 'Confirm fingerprint');

    service.lockFromBackground();
    expect(service.isUnlocked, isTrue);
    service.lock();
    expect(service.isUnlocked, isFalse);
  });

  testWidgets('settings overview offers PIN and fingerprint options', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final service = AppLockService(storage, biometric: _FakeBiometricUnlock())
      ..load();
    Get.put<AppLockService>(service);
    await tester.pumpWidget(
      const GetMaterialApp(home: AppLockSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PIN'), findsOneWidget);
    expect(find.text('Fingerprint'), findsOneWidget);
  });

  testWidgets('settings flow confirms and enables a new PIN', (tester) async {
    final storage = await AppStorage.create();
    final service = AppLockService(storage)..load();
    Get.put<AppLockService>(service);
    await tester.pumpWidget(
      const GetMaterialApp(home: AppLockSettingsScreen()),
    );

    await tester.tap(find.text('PIN'));
    await tester.pumpAndSettle();
    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.text(digit));
    }
    await tester.pumpAndSettle();
    expect(find.text('Confirm PIN'), findsOneWidget);

    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.text(digit));
    }
    await tester.pumpAndSettle();

    expect(service.isEnabled, isTrue);
    expect(service.isBiometricEnabled, isFalse);
    expect(find.text('App lock is on'), findsOneWidget);
  });

  testWidgets('fingerprint option sets PIN then enables biometrics', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final biometric = _FakeBiometricUnlock();
    final service = AppLockService(storage, biometric: biometric)..load();
    Get.put<AppLockService>(service);
    await tester.pumpWidget(
      const GetMaterialApp(home: AppLockSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fingerprint'));
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
    }
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
    }
    await tester.pumpAndSettle();

    expect(service.isEnabled, isTrue);
    expect(service.isBiometricEnabled, isTrue);
    expect(biometric.authenticateCalls, 1);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('fingerprint option explains when hardware is missing', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final service = AppLockService(
      storage,
      biometric: _FakeBiometricUnlock(available: false),
    )..load();
    Get.put<AppLockService>(service);
    await tester.pumpWidget(
      const GetMaterialApp(home: AppLockSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fingerprint'));
    await tester.pump();

    expect(
      find.text('Fingerprint is not available on this device.'),
      findsOneWidget,
    );
    expect(service.isEnabled, isFalse);
  });

  testWidgets('locked cold start renders above the navigator without errors', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final service = AppLockService(storage)..load();
    await service.setPin('1234');
    service.lock();
    Get.put<AppLockService>(service);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppLockGate(
          service: service,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Delete digit',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fingerprint unlocks the cold-start gate', (tester) async {
    final storage = await AppStorage.create();
    final biometric = _FakeBiometricUnlock();
    final service = AppLockService(storage, biometric: biometric)..load();
    await service.setPin('1234');
    await service.enableBiometric(reason: 'Confirm fingerprint');
    service.lock();
    Get.put<AppLockService>(service);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppLockGate(
          service: service,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.isUnlocked, isTrue);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('fingerprint keypad remains when biometric unlock is declined', (
    tester,
  ) async {
    final storage = await AppStorage.create();
    final biometric = _FakeBiometricUnlock();
    final service = AppLockService(storage, biometric: biometric)..load();
    await service.setPin('1234');
    await service.enableBiometric(reason: 'Confirm fingerprint');
    biometric.succeeds = false;
    service.lock();
    Get.put<AppLockService>(service);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppLockGate(
          service: service,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.isUnlocked, isFalse);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Use fingerprint',
      ),
      findsOneWidget,
    );
    expect(service.unlock('1234'), isTrue);
  });
}
