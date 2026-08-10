import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manages units and keeps a valid default', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UnitService(await AppStorage.create());

    expect(service.defaultUnit, 'pcs');
    await service.setDefault('kg');
    expect(service.defaultUnit, 'kg');

    await service.rename('kg', 'kilogram');
    expect(service.units, contains('kilogram'));
    expect(service.defaultUnit, 'kilogram');

    await service.delete('kilogram');
    expect(service.units, isNot(contains('kilogram')));
    expect(service.units, contains(service.defaultUnit));

    expect(await service.create(' bundle '), 'bundle');
    expect(await service.create('BUNDLE'), 'bundle');
    expect(service.units, contains('bundle'));
    expect(
      service.units.where((unit) => unit.toLowerCase() == 'bundle'),
      hasLength(1),
    );
  });
}
