import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/modules/documents/screens/documents_screen.dart';
import 'package:creovo_invoice/modules/invoices/controllers/invoice_list_controller.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('documents host keeps sales and purchases on separate tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put(storage);
    Get.put(BusinessRepository(database));
    Get.put(InvoiceRepository(database));
    Get.put(PurchaseRepository(database));
    Get.put(InvoiceListController(Get.find(), Get.find()));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      Get.reset();
      await database.close();
    });

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const DocumentsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Purchases'), findsOneWidget);
    expect(find.text('Invoices'), findsWidgets);

    await tester.tap(find.text('Purchases'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Purchase bills'), findsWidgets);
    expect(storage.getString(AppStorageKeyConst.documentsTab), 'purchases');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
