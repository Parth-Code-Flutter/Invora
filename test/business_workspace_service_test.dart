import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/business_workspace_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('existing users default safely to sales', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BusinessWorkspaceService(await AppStorage.create());

    expect(service.defaultWorkspace.value, BusinessWorkspace.sales);
    expect(service.activeWorkspace.value, BusinessWorkspace.sales);
  });

  test('initial choice and later switching persist independently', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final service = BusinessWorkspaceService(storage);

    await service.setInitial(BusinessWorkspace.purchases);
    expect(service.isPurchases, isTrue);
    expect(
      storage.getString(AppStorageKeyConst.defaultWorkspace),
      BusinessWorkspace.purchases.name,
    );

    await service.select(BusinessWorkspace.sales);
    expect(service.isSales, isTrue);
    expect(
      storage.getString(AppStorageKeyConst.defaultWorkspace),
      BusinessWorkspace.purchases.name,
    );

    final restored = BusinessWorkspaceService(storage);
    expect(restored.defaultWorkspace.value, BusinessWorkspace.purchases);
    expect(restored.activeWorkspace.value, BusinessWorkspace.sales);
  });
}
