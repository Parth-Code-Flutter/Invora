import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/stock_ledger.dart';
import 'package:creovo_invoice/data/services/stock_report_service.dart';
import 'package:creovo_invoice/modules/reports/controllers/stock_report_controller.dart';
import 'package:creovo_invoice/modules/reports/screens/stock_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stock reports ask to enable tracking when off', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = Get.put(
      StockReportController(
        StockReportService(StockLedger(database), ProductRepository(database)),
      ),
    );
    addTearDown(() async {
      Get.reset();
      await database.close();
    });
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await controller.reload();
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const StockReportScreen()),
    );
    await tester.pump();

    expect(find.text('Stock reports'), findsOneWidget);
    expect(find.text('Stock tracking off'), findsOneWidget);
    expect(
      find.text('Keep stock for a product to use these reports.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock reports list on-hand after tracking is on', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final ledger = StockLedger(database);
    final products = ProductRepository(database);
    final product = await products.save(
      ProductServiceModel(
        name: 'Teak board',
        type: ItemType.product,
        unit: 'pcs',
        salePriceMinor: 10000,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    await ledger.enable(
      openingAsOf: DateTime(2026, 8, 1),
      openingQtyByProduct: {product.id!: 7000},
    );
    final controller = Get.put(
      StockReportController(StockReportService(ledger, products)),
    );
    addTearDown(() async {
      Get.reset();
      await database.close();
    });
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await controller.reload();
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const StockReportScreen()),
    );
    await tester.pump();

    expect(find.text('Teak board'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('On hand as of'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
