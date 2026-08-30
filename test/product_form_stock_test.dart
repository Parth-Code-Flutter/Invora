import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/barcode_capture_result.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/data/services/stock_ledger.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';
import 'package:creovo_invoice/modules/products/controllers/product_form_controller.dart';
import 'package:creovo_invoice/modules/products/screens/product_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    Get.reset();
    await database.close();
  });

  Future<ProductFormController> createController() async {
    final storage = await AppStorage.create();
    return ProductFormController(
      ProductRepository(database),
      BusinessRepository(database),
      UnitService(storage),
      ProductSettingsService(storage),
      StockLedger(database),
    );
  }

  test('new products default Keep stock on and services never track', () async {
    final controller = await createController();
    controller.onInit();
    addTearDown(controller.onClose);
    expect(controller.trackStock.value, isTrue);
    expect(controller.showStockCard, isTrue);
    expect(controller.showQtyField, isTrue);

    controller.selectType(ItemType.service);
    expect(controller.trackStock.value, isFalse);
    expect(controller.showStockCard, isFalse);
    expect(controller.showQtyField, isFalse);
  });

  testWidgets(
    'Add item shows Keep stock for products and hides it for services',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Get.put(await createController());
      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.light, home: const ProductFormScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Cover'), findsOneWidget);
      expect(find.text('Keep stock for this item'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('SKU / Code'), findsOneWidget);
      expect(find.byTooltip('Scan barcode'), findsOneWidget);

      await tester.tap(find.text('Service'));
      await tester.pumpAndSettle();
      expect(find.text('Keep stock for this item'), findsNothing);
      expect(find.text('Quantity'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edit keeps the quantity field when Keep stock is on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final products = ProductRepository(database);
    final saved = await products.save(
      ProductServiceModel(
        name: '10 Inch MDF',
        type: ItemType.product,
        unit: 'pcs',
        salePriceMinor: 14000,
        trackStock: true,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    await StockLedger(database).setProductTracked(
      productId: saved.id!,
      tracked: true,
      openingQtyScaled: 5000,
    );
    final controller = await createController();
    Get.put(controller);
    await controller.applyCapture(
      BarcodeCaptureResult(code: 'mdf', product: saved),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ProductFormScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keep stock for this item'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(controller.openingQty.text, '5');
    expect(tester.takeException(), isNull);
  });
}
