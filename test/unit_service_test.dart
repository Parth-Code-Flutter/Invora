import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores custom units and avoids case-insensitive duplicates', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UnitService(await AppStorage.create());

    expect(service.units, containsAll(['pcs', 'kg', 'service']));
    expect(await service.create(' bundle '), 'bundle');
    expect(await service.create('BUNDLE'), 'bundle');
    expect(service.units.where((unit) => unit == 'bundle'), hasLength(1));
  });
}
