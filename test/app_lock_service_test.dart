import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/services/app_lock_service.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/modules/settings/screens/app_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('settings flow confirms and enables a new PIN', (tester) async {
    final storage = await AppStorage.create();
    final service = AppLockService(storage)..load();
    Get.put<AppLockService>(service);
    await tester.pumpWidget(
      const GetMaterialApp(home: AppLockSettingsScreen()),
    );

    await tester.tap(find.text('Set up PIN'));
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
    expect(find.text('App lock is on'), findsOneWidget);
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
}
