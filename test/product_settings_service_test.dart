import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/models/business_category_model.dart';
import 'package:creovo_invoice/data/models/product_attribute_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';
import 'package:creovo_invoice/modules/products/controllers/product_form_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'category presets are recommendations and user choices persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = ProductSettingsService(await AppStorage.create());

      await service.changeCategory(BusinessCategory.clothingFashion);
      expect(service.enabledFields, containsAll(['size', 'color', 'brand']));
      expect(service.preferredUnits, contains('pair'));

      await service.setEnabledFields({'size', 'material'});
      await service.setShowAttributesOnInvoice(false);
      await service.setCustomFields(const [
        ProductCustomField(
          key: 'custom_finish',
          label: 'Finish',
          type: ProductCustomFieldType.text,
        ),
      ]);

      expect(service.category, BusinessCategory.clothingFashion);
      expect(service.enabledFields, {'size', 'material'});
      expect(service.showAttributesOnInvoice, isFalse);
      expect(service.customFields.single.label, 'Finish');
    },
  );

  test(
    'changing category resets recommendations without touching product data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = ProductSettingsService(await AppStorage.create());

      await service.setEnabledFields({'custom_choice'});
      await service.changeCategory(BusinessCategory.medicalPharmacy);

      expect(service.enabledFields, containsAll(['batchNumber', 'expiryDate']));
      expect(service.enabledFields, isNot(contains('custom_choice')));
    },
  );

  test('item form refresh adds fields without losing typed values', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final service = ProductSettingsService(storage);
    await service.setEnabledFields({'size'});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = ProductFormController(
      ProductRepository(database),
      BusinessRepository(database),
      UnitService(storage),
      service,
    );
    controller.onInit();
    addTearDown(controller.onClose);
    controller.name.text = 'Dining table';
    controller.attributeControllers['size']!.text = '6 feet';

    await service.setCustomFields(const [
      ProductCustomField(
        key: 'custom_finish',
        label: 'Finish',
        type: ProductCustomFieldType.text,
      ),
    ]);
    await service.setEnabledFields({'size', 'custom_finish'});
    controller.refreshFieldSettings();

    expect(controller.name.text, 'Dining table');
    expect(controller.attributeControllers['size']!.text, '6 feet');
    expect(controller.attributeControllers, contains('custom_finish'));
    expect(controller.fieldEnabled('custom_finish'), isTrue);
  });
}
