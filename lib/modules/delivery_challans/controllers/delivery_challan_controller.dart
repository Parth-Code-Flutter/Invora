import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/enums/tax_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/delivery_challan_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/delivery_challan_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/delivery_challan_pdf_service.dart';
import '../../../data/services/invoice_defaults_service.dart';

class DeliveryChallanListController extends GetxController {
  DeliveryChallanListController(this._challans);
  final DeliveryChallanRepository _challans;

  final query = ''.obs;
  final items = <DeliveryChallanSummaryModel>[].obs;
  StreamSubscription<List<DeliveryChallanSummaryModel>>? _subscription;

  List<DeliveryChallanSummaryModel> get visible {
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return items.toList(growable: false);
    return items
        .where(
          (item) =>
              item.challanNumber.toLowerCase().contains(needle) ||
              item.customerName.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _subscription = _challans.watchAll().listen(items.assignAll);
  }

  void search(String value) => query.value = value;

  void openCreate() => Get.toNamed<void>(AppRoutes.deliveryChallanCreate);

  void openDetails(DeliveryChallanSummaryModel item) =>
      Get.toNamed<void>(AppRoutes.deliveryChallanDetails, arguments: item.id);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class DeliveryChallanFormController extends GetxController {
  DeliveryChallanFormController(
    this._challans,
    this._customers,
    this._invoices,
  );
  final DeliveryChallanRepository _challans;
  final CustomerRepository _customers;
  final InvoiceRepository _invoices;

  final customer = Rxn<CustomerSnapshotModel>();
  final items = <DeliveryChallanItemModel>[].obs;
  final challanDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  final movementReason = MovementReason.supply.obs;
  final dispatchAddress = TextEditingController();
  final dispatchCity = TextEditingController();
  final dispatchState = TextEditingController();
  final dispatchPinCode = TextEditingController();
  final deliveryAddress = TextEditingController();
  final deliveryCity = TextEditingController();
  final deliveryState = TextEditingController();
  final deliveryPinCode = TextEditingController();
  final transporterName = TextEditingController();
  final transporterId = TextEditingController();
  final vehicleNumber = TextEditingController();
  final transportDocumentNumber = TextEditingController();
  final distanceKm = TextEditingController();
  final notes = TextEditingController();
  final movementReasonNote = TextEditingController();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final dirty = false.obs;
  final showAddresses = false.obs;
  final showTransport = false.obs;
  final showNotes = false.obs;
  DateTime? transportDocumentDate;
  DeliveryChallanModel? _existing;
  DeliveryChallanSourceType _sourceType = DeliveryChallanSourceType.blank;
  int? _sourceId;
  String? _sourceNumber;
  String _number = '';
  DateTime _createdAt = DateTime.now();
  var _counter = 0;
  final _dispatchCapBySourceItem = <int, int>{};

  bool get isEditing => _existing != null;
  bool get hasUnsavedChanges => !isLoading.value && dirty.value;
  bool get shouldPromptForCustomer =>
      !isLoading.value && !isEditing && customer.value == null;
  bool get isAgainstInvoice => _sourceType == DeliveryChallanSourceType.invoice;
  bool get isFromQuotation =>
      _sourceType == DeliveryChallanSourceType.quotation;
  String get challanNumber => _number;
  String? get sourceCaption {
    final caption = DeliveryChallanLabels.source(_sourceType, _sourceNumber);
    if (caption == null) return null;
    if (isAgainstInvoice) {
      return '$caption — remaining quantity to send';
    }
    return caption;
  }

  String get addressSummary {
    final parts = [
      deliveryAddress.text,
      deliveryCity.text,
      deliveryState.text,
      deliveryPinCode.text,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty);
    if (parts.isEmpty) return 'Uses the customer address';
    return parts.join(', ');
  }

  String get transportSummary {
    final parts = [
      transporterName.text,
      vehicleNumber.text,
      transporterId.text,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty);
    if (parts.isEmpty) return 'Optional until you prepare e-way fields';
    return parts.join(' · ');
  }

  Future<List<CustomerModel>> customers() => _customers.watchCustomers().first;

  @override
  void onInit() {
    super.onInit();
    for (final controller in _textControllers) {
      controller.addListener(_markDirty);
    }
    _initialize();
  }

  List<TextEditingController> get _textControllers => [
    dispatchAddress,
    dispatchCity,
    dispatchState,
    dispatchPinCode,
    deliveryAddress,
    deliveryCity,
    deliveryState,
    deliveryPinCode,
    transporterName,
    transporterId,
    vehicleNumber,
    transportDocumentNumber,
    distanceKm,
    notes,
    movementReasonNote,
  ];

  void _markDirty() => dirty.value = true;

  Future<void> _initialize() async {
    final arguments = Get.arguments;
    final args = arguments is DeliveryChallanEditorArgs
        ? arguments
        : arguments is int
        ? DeliveryChallanEditorArgs(challanId: arguments)
        : const DeliveryChallanEditorArgs();
    if (args.challanId != null) {
      final saved = await _challans.getById(args.challanId!);
      if (saved != null) {
        _restore(saved);
        await _loadDispatchCaps();
        isLoading.value = false;
        dirty.value = false;
        return;
      }
    }
    _number = await _challans.nextNumber();
    if (args.quotationId != null) {
      await _prefillFromDocument(
        args.quotationId!,
        DeliveryChallanSourceType.quotation,
      );
    } else if (args.invoiceId != null) {
      await _prefillFromDocument(
        args.invoiceId!,
        DeliveryChallanSourceType.invoice,
      );
    } else if (args.customerId != null) {
      final selected = await _customers.getById(args.customerId!);
      if (selected != null) selectCustomer(selected);
    }
    isLoading.value = false;
    dirty.value = false;
    if (!isEditing &&
        (_sourceType == DeliveryChallanSourceType.invoice ||
            _sourceType == DeliveryChallanSourceType.quotation) &&
        items.isEmpty) {
      AppNotification.warning(
        'Cannot create challan',
        'No remaining quantity to dispatch.',
      );
    }
  }

  Future<void> _prefillFromDocument(
    int documentId,
    DeliveryChallanSourceType sourceType,
  ) async {
    final document = await _invoices.getById(documentId);
    if (document == null) return;
    _sourceType = sourceType;
    _sourceId = document.id;
    _sourceNumber = document.invoiceNumber;
    customer.value = document.customer;
    _copyCustomerAddresses(document.customer);
    if (sourceType == DeliveryChallanSourceType.invoice) {
      movementReason.value = MovementReason.supply;
    }
    final remaining = await _challans.remainingLinesFromDocument(
      document,
      sourceType: sourceType,
    );
    _dispatchCapBySourceItem
      ..clear()
      ..addEntries([
        for (final item in remaining)
          if (item.sourceItemId != null)
            MapEntry(item.sourceItemId!, item.dispatchedQuantityScaled),
      ]);
    items.assignAll(remaining);
  }

  Future<void> _loadDispatchCaps() async {
    if (_sourceId == null ||
        (_sourceType != DeliveryChallanSourceType.invoice &&
            _sourceType != DeliveryChallanSourceType.quotation)) {
      return;
    }
    final document = await _invoices.getById(_sourceId!);
    if (document == null) return;
    _sourceNumber = document.invoiceNumber;
    final dispatched = await _challans.dispatchedQuantityBySourceItem(
      sourceType: _sourceType,
      sourceId: _sourceId!,
      excludeChallanId: _existing?.id,
    );
    _dispatchCapBySourceItem
      ..clear()
      ..addEntries([
        for (final item in document.items)
          if (item.id != null)
            MapEntry(
              item.id!,
              item.quantityScaled - (dispatched[item.id!] ?? 0),
            ),
      ]);
  }

  void _restore(DeliveryChallanModel saved) {
    _existing = saved;
    _number = saved.challanNumber;
    _createdAt = saved.createdAt;
    _sourceType = saved.sourceType;
    _sourceId = saved.sourceId;
    _sourceNumber = saved.sourceNumber;
    customer.value = saved.customer;
    challanDate.value = saved.challanDate;
    movementReason.value = saved.movementReason;
    dispatchAddress.text = saved.dispatchAddress ?? '';
    dispatchCity.text = saved.dispatchCity ?? '';
    dispatchState.text = saved.dispatchState ?? '';
    dispatchPinCode.text = saved.dispatchPinCode ?? '';
    deliveryAddress.text = saved.deliveryAddress ?? '';
    deliveryCity.text = saved.deliveryCity ?? '';
    deliveryState.text = saved.deliveryState ?? '';
    deliveryPinCode.text = saved.deliveryPinCode ?? '';
    transporterName.text = saved.transporterName ?? '';
    transporterId.text = saved.transporterId ?? '';
    vehicleNumber.text = saved.vehicleNumber ?? '';
    transportDocumentNumber.text = saved.transportDocumentNumber ?? '';
    transportDocumentDate = saved.transportDocumentDate;
    distanceKm.text = saved.distanceKm?.toString() ?? '';
    notes.text = saved.notes ?? '';
    movementReasonNote.text = saved.movementReasonNote ?? '';
    items.assignAll(saved.items);
    showNotes.value = notes.text.trim().isNotEmpty;
    showTransport.value = [
      transporterName,
      transporterId,
      vehicleNumber,
      transportDocumentNumber,
      distanceKm,
    ].any((field) => field.text.trim().isNotEmpty);
  }

  void selectCustomer(CustomerModel value) {
    final snapshot = CustomerSnapshotModel.fromCustomer(value);
    customer.value = snapshot;
    _copyCustomerAddresses(snapshot);
    dirty.value = true;
  }

  void _copyCustomerAddresses(CustomerSnapshotModel snapshot) {
    deliveryAddress.text = snapshot.address ?? '';
    deliveryCity.text = snapshot.city ?? '';
    deliveryState.text = snapshot.state ?? '';
    deliveryPinCode.text = snapshot.pinCode ?? '';
    if (dispatchAddress.text.trim().isEmpty) {
      dispatchAddress.text = snapshot.address ?? '';
      dispatchCity.text = snapshot.city ?? '';
      dispatchState.text = snapshot.state ?? '';
      dispatchPinCode.text = snapshot.pinCode ?? '';
    }
  }

  void copyDeliveryFromCustomer() {
    final snapshot = customer.value;
    if (snapshot == null) return;
    deliveryAddress.text = snapshot.address ?? '';
    deliveryCity.text = snapshot.city ?? '';
    deliveryState.text = snapshot.state ?? '';
    deliveryPinCode.text = snapshot.pinCode ?? '';
    dirty.value = true;
  }

  void copyDispatchFromCustomer() {
    final snapshot = customer.value;
    if (snapshot == null) return;
    dispatchAddress.text = snapshot.address ?? '';
    dispatchCity.text = snapshot.city ?? '';
    dispatchState.text = snapshot.state ?? '';
    dispatchPinCode.text = snapshot.pinCode ?? '';
    dirty.value = true;
  }

  void setDate(DateTime value) {
    challanDate.value = DateTime(value.year, value.month, value.day);
    dirty.value = true;
  }

  void setReason(MovementReason value) {
    if (isAgainstInvoice) return;
    movementReason.value = value;
    dirty.value = true;
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
      addProduct(product);
    }
    dirty.value = true;
  }

  void addProduct(ProductServiceModel product) {
    final existingIndex = items.indexWhere(
      (item) => product.id != null && item.productId == product.id,
    );
    if (existingIndex >= 0) {
      final item = items[existingIndex];
      items[existingIndex] = item.copyWith(
        orderedQuantityScaled: item.orderedQuantityScaled + 1000,
        dispatchedQuantityScaled: item.dispatchedQuantityScaled + 1000,
      );
      dirty.value = true;
      return;
    }
    items.add(
      DeliveryChallanItemModel(
        localId: 'new-${_counter++}',
        productId: product.id,
        name: product.name,
        description: product.description,
        orderedQuantityScaled: 1000,
        dispatchedQuantityScaled: 1000,
        unit: product.unit,
        rateMinor: product.salePriceMinor,
        hsnSac: product.hsnSac,
        taxRateBasisPoints: product.taxRateBasisPoints,
      ),
    );
    dirty.value = true;
  }

  void addCustomItem({
    required String name,
    required int quantityScaled,
    required String unit,
    required int rateMinor,
    String? hsnSac,
    int taxRateBasisPoints = 0,
  }) {
    items.add(
      DeliveryChallanItemModel(
        localId: 'new-${_counter++}',
        name: name.trim(),
        orderedQuantityScaled: quantityScaled,
        dispatchedQuantityScaled: quantityScaled,
        unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
        rateMinor: rateMinor,
        hsnSac: hsnSac,
        taxRateBasisPoints: taxRateBasisPoints,
      ),
    );
    dirty.value = true;
  }

  void setDispatched(DeliveryChallanItemModel item, int quantityScaled) {
    final index = items.indexWhere((row) => row.localId == item.localId);
    if (index < 0) return;
    var quantity = quantityScaled < 0 ? 0 : quantityScaled;
    final cap = item.sourceItemId == null
        ? null
        : _dispatchCapBySourceItem[item.sourceItemId];
    if (cap != null && quantity > cap) quantity = cap;
    if (quantity <= 0) return;
    final current = items[index];
    items[index] = current.copyWith(
      orderedQuantityScaled: current.orderedQuantityScaled == 0
          ? quantity
          : current.orderedQuantityScaled,
      dispatchedQuantityScaled: quantity,
    );
    dirty.value = true;
  }

  void removeItem(DeliveryChallanItemModel item) {
    items.removeWhere((row) => row.localId == item.localId);
    dirty.value = true;
  }

  Future<bool> save({required bool asDraft, bool pop = true}) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final parsedDistance = distanceKm.text.trim().isEmpty
          ? null
          : int.tryParse(distanceKm.text.trim());
      if (distanceKm.text.trim().isNotEmpty && parsedDistance == null) {
        AppNotification.warning(
          'Cannot save challan',
          'Distance must be a whole number of kilometres.',
        );
        return false;
      }
      final saved = await _challans.save(
        DeliveryChallanModel(
          id: _existing?.id,
          challanNumber: _number,
          customer: customer.value ?? const CustomerSnapshotModel(name: ''),
          sourceType: _sourceType,
          sourceId: _sourceId,
          challanDate: challanDate.value,
          status: asDraft
              ? DeliveryChallanStatus.draft
              : DeliveryChallanStatus.open,
          movementReason: movementReason.value,
          movementReasonNote: movementReasonNote.text,
          dispatchAddress: dispatchAddress.text,
          dispatchCity: dispatchCity.text,
          dispatchState: dispatchState.text,
          dispatchPinCode: dispatchPinCode.text,
          deliveryAddress: deliveryAddress.text,
          deliveryCity: deliveryCity.text,
          deliveryState: deliveryState.text,
          deliveryPinCode: deliveryPinCode.text,
          transporterName: transporterName.text,
          transporterId: transporterId.text,
          vehicleNumber: vehicleNumber.text,
          transportDocumentNumber: transportDocumentNumber.text,
          transportDocumentDate: transportDocumentDate,
          distanceKm: parsedDistance,
          ewayStatus: _existing?.ewayStatus ?? EwayStatus.none,
          ewayNumber: _existing?.ewayNumber,
          notes: notes.text,
          items: items.toList(growable: false),
          createdAt: _existing?.createdAt ?? _createdAt,
          updatedAt: DateTime.now(),
        ),
        asDraft: asDraft,
      );
      dirty.value = false;
      _existing = saved;
      if (pop) {
        Get.offNamed<void>(
          AppRoutes.deliveryChallanDetails,
          arguments: saved.id,
        );
      }
      AppNotification.success(
        asDraft
            ? 'Challan saved'
            : isEditing
            ? 'Challan updated'
            : 'Challan issued',
        saved.challanNumber,
      );
      return true;
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot save challan', error.message.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}

class DeliveryChallanDetailsController extends GetxController {
  DeliveryChallanDetailsController(this._challans, this._business, this._pdf);
  final DeliveryChallanRepository _challans;
  final BusinessRepository _business;
  final DeliveryChallanPdfService _pdf;

  final challan = Rxn<DeliveryChallanModel>();
  final currencySymbol = '₹'.obs;
  int? _id;

  @override
  void onInit() {
    super.onInit();
    _id = Get.arguments is int ? Get.arguments as int : null;
    reload();
  }

  Future<void> reload() async {
    final id = _id ?? challan.value?.id;
    if (id != null) {
      challan.value = await _challans.getById(id);
      challan.refresh();
    }
    currencySymbol.value =
        (await _business.getProfile())?.currencySymbol ?? '₹';
  }

  Future<BusinessProfileModel> _requireBusiness() async {
    final profile = await _business.getProfile();
    if (profile == null || profile.businessName.trim().isEmpty) {
      throw ArgumentError('Complete business setup before generating a PDF.');
    }
    return profile;
  }

  Future<void> share() async {
    final current = challan.value;
    if (current == null) return;
    try {
      await _pdf.share(challan: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot share PDF', error.message.toString());
    }
  }

  Future<void> printPdf() async {
    final current = challan.value;
    if (current == null) return;
    try {
      await _pdf.print(challan: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot print PDF', error.message.toString());
    }
  }

  Future<void> savePdf() async {
    final current = challan.value;
    if (current == null) return;
    try {
      await _pdf.save(challan: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot save PDF', error.message.toString());
    }
  }

  Future<void> openEdit() async {
    final current = challan.value;
    if (current?.id == null || !current!.canEdit) return;
    await Get.toNamed<void>(
      AppRoutes.deliveryChallanEdit,
      arguments: current.id,
    );
    await reload();
  }

  Future<void> openConvert() async {
    final current = challan.value;
    if (current?.id == null || !current!.canConvert) {
      AppNotification.warning(
        'Cannot convert',
        current?.isAgainstInvoice == true
            ? 'This challan is against an invoice. Remaining quantity is for delivery, not another invoice.'
            : current?.movementReason != MovementReason.supply
            ? 'Non-sale movement cannot be converted to an invoice.'
            : 'No remaining quantity to invoice.',
      );
      return;
    }
    await Get.toNamed<void>(
      AppRoutes.deliveryChallanConvert,
      arguments: current.id,
    );
    await reload();
  }

  Future<void> recordQuantities(
    List<DeliveryChallanQuantityUpdate> updates,
  ) async {
    final current = challan.value;
    if (current?.id == null) return;
    try {
      challan.value = await _challans.recordQuantities(
        challanId: current!.id!,
        updates: updates,
      );
      AppNotification.success(
        'Quantities updated',
        'Delivered and returned quantities were saved offline.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot update quantities',
        error.message.toString(),
      );
    }
  }

  Future<void> prepareEway() async {
    final current = challan.value;
    if (current?.id == null) return;
    try {
      challan.value = await _challans.prepareEway(current!.id!);
      AppNotification.success(
        'E-way prepared',
        'Fields are prepared on this device. Generation happens on the GST portal.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot prepare e-way', error.message.toString());
    }
  }

  Future<void> importEway(String number) async {
    final current = challan.value;
    if (current?.id == null) return;
    try {
      challan.value = await _challans.importEwayAcknowledgement(
        challanId: current!.id!,
        ewayNumber: number,
      );
      AppNotification.success(
        'Acknowledgement imported',
        'The e-way bill number was saved from the portal response.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot import acknowledgement',
        error.message.toString(),
      );
    }
  }

  Future<void> cancel(String reason) async {
    final current = challan.value;
    if (current?.id == null) return;
    try {
      challan.value = await _challans.cancel(
        challanId: current!.id!,
        reason: reason,
      );
      AppNotification.success(
        'Challan cancelled',
        'It stays on file and cannot be converted.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot cancel challan',
        error.message.toString(),
      );
    }
  }
}

class DeliveryChallanConvertController extends GetxController {
  DeliveryChallanConvertController(
    this._challans,
    this._invoices,
    this._business, {
    this.defaults,
  });
  final DeliveryChallanRepository _challans;
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final InvoiceDefaultsService? defaults;

  final challan = Rxn<DeliveryChallanModel>();
  final quantities = <int, int>{}.obs;
  final quantityInputs = <int, TextEditingController>{};
  final isSaving = false.obs;
  int? _id;

  @override
  void onInit() {
    super.onInit();
    _id = Get.arguments is int ? Get.arguments as int : null;
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) return;
    final loaded = await _challans.getById(id);
    if (loaded == null) {
      challan.value = null;
      return;
    }
    quantities.assignAll({
      for (final item in loaded.items)
        if (item.id != null) item.id!: item.remainingToInvoiceScaled,
    });
    for (final item in loaded.items) {
      if (item.id == null) continue;
      quantityInputs[item.id!] = TextEditingController(
        text: QuantityUtils.toInputValue(item.remainingToInvoiceScaled),
      );
    }
    challan.value = loaded;
  }

  @override
  void onClose() {
    for (final controller in quantityInputs.values) {
      controller.dispose();
    }
    super.onClose();
  }

  void setQuantity(int itemId, String input) {
    final parsed = QuantityUtils.parseScaled(input);
    if (parsed == null) return;
    quantities[itemId] = parsed;
  }

  Future<void> convert() async {
    final current = challan.value;
    if (current?.id == null || isSaving.value) return;
    isSaving.value = true;
    try {
      final profile = await _business.getProfile();
      final number = await _invoices.nextInvoiceNumber(
        prefix: profile?.invoicePrefix ?? 'INV',
        startingNumber: profile?.startingInvoiceNumber ?? 1,
      );
      final dueDays = defaults?.dueDays ?? 0;
      final invoiceDate = DateTime.now();
      final invoice = await _challans.convertToInvoice(
        challanId: current!.id!,
        invoiceNumber: number,
        taxType: defaults?.taxType ?? TaxType.cgstSgst,
        invoiceDate: invoiceDate,
        dueDate: dueDays > 0 ? invoiceDate.add(Duration(days: dueDays)) : null,
        lines: [
          for (final entry in quantities.entries)
            DeliveryChallanConvertLine(
              itemId: entry.key,
              quantityScaled: entry.value,
            ),
        ],
      );
      AppNotification.success('Invoice created', invoice.invoiceNumber);
      Get.offNamed<void>(AppRoutes.invoiceDetails, arguments: invoice.id);
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot convert', error.message.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
