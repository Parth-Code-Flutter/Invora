import 'dart:convert';

import '../../app/constants/app_storage_key_const.dart';
import '../models/business_category_model.dart';
import '../models/product_attribute_model.dart';
import 'app_storage.dart';

class ProductSettingsService {
  ProductSettingsService(this._storage);
  final AppStorage _storage;

  BusinessCategory get category => BusinessCategory.values.firstWhere(
    (value) =>
        value.name == _storage.getString(AppStorageKeyConst.businessCategory),
    orElse: () => BusinessCategory.generalBusiness,
  );

  Set<String> get enabledFields {
    final stored = _storage.getStringList(
      AppStorageKeyConst.enabledProductFields,
    );
    return stored == null
        ? {...ProductFieldPresets.presets[category]!.enabledFields}
        : stored.toSet();
  }

  List<String> get preferredUnits =>
      _storage.getStringList(AppStorageKeyConst.preferredUnits) ??
      ProductFieldPresets.presets[category]!.recommendedUnits;

  bool get showAttributesOnInvoice =>
      _storage.getBool(AppStorageKeyConst.showProductAttributesOnInvoice) ??
      true;

  List<ProductCustomField> get customFields {
    final raw = _storage.getString(AppStorageKeyConst.customProductFields);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map(
            (value) =>
                ProductCustomField.fromJson(Map<String, dynamic>.from(value)),
          )
          .where((value) => value.key.isNotEmpty && value.label.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> changeCategory(BusinessCategory value) async {
    final preset = ProductFieldPresets.presets[value]!;
    await Future.wait([
      _storage.setString(AppStorageKeyConst.businessCategory, value.name),
      _storage.setStringList(
        AppStorageKeyConst.enabledProductFields,
        preset.enabledFields.toList(),
      ),
      _storage.setStringList(
        AppStorageKeyConst.preferredUnits,
        preset.recommendedUnits,
      ),
    ]);
  }

  Future<void> setEnabledFields(Set<String> values) => _storage.setStringList(
    AppStorageKeyConst.enabledProductFields,
    values.toList(),
  );

  Future<void> setCustomFields(List<ProductCustomField> values) =>
      _storage.setString(
        AppStorageKeyConst.customProductFields,
        jsonEncode(values.map((value) => value.toJson()).toList()),
      );

  Future<void> setShowAttributesOnInvoice(bool value) => _storage.setBool(
    AppStorageKeyConst.showProductAttributesOnInvoice,
    value,
  );
}
