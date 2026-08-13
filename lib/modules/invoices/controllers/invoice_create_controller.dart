import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/invoice_calculation_service.dart';
import '../../../data/services/invoice_defaults_service.dart';
import '../../../data/services/invoice_validation_service.dart';

class InvoiceCreateController extends GetxController {
  InvoiceCreateController(
    this._invoices,
    this._business,
    this._customers,
    this._products,
    this._calculator, {
    this.defaults,
    this.documentType = DocumentType.invoice,
  });

  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final CustomerRepository _customers;
  final ProductRepository _products;
  final InvoiceCalculationService _calculator;
  final InvoiceDefaultsService? defaults;
  static const _validator = InvoiceValidationService();
  final DocumentType documentType;
  bool get isQuotation => documentType == DocumentType.quotation;
  bool get isEditing => _id != null;
  bool get hasRecordedPayments =>
      isEditing && (calculation.value?.paidAmountMinor ?? 0) > 0;
  bool get shouldPromptForCustomer => _id == null && customer.value == null;

  final invoiceNumber = ''.obs;
  final customer = Rxn<CustomerSnapshotModel>();
  final items = <InvoiceItemModel>[].obs;
  final charges = <InvoiceChargeModel>[].obs;
  final taxType = TaxType.cgstSgst.obs;
  final invoiceDiscount = const DiscountInput.none().obs;
  final invoiceDate = DateTime.now().obs;
  final dueDate = Rxn<DateTime>();
  final calculation = Rxn<InvoiceCalculationResult>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final showMoreOptions = false.obs;
  final currencySymbol = '₹'.obs;
  final notesController = TextEditingController();
  final termsController = TextEditingController();
  final paidController = TextEditingController();
  int? _id;
  DateTime _createdAt = DateTime.now();
  InvoiceStatus _originalStatus = InvoiceStatus.draft;
  var _counter = 0;
  String _baseline = '';
  bool _dueDateUsesDefault = false;

  bool get hasUnsavedChanges => !isLoading.value && _snapshot() != _baseline;

  @override
  void onInit() {
    super.onInit();
    paidController.addListener(recalculate);
    _initialize();
  }

  @override
  void onClose() {
    paidController.dispose();
    notesController.dispose();
    termsController.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    final profile = await _business.getProfile();
    currencySymbol.value = profile?.currencySymbol ?? '₹';
    final arguments = Get.arguments;
    final argumentId = arguments is int
        ? arguments
        : arguments is InvoiceEditorArgs
        ? arguments.invoiceId
        : null;
    final saved = argumentId == null
        ? null
        : await _invoices.getById(argumentId);
    if (saved != null) {
      _restore(saved);
      AppNotification.info('Draft restored', saved.invoiceNumber);
    } else {
      taxType.value = defaults?.taxType ?? TaxType.cgstSgst;
      dueDate.value = invoiceDate.value.add(
        Duration(days: defaults?.dueDays ?? 0),
      );
      _dueDateUsesDefault = true;
      notesController.text = defaults?.notes ?? '';
      termsController.text = defaults?.terms ?? '';
      invoiceNumber.value = await _invoices.nextInvoiceNumber(
        prefix: isQuotation ? 'QTN' : profile?.invoicePrefix ?? 'INV',
        startingNumber: isQuotation ? 1 : profile?.startingInvoiceNumber ?? 1,
      );
      recalculate();
      if (arguments is InvoiceEditorArgs) {
        if (arguments.customerId != null) {
          final selected = await _customers.getById(arguments.customerId!);
          if (selected != null) selectCustomer(selected);
        }
        if (arguments.productId != null) {
          final selected = await _products.getById(arguments.productId!);
          if (selected != null) addProduct(selected);
        }
      }
    }
    _captureBaseline();
    isLoading.value = false;
  }

  Future<List<CustomerModel>> customers() => _customers.watchCustomers().first;

  void setInvoiceDate(DateTime value) {
    invoiceDate.value = value;
    if (_dueDateUsesDefault) {
      dueDate.value = value.add(Duration(days: defaults?.dueDays ?? 0));
    }
  }

  void setDueDate(DateTime value) {
    dueDate.value = value;
    _dueDateUsesDefault = false;
  }

  void selectCustomer(CustomerModel value) {
    customer.value = CustomerSnapshotModel.fromCustomer(value);
  }

  void addProduct(ProductServiceModel product) {
    _addOrIncrementProduct(product);
    recalculate();
  }

  void addProducts(Iterable<ProductServiceModel> products) {
    for (final product in products) {
      _addOrIncrementProduct(product);
    }
    recalculate();
  }

  void applyCatalogSelection({
    required Iterable<ProductServiceModel> added,
    required Set<int> removedProductIds,
  }) {
    if (removedProductIds.isNotEmpty) {
      items.removeWhere(
        (item) =>
            item.productId != null &&
            removedProductIds.contains(item.productId),
      );
    }
    for (final product in added) {
      _addOrIncrementProduct(product);
    }
    recalculate();
  }

