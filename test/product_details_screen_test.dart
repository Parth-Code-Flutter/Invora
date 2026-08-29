import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/models/product_attribute_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/products/controllers/product_details_controller.dart';
import 'package:creovo_invoice/modules/products/screens/product_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('item details shows price, facts, and use-in-invoice action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final products = ProductRepository(database);
    final saved = await products.save(
      ProductServiceModel(
        name: 'Premium Paper',
        type: ItemType.product,
        unit: 'box',
        salePriceMinor: 125050,
        hsnSac: '4802',
        taxRateBasisPoints: 1800,
        description: 'Ivory A4 reams for invoices',
        attributes: const [
          ProductAttributeValue(key: 'color', label: 'Color', value: 'Ivory'),
        ],
        createdAt: DateTime(2026, 8, 29),
        updatedAt: DateTime(2026, 8, 29),
      ),
    );
    Get.put(
      ProductDetailsController(
        products,
        BusinessRepository(database),
        seededItemId: saved.id,
      ),
    );
    addTearDown(() async {
      Get.reset();
      await database.close();
    });

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ProductDetailsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item details'), findsOneWidget);
    expect(find.text('Premium Paper'), findsOneWidget);
    expect(find.text('₹1,250.50'), findsOneWidget);
    expect(find.text('Use in invoice'), findsOneWidget);
    expect(find.text('HSN code'), findsOneWidget);
    expect(find.text('4802'), findsOneWidget);
    expect(find.text('Ivory A4 reams for invoices'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
