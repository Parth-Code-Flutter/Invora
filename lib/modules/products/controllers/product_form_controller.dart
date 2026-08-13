import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../data/models/barcode_capture_result.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/product_form_args.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/models/product_attribute_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/unit_service.dart';
import '../../../data/services/product_settings_service.dart';

class ProductFormController extends GetxController {
  ProductFormController(
    this._repository,
    this._businessRepository,
    this.unitService,
    this.productSettings,
  );
  static const taxRates = TaxUtils.gstRateBasisPoints;

  final ProductRepository _repository;
  final BusinessRepository _businessRepository;
  final UnitService unitService;
  final ProductSettingsService productSettings;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final salePrice = TextEditingController();
  final hsnSac = TextEditingController();
  final taxRate = TextEditingController();
  final type = ItemType.product.obs;
  final selectedUnit = ''.obs;
  final selectedTaxBasisPoints = 0.obs;
  final isCustomTax = false.obs;
  final currencySymbol = '₹'.obs;
  final gstEnabled = false.obs;
  final enabledFieldKeys = <String>{}.obs;
  final customFields = <ProductCustomField>[].obs;
  final attributeControllers = <String, TextEditingController>{};
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditing = false.obs;
  ProductServiceModel? _existing;
  String _baseline = '';

  bool get hasUnsavedChanges => !isLoading.value && _snapshot() != _baseline;

  @override
  void onInit() {
    super.onInit();
    selectedUnit.value = unitService.defaultUnit;
    enabledFieldKeys.assignAll(productSettings.enabledFields);
    customFields.assignAll(productSettings.customFields);
    for (final field in attributeDefinitions) {
      attributeControllers[field.key] = TextEditingController();
    }
    _captureBaseline();
    _loadCurrency();
    _applyRouteArguments();
  }

  /// Supports both legacy integer ids and [ProductFormArgs] from the scanner.
  void _applyRouteArguments() {
    final arguments = Get.arguments;
    if (arguments is int) {
      isEditing.value = true;
      _load(arguments);
      return;
    }
    if (arguments is ProductFormArgs) {
      if (arguments.productId != null) {
        isEditing.value = true;
        _load(arguments.productId!);
      }
      final sku = arguments.initialSku?.trim();
      if (sku != null && sku.isNotEmpty) {
        _applyUnknownSku(sku);
        _captureBaseline();
      }
    }
  }

  /// Fills the form from a one-shot scan so the user can edit before saving.
  Future<void> applyCapture(BarcodeCaptureResult capture) async {
    final product = capture.product;
    if (product != null) {
      await _applyProduct(product, treatAsSaved: true);
      return;
    }
    _applyUnknownSku(capture.code);
  }

  void selectType(ItemType value) {
    type.value = value;
    if (!isEditing.value) {
      selectedUnit.value = unitService.defaultUnit;
    }
  }

  void refreshFieldSettings() {
    enabledFieldKeys.assignAll(productSettings.enabledFields);
    customFields.assignAll(productSettings.customFields);
    for (final field in attributeDefinitions) {
      attributeControllers.putIfAbsent(field.key, TextEditingController.new);
    }
  }

  bool fieldEnabled(String key) {
    if (type.value == ItemType.service &&
        const {
          'color',
          'size',
          'material',
          'weight',
          'dimensions',
          'shape',
          'batchNumber',
          'expiryDate',
        }.contains(key)) {
      return false;
    }
    return enabledFieldKeys.contains(key);
  }

  List<ProductFieldDefinition> get attributeDefinitions => [
    ...ProductFieldPresets.fields.where(
      (field) =>
          !const {'description', 'unit', 'tax', 'hsnSac'}.contains(field.key),
    ),
    ...productSettings.customFields.map(
      (field) => ProductFieldDefinition(
        field.key,
        field.label,
        number: field.type == ProductCustomFieldType.number,
      ),
    ),
  ];

  void selectTax(int? basisPoints) {
    if (basisPoints == null) {
      isCustomTax.value = true;
      if (!isEditing.value) taxRate.clear();
      return;
    }
    isCustomTax.value = false;
    selectedTaxBasisPoints.value = basisPoints;
    taxRate.text = TaxUtils.toInputValue(basisPoints);
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required.';
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Sale price is required.';
    return CurrencyUtils.parseMinor(value) == null
        ? 'Enter a valid amount with up to 2 decimal places.'
        : null;
  }