  void _addOrIncrementProduct(ProductServiceModel product) {
    final existingIndex = items.indexWhere(
      (item) => product.id != null && item.productId != null
          ? item.productId == product.id
          : item.name.trim().toLowerCase() ==
                    product.name.trim().toLowerCase() &&
                item.unit == product.unit &&
                item.rateMinor == product.salePriceMinor,
    );
    if (existingIndex >= 0) {
      final item = items[existingIndex];
      items[existingIndex] = _withQuantity(item, item.quantityScaled + 1000);
      return;
    }
    items.add(
      InvoiceItemModel(
        localId: 'new-${_counter++}',
        productId: product.id,
        name: product.name,
        description: product.description,
        quantityScaled: 1000,
        unit: product.unit,
        rateMinor: product.salePriceMinor,
        hsnSac: product.hsnSac,
        taxRateBasisPoints: product.taxRateBasisPoints,
        attributes: product.attributes,
      ),
    );
  }

  void addItem(InvoiceItemModel item) {
    items.add(item);
    recalculate();
  }

  void replaceItem(int index, InvoiceItemModel item) {
    items[index] = item;
    recalculate();
  }

  /// Updates only the invoice snapshot. The linked catalog product is never
  /// written, so customer-specific pricing stays local to this invoice.
  void updateItemRate(int index, int rateMinor) {
    final item = items[index];
    items[index] = InvoiceItemModel(
      id: item.id,
      localId: item.localId,
      productId: item.productId,
      name: item.name,
      description: item.description,
      quantityScaled: item.quantityScaled,
      unit: item.unit,
      rateMinor: rateMinor,
      hsnSac: item.hsnSac,
      taxRateBasisPoints: item.taxRateBasisPoints,
      discount: item.discount,
      attributes: item.attributes,
    );
    recalculate();
  }

  void incrementQuantity(int index) {
    final item = items[index];
    items[index] = _withQuantity(item, item.quantityScaled + 1000);
    recalculate();
  }

  void decrementQuantity(int index) {
    final item = items[index];
    if (item.quantityScaled <= 1000) return;
    items[index] = _withQuantity(item, item.quantityScaled - 1000);
    recalculate();
  }

  void updateItemQuantity(int index, int quantityScaled) {
    if (index < 0 || index >= items.length || quantityScaled <= 0) return;
    items[index] = _withQuantity(items[index], quantityScaled);
    recalculate();
  }

  void duplicateItem(int index) {
    final item = items[index];
    items.insert(
      index + 1,
      InvoiceItemModel(
        localId: 'copy-${_counter++}',
        productId: item.productId,
        name: item.name,
        description: item.description,
        quantityScaled: item.quantityScaled,
        unit: item.unit,
        rateMinor: item.rateMinor,
        hsnSac: item.hsnSac,
        taxRateBasisPoints: item.taxRateBasisPoints,
        discount: item.discount,
        attributes: item.attributes,
      ),
    );
    recalculate();
  }

  void removeItem(int index) {
    items.removeAt(index);
    recalculate();
  }

  InvoiceItemModel _withQuantity(InvoiceItemModel item, int quantityScaled) =>
      InvoiceItemModel(
        id: item.id,
        localId: item.localId,
        productId: item.productId,
        name: item.name,
        description: item.description,
        quantityScaled: quantityScaled,
        unit: item.unit,
        rateMinor: item.rateMinor,
        hsnSac: item.hsnSac,
        taxRateBasisPoints: item.taxRateBasisPoints,
        discount: item.discount,
        attributes: item.attributes,
      );

  void addCharge(InvoiceChargeModel charge) {
    charges.add(charge);
    recalculate();
  }

  void removeCharge(int index) {
    charges.removeAt(index);
    recalculate();
  }

  void setInvoiceDiscount(DiscountInput value) {
    invoiceDiscount.value = value;
    recalculate();
  }

  void setTaxType(TaxType value) {
    taxType.value = value;
    recalculate();
  }

  void toggleMoreOptions() => showMoreOptions.toggle();

  void recalculate() {
    final paid = CurrencyUtils.parseMinor(paidController.text) ?? 0;
    calculation.value = _calculator.calculate(
      InvoiceCalculationInput(
        items: items
            .map(
              (item) => InvoiceCalculationItemInput(
                id: item.localId,
                quantityScaled: item.quantityScaled,
                rateMinor: item.rateMinor,
                discount: item.discount,
                taxRateBasisPoints: item.taxRateBasisPoints,
              ),
            )
            .toList(),
        invoiceDiscount: invoiceDiscount.value,
        additionalCharges: charges
            .map(
              (charge) => AdditionalChargeInput(
                title: charge.title,
                amountMinor: charge.amountMinor,
              ),
            )
            .toList(),
        taxType: taxType.value,
        automaticRoundOff: true,
        paidAmountMinor: paid,
      ),
    );
  }

