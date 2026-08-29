import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/models/product_attribute_model.dart';
import '../../../data/services/product_settings_service.dart';
import '../../../data/services/stock_ledger.dart';

class ProductSettingsController extends GetxController {
  ProductSettingsController(this._service, [this._ledger]);
  final ProductSettingsService _service;
  final StockLedger? _ledger;
  final category = BusinessCategory.generalBusiness.obs;
  final enabledFields = <String>{}.obs;
  final customFields = <ProductCustomField>[].obs;
  final showOnInvoice = true.obs;
  final stockEnabled = false.obs;
  final canTrackStock = false.obs;

  @override
  void onInit() {
    super.onInit();
    _reload();
    reloadStock();
  }

  void _reload() {
    category.value = _service.category;
    enabledFields.assignAll(_service.enabledFields);
    customFields.assignAll(_service.customFields);
    showOnInvoice.value = _service.showAttributesOnInvoice;
  }

  Future<void> reloadStock() async {
    canTrackStock.value = _ledger != null;
    stockEnabled.value = _ledger != null && await _ledger.isEnabled();
  }

  Future<void> disableStock() async {
    await _ledger?.disable();
    stockEnabled.value = false;
    AppNotification.success(
      'Stock tracking off',
      'Stock screens are hidden. Saved movements stay on this device.',
    );
  }

  Future<void> changeCategory(BusinessCategory value) async {
    await _service.changeCategory(value);
    _reload();
    AppNotification.success(
      'Business category updated',
      'Recommended fields changed. Existing product information was not deleted.',
    );
  }

  Future<void> toggleField(String key, bool enabled) async {
    final values = {...enabledFields};
    enabled ? values.add(key) : values.remove(key);
    enabledFields.assignAll(values);
    await _service.setEnabledFields(values);
  }

  Future<void> setShowOnInvoice(bool value) async {
    showOnInvoice.value = value;
    await _service.setShowAttributesOnInvoice(value);
  }

  Future<String?> addCustomField(
    String label,
    ProductCustomFieldType type,
  ) async {
    final normalized = label.trim();
    if (normalized.isEmpty) return 'Enter a field name.';
    final key =
        'custom_${normalized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
    if (customFields.any((value) => value.key == key)) {
      return 'This field already exists.';
    }
    final updated = [
      ...customFields,
      ProductCustomField(key: key, label: normalized, type: type),
    ];
    customFields.assignAll(updated);
    enabledFields.add(key);
    await Future.wait([
      _service.setCustomFields(updated),
      _service.setEnabledFields(enabledFields),
    ]);
    return null;
  }

  Future<void> deleteCustomField(ProductCustomField field) async {
    final updated = customFields
        .where((value) => value.key != field.key)
        .toList();
    customFields.assignAll(updated);
    enabledFields.remove(field.key);
    await Future.wait([
      _service.setCustomFields(updated),
      _service.setEnabledFields(enabledFields),
    ]);
  }
}
