import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/demo_access_service.dart';
import 'package:creovo_invoice/data/services/demo_build_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default environment config never expires', () {
    expect(DemoBuildConfig.fromEnvironment().isDemoBuild, isFalse);
    expect(DemoBuildConfig.parseDay(''), isNull);
    expect(DemoBuildConfig.parseDay('26-08-2026'), isNull);
  });

  test('empty demo config keeps the app unlocked', () async {
    final service = DemoAccessService(
      config: const DemoBuildConfig(),
      storage: await AppStorage.create(),
      clock: () => DateTime(2030, 1, 1),
    );
    expect(service.evaluate(), isFalse);
    expect(service.isExpired, isFalse);
  });

  test('locks after the inclusive expiry calendar day', () async {
    final storage = await AppStorage.create();
    final config = DemoBuildConfig(
      expiresAt: DateTime(2026, 8, 26),
      buildTime: DateTime(2026, 8, 19),
      clientName: 'Sharma Traders',
    );
    final onExpiryDay = DemoAccessService(
      config: config,
      storage: storage,
      clock: () => DateTime(2026, 8, 26, 23, 50),
    );
    expect(onExpiryDay.evaluate(), isFalse);

    final afterExpiry = DemoAccessService(
      config: config,
      storage: storage,
      clock: () => DateTime(2026, 8, 27),
    );
    expect(afterExpiry.evaluate(), isTrue);
    expect(afterExpiry.lockTitle, 'Please contact your sales person');
    expect(afterExpiry.lockMessage, contains('Sharma Traders'));
  });

  test(
    'locks when the device clock is before the baked-in build day',
    () async {
      final service = DemoAccessService(
        config: DemoBuildConfig(
          expiresAt: DateTime(2026, 8, 26),
          buildTime: DateTime(2026, 8, 19),
        ),
        storage: await AppStorage.create(),
        clock: () => DateTime(2026, 8, 18),
      );
      expect(service.evaluate(), isTrue);
    },
  );

  test('locks when the device clock moves before last seen day', () async {
    final storage = await AppStorage.create();
    await storage.setString(AppStorageKeyConst.demoLastSeenDay, '2026-08-22');
    final service = DemoAccessService(
      config: DemoBuildConfig(
        expiresAt: DateTime(2026, 8, 26),
        buildTime: DateTime(2026, 8, 19),
      ),
      storage: storage,
      clock: () => DateTime(2026, 8, 20),
    );
    expect(service.evaluate(), isTrue);
  });

  test('records last seen only while the demo is still valid', () async {
    final storage = await AppStorage.create();
    final service = DemoAccessService(
      config: DemoBuildConfig(
        expiresAt: DateTime(2026, 8, 26),
        buildTime: DateTime(2026, 8, 19),
      ),
      storage: storage,
      clock: () => DateTime(2026, 8, 21),
    );
    expect(service.evaluate(), isFalse);
    expect(storage.getString(AppStorageKeyConst.demoLastSeenDay), '2026-08-21');
  });
}