  Future<bool> save({required bool draft}) async {
    if (_originalStatus == InvoiceStatus.cancelled) {
      AppNotification.warning(
        'Invoice cancelled',
        'Cancelled invoices cannot be edited.',
      );
      return false;
    }
    if (await _invoices.numberExists(invoiceNumber.value, excludingId: _id)) {
      AppNotification.error(
        'Duplicate invoice number',
        'Use a unique invoice number.',
      );
      return false;
    }
    isSaving.value = true;
    try {
      final model = buildDocument(draft: draft);
      if (model == null) return false;
      if (!draft) {
        final validation = _validator.validateRequired(model);
        if (validation != null) {
          AppNotification.warning('Complete required details', validation);
          return false;
        }
      }
      final saved = await _invoices.save(model);
      _id = saved.id;
      _captureBaseline();
      AppNotification.success(
        draft ? 'Draft saved' : 'Invoice saved',
        saved.invoiceNumber,
      );
      if (!draft) {
        await AppFocus.dismissKeyboard();
        Get.back(result: true);
      }
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  InvoiceModel? buildDocument({required bool draft}) {
    recalculate();
    final result = calculation.value!;
    final status = draft && !isEditing
        ? InvoiceStatus.draft
        : isQuotation
        ? InvoiceStatus.sent
        : switch (result.paymentStatus) {
            InvoicePaymentStatus.unpaid => InvoiceStatus.unpaid,
            InvoicePaymentStatus.partiallyPaid => InvoiceStatus.partiallyPaid,
            InvoicePaymentStatus.paid => InvoiceStatus.paid,
          };
    return InvoiceModel(
      id: _id,
      documentType: documentType,
      invoiceNumber: invoiceNumber.value,
      customer: customer.value ?? const CustomerSnapshotModel(name: ''),
      invoiceDate: invoiceDate.value,
      dueDate: dueDate.value,
      status: status,
      taxType: taxType.value,
      invoiceDiscount: invoiceDiscount.value,
      items: List.of(items),
      charges: List.of(charges),
      calculation: result,
      notes: _optional(notesController.text),
      terms: _optional(termsController.text),
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> preview() async {
    if (await _invoices.numberExists(invoiceNumber.value, excludingId: _id)) {
      AppNotification.error(
        'Invoice number in use',
        'Choose another invoice number.',
      );
      return;
    }
    final model = buildDocument(draft: false);
    if (model != null) {
      final validation = _validator.validateRequired(model);
      if (validation != null) {
        AppNotification.warning('Complete required details', validation);
        return;
      }
      await Get.toNamed<void>(AppRoutes.invoicePreview, arguments: model);
    }
  }

  void _restore(InvoiceModel model) {
    _id = model.id;
    _createdAt = model.createdAt;
    _originalStatus = model.status;
    invoiceNumber.value = model.invoiceNumber;
    customer.value = model.customer.name.isEmpty ? null : model.customer;
    invoiceDate.value = model.invoiceDate;
    dueDate.value = model.dueDate;
    _dueDateUsesDefault = false;
    taxType.value = model.taxType;
    invoiceDiscount.value = model.invoiceDiscount;
    items.assignAll(model.items);
    charges.assignAll(model.charges);
    notesController.text = model.notes ?? '';
    termsController.text = model.terms ?? '';
    paidController.text = CurrencyUtils.toInputValue(
      model.calculation.paidAmountMinor,
    );
    recalculate();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  String _snapshot() => jsonEncode({
    'number': invoiceNumber.value,
    'customer': _customerSnapshot(customer.value),
    'invoiceDate': invoiceDate.value.toIso8601String(),
    'dueDate': dueDate.value?.toIso8601String(),
    'taxType': taxType.value.name,
    'discount': _discountSnapshot(invoiceDiscount.value),
    'items': items
        .map(
          (item) => {
            'productId': item.productId,
            'name': item.name,
            'description': item.description,
            'quantity': item.quantityScaled,
            'unit': item.unit,
            'rate': item.rateMinor,
            'hsnSac': item.hsnSac,
            'tax': item.taxRateBasisPoints,
            'attributes': item.attributes
                .map((value) => value.toJson())
                .toList(),
            'discount': _discountSnapshot(item.discount),
          },
        )
        .toList(),
    'charges': charges
        .map((charge) => [charge.title, charge.amountMinor])
        .toList(),
    'notes': notesController.text,
    'terms': termsController.text,
    'paid': paidController.text,
  });

  Map<String, Object?>? _customerSnapshot(CustomerSnapshotModel? value) =>
      value == null
      ? null
      : {
          'id': value.customerId,
          'name': value.name,
          'company': value.companyName,
          'mobile': value.mobile,
          'email': value.email,
          'address': value.address,
          'city': value.city,
          'state': value.state,
          'pin': value.pinCode,
          'gstin': value.gstin,
        };

  Map<String, Object> _discountSnapshot(DiscountInput value) => {
    'type': value.type.name,
    'fixed': value.fixedMinor,
    'percentage': value.percentageBasisPoints,
  };

  void _captureBaseline() => _baseline = _snapshot();
}