  String? validateTax(String? value) {
    return TaxUtils.parseBasisPoints(value ?? '') == null
        ? 'Enter a tax rate from 0 to 100.'
        : null;
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final saved = await _repository.save(
        ProductServiceModel(
          id: _existing?.id,
          name: name.text.trim(),
          type: type.value,
          description: _optional(description.text),
          unit: selectedUnit.value,
          salePriceMinor: CurrencyUtils.parseMinor(salePrice.text)!,
          hsnSac: _optional(hsnSac.text.toUpperCase()),
          taxRateBasisPoints: gstEnabled.value
              ? TaxUtils.parseBasisPoints(taxRate.text)!
              : 0,
          attributes: _attributeValues(),
          createdAt: _existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      _captureBaseline();
      await AppFocus.dismissKeyboard();
      Get.back<ProductServiceModel>(result: saved);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _loadCurrency() async {
    final profile = await _businessRepository.getProfile();
    currencySymbol.value = profile?.currencySymbol ?? '₹';
    gstEnabled.value = profile?.gstRegistered ?? false;
  }

  Future<void> _load(int id) async {
    isLoading.value = true;
    final item = await _repository.getById(id);
    if (item != null) {
      await _applyProduct(item, treatAsSaved: true);
    }
    isLoading.value = false;
  }

  /// Copies catalog values into the editors. [treatAsSaved] marks the form as
  /// editing that row so Save updates it instead of creating a duplicate.
  Future<void> _applyProduct(
    ProductServiceModel item, {
    required bool treatAsSaved,
  }) async {
    _existing = treatAsSaved ? item : null;
    isEditing.value = treatAsSaved && item.id != null;
    name.text = item.name;
    description.text = item.description ?? '';
    salePrice.text = CurrencyUtils.toInputValue(item.salePriceMinor);
    hsnSac.text = item.hsnSac ?? '';
    type.value = item.type;
    selectedUnit.value = await unitService.create(item.unit);
    taxRate.text = TaxUtils.toInputValue(item.taxRateBasisPoints);
    selectedTaxBasisPoints.value = item.taxRateBasisPoints;
    isCustomTax.value = !taxRates.contains(item.taxRateBasisPoints);
    for (final controller in attributeControllers.values) {
      controller.clear();
    }
    for (final attribute in item.attributes) {
      enabledFieldKeys.add(attribute.key);
      attributeControllers
              .putIfAbsent(attribute.key, TextEditingController.new)
              .text =
          attribute.value;
    }
    _captureBaseline();
  }

  void _applyUnknownSku(String code) {
    enabledFieldKeys.add('sku');
    attributeControllers.putIfAbsent('sku', TextEditingController.new).text =
        code;
  }

  String _snapshot() => [
    name.text,
    description.text,
    salePrice.text,
    hsnSac.text,
    taxRate.text,
    type.value.name,
    selectedUnit.value,
    selectedTaxBasisPoints.value.toString(),
    isCustomTax.value.toString(),
    ...attributeControllers.entries.map(
      (entry) => '${entry.key}:${entry.value.text}',
    ),
  ].join('\u001f');

  void _captureBaseline() => _baseline = _snapshot();

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void onClose() {
    name.dispose();
    description.dispose();
    salePrice.dispose();
    hsnSac.dispose();
    taxRate.dispose();
    for (final controller in attributeControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  List<ProductAttributeValue> _attributeValues() {
    final labels = {
      for (final field in attributeDefinitions) field.key: field.label,
    };
    final previous = {
      for (final value
          in _existing?.attributes ?? const <ProductAttributeValue>[])
        value.key: value,
    };
    final result = <ProductAttributeValue>[];
    for (final entry in attributeControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        result.add(
          ProductAttributeValue(
            key: entry.key,
            label: labels[entry.key] ?? previous[entry.key]?.label ?? entry.key,
            value: value,
          ),
        );
      } else if (!fieldEnabled(entry.key) && previous[entry.key] != null) {
        result.add(previous[entry.key]!);
      }
    }
    return result;
  }
}
