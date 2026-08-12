import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/models/business_category_model.dart';
import 'package:creovo_invoice/data/models/product_attribute_model.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';

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
}
