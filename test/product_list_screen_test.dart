import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/products/controllers/product_list_controller.dart';
import 'package:creovo_invoice/modules/products/screens/product_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    Get.reset();
    await database.close();
  });

  testWidgets('empty catalog shows create action and type filters', (
    tester,
  ) async {
    Get.put(
      ProductListController(
        ProductRepository(database),
        BusinessRepository(database),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ProductListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your catalog is empty'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog list shows a scannable item row', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 29);
    await ProductRepository(database).save(
      ProductServiceModel(
        name: 'Premium Paper',
        type: ItemType.product,
        unit: 'box',
        salePriceMinor: 125050,
        hsnSac: '4802',
        taxRateBasisPoints: 1800,
        createdAt: now,
        updatedAt: now,
      ),
    );
    Get.put(
      ProductListController(
        ProductRepository(database),
        BusinessRepository(database),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ProductListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium Paper'), findsOneWidget);
    expect(find.text('Name · A–Z'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.textContaining('HSN 4802'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
