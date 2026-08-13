import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/barcode_capture_result.dart';
import 'package:creovo_invoice/data/models/invoice_item_scan_prefill.dart';
import 'package:creovo_invoice/data/models/product_attribute_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';
import 'package:creovo_invoice/modules/products/controllers/product_form_controller.dart';

ProductServiceModel _biscuit() {
  final now = DateTime(2026, 8, 13);
  return ProductServiceModel(
    id: 9,
    name: '50-50 Biscuit',
    type: ItemType.product,
    description: 'Packaged snack',
    unit: 'pcs',
    salePriceMinor: 500,
    hsnSac: '1905',
    taxRateBasisPoints: 1800,
    attributes: const [
      ProductAttributeValue(key: 'sku', label: 'SKU / Code', value: '890123'),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invoice item prefill copies catalog values for in-form editing', () {
    final prefill = InvoiceItemScanPrefill.fromProduct(_biscuit());
    expect(prefill.productId, 9);
    expect(prefill.name, '50-50 Biscuit');
    expect(prefill.quantityText, '1');
    expect(prefill.unit, 'pcs');
    expect(prefill.rateText, '5.00');
    expect(prefill.hsnSac, '1905');
    expect(prefill.taxRateBasisPoints, 1800);
    expect(prefill.description, 'Packaged snack');
  });

  test(
    'product form scan loads a catalog match into editable fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = ProductFormController(
        ProductRepository(database),
        BusinessRepository(database),
        UnitService(storage),
        ProductSettingsService(storage),
      );
      controller.onInit();
      addTearDown(controller.onClose);

      await controller.applyCapture(
        BarcodeCaptureResult(code: '890123', product: _biscuit()),
      );

      expect(controller.isEditing.value, isTrue);
      expect(controller.name.text, '50-50 Biscuit');
      expect(controller.salePrice.text, '5.00');
      expect(controller.hsnSac.text, '1905');
      expect(controller.selectedUnit.value, 'pcs');
      expect(controller.attributeControllers['sku']!.text, '890123');
    },
  );

  test('product form scan without a catalog match only fills SKU', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = ProductFormController(
      ProductRepository(database),
      BusinessRepository(database),
      UnitService(storage),
      ProductSettingsService(storage),
    );
    controller.onInit();
    addTearDown(controller.onClose);

    await controller.applyCapture(const BarcodeCaptureResult(code: '999000'));

    expect(controller.isEditing.value, isFalse);
    expect(controller.name.text, isEmpty);
    expect(controller.attributeControllers['sku']!.text, '999000');
    expect(controller.fieldEnabled('sku'), isTrue);
  });
}
