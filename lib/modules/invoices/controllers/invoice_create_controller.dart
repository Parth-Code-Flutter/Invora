import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/invoice_calculation_service.dart';

class InvoiceCreateController extends GetxController {
  InvoiceCreateController(
    this._invoices,
    this._business,
    this._customers,
    this._products,
    this._calculator, {
    this.documentType = DocumentType.invoice,
  });

  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final CustomerRepository _customers;
  final ProductRepository _products;
  final InvoiceCalculationService _calculator;
  final DocumentType documentType;
  bool get isQuotation => documentType == DocumentType.quotation;

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
  final currencySymbol = '₹'.obs;
  final notesController = TextEditingController();
  final termsController = TextEditingController();
  final paidController = TextEditingController(text: '0.00');
  int? _id;
  DateTime _createdAt = DateTime.now();
  InvoiceStatus _originalStatus = InvoiceStatus.draft;
  var _counter = 0;

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
    final argumentId = Get.arguments is int ? Get.arguments as int : null;
    final saved = argumentId == null
        ? await _invoices.latestDraftOfType(documentType)
        : await _invoices.getById(argumentId);
    if (saved != null) {
      _restore(saved);
      Get.snackbar('Draft restored', saved.invoiceNumber);
    } else {
      invoiceNumber.value = await _invoices.nextInvoiceNumber(
        prefix: isQuotation ? 'QTN' : profile?.invoicePrefix ?? 'INV',
        startingNumber: isQuotation ? 1 : profile?.startingInvoiceNumber ?? 1,
      );
      recalculate();
    }
    isLoading.value = false;
  }

  Future<List<CustomerModel>> customers() => _customers.watchCustomers().first;
  Future<List<ProductServiceModel>> products() => _products.watchItems().first;

  void selectCustomer(CustomerModel value) {
    customer.value = CustomerSnapshotModel.fromCustomer(value);
  }

  void addProduct(ProductServiceModel product) {
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
      ),
    );
    recalculate();
  }

  void addItem(InvoiceItemModel item) {
    items.add(item);
    recalculate();
  }

  void replaceItem(int index, InvoiceItemModel item) {
    items[index] = item;
    recalculate();
  }

  void removeItem(int index) {
    items.removeAt(index);
    recalculate();
  }

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

  Future<void> save({required bool draft}) async {
    if (_originalStatus == InvoiceStatus.cancelled) {
      Get.snackbar('Invoice cancelled', 'Cancelled invoices cannot be edited.');
      return;
    }
    if (customer.value == null) {
      Get.snackbar('Customer required', 'Select a customer before saving.');
      return;
    }
    if (items.isEmpty) {
      Get.snackbar('Items required', 'Add at least one invoice item.');
      return;
    }
    if (await _invoices.numberExists(invoiceNumber.value, excludingId: _id)) {
      Get.snackbar('Duplicate invoice number', 'Use a unique invoice number.');
      return;
    }
    isSaving.value = true;
    try {
      recalculate();
      final result = calculation.value!;
      final paymentStatus = result.paymentStatus;
      final status = draft
          ? InvoiceStatus.draft
          : isQuotation
          ? InvoiceStatus.sent
          : switch (paymentStatus) {
              InvoicePaymentStatus.unpaid => InvoiceStatus.unpaid,
              InvoicePaymentStatus.partiallyPaid => InvoiceStatus.partiallyPaid,
              InvoicePaymentStatus.paid => InvoiceStatus.paid,
            };
      final saved = await _invoices.save(
        InvoiceModel(
          id: _id,
          documentType: documentType,
          invoiceNumber: invoiceNumber.value,
          customer: customer.value!,
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
        ),
      );
      _id = saved.id;
      Get.snackbar(
        draft ? 'Draft saved' : 'Invoice saved',
        saved.invoiceNumber,
      );
      if (!draft) Get.back(result: true);
    } finally {
      isSaving.value = false;
    }
  }

  void _restore(InvoiceModel model) {
    _id = model.id;
    _createdAt = model.createdAt;
    _originalStatus = model.status;
    invoiceNumber.value = model.invoiceNumber;
    customer.value = model.customer;
    invoiceDate.value = model.invoiceDate;
    dueDate.value = model.dueDate;
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
}
