import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/bindings/initial_binding.dart';
import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/modules/invoices/controllers/invoice_list_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rebinds database services after restore without restarting', () async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.restoreCompleted: true,
    });
    final storage = await AppStorage.create();
    final originalDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    final originalRuntime = LocalDatabaseService(originalDatabase);
    await originalRuntime.initialize();
    InitialBinding(storage, originalRuntime).dependencies();
    final originalRepository = Get.find<BusinessRepository>();
    Get.put(InvoiceListController(Get.find(), Get.find()), permanent: true);

    // BackupService closes the live connection before replacing its file.
    await originalDatabase.close();
    final replacementDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    await InitialBinding.reloadDatabaseRuntime(
      storage,
      replacement: LocalDatabaseService(replacementDatabase),
    );

    expect(Get.find<AppDatabase>(), same(replacementDatabase));
    expect(Get.find<BusinessRepository>(), isNot(same(originalRepository)));
    expect(Get.isRegistered<InvoiceListController>(), isFalse);
    expect(
      await Get.find<AppDatabase>().customSelect('SELECT 1').getSingle(),
      isNotNull,
    );
    expect(storage.getBool(AppStorageKeyConst.restoreCompleted), isNull);

    await Get.delete<LocalDatabaseService>(force: true);
    await Get.delete<AppDatabase>(force: true);
    Get.reset();
  });
}
