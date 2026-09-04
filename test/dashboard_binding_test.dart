import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/backup_service.dart';
import 'package:creovo_invoice/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:creovo_invoice/modules/dashboard/controllers/dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main-tab navigation reuses the loaded dashboard controller', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final storage = await AppStorage.create();
    final business = BusinessRepository(database);
    Get.put<BusinessRepository>(business);
    Get.put<InvoiceRepository>(InvoiceRepository(database));
    Get.put<PurchaseRepository>(PurchaseRepository(database));
    Get.put<BackupService>(BackupService(database, business, storage));

    DashboardBinding().dependencies();
    final first = Get.find<DashboardController>();
    DashboardBinding().dependencies();

    expect(Get.find<DashboardController>(), same(first));
    expect(Get.isRegistered<DashboardController>(), isTrue);

    await Get.delete<DashboardController>(force: true);
    Get.reset();
    await database.close();
  });
}
