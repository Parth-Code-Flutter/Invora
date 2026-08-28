import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/services/purchase_order_pdf_service.dart';

class PurchaseOrderListController extends GetxController {
  PurchaseOrderListController(this._orders);
  final PurchaseOrderRepository _orders;

  final query = ''.obs;
  final items = <PurchaseOrderSummaryModel>[].obs;
  StreamSubscription<List<PurchaseOrderSummaryModel>>? _subscription;

  List<PurchaseOrderSummaryModel> get visible {
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return items.toList(growable: false);
    return items
        .where(
          (item) =>
              item.orderNumber.toLowerCase().contains(needle) ||
              item.supplierName.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _subscription = _orders.watchAll().listen(items.assignAll);
  }

  void search(String value) => query.value = value;

  void openCreate() => Get.toNamed<void>(AppRoutes.purchaseOrderCreate);

  void openDetails(PurchaseOrderSummaryModel item) =>
      Get.toNamed<void>(AppRoutes.purchaseOrderDetails, arguments: item.id);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class PurchaseOrderFormController extends GetxController {
  PurchaseOrderFormController(this._orders, this._purchases);
  final PurchaseOrderRepository _orders;
  final PurchaseRepository _purchases;

  final supplier = Rxn<SupplierModel>();
  final items = <PurchaseOrderItemModel>[].obs;
  final orderDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  final expectedDate = Rxn<DateTime>();
  final terms = TextEditingController();
  final notes = TextEditingController();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final dirty = false.obs;
  final showTerms = false.obs;
  final showNotes = false.obs;
  PurchaseOrderModel? _existing;
  String _number = '';
  DateTime _createdAt = DateTime.now();
  var _counter = 0;

  bool get isEditing => _existing != null;
  bool get hasUnsavedChanges => !isLoading.value && dirty.value;
  bool get shouldPromptForSupplier =>
      !isLoading.value && !isEditing && supplier.value == null;
  String get orderNumber => _number;

  String get termsSummary {
    final value = terms.text.trim();
    return value.isEmpty ? 'Optional payment or delivery terms' : value;
  }

  Future<List<SupplierModel>> suppliers({String query = ''}) =>
      _purchases.watchSuppliers(query: query).first;

  @override
  void onInit() {
    super.onInit();
    terms.addListener(_markDirty);
    notes.addListener(_markDirty);
    _initialize();
  }

  void _markDirty() => dirty.value = true;

  Future<void> _initialize() async {
    final arguments = Get.arguments;
    final args = arguments is PurchaseOrderEditorArgs
        ? arguments
        : arguments is int
        ? PurchaseOrderEditorArgs(orderId: arguments)
        : const PurchaseOrderEditorArgs();
    if (args.orderId != null) {
      final saved = await _orders.getById(args.orderId!);
      if (saved != null) {
        _restore(saved);
        isLoading.value = false;
        dirty.value = false;
        return;
      }
    }
    _number = await _orders.nextNumber();
    if (args.supplierId != null) {
      final selected = await _purchases.getSupplier(args.supplierId!);
      if (selected != null) selectSupplier(selected);
    }
    isLoading.value = false;
    dirty.value = false;
  }

  void _restore(PurchaseOrderModel saved) {
    _existing = saved;
    _number = saved.orderNumber;
    _createdAt = saved.createdAt;
    supplier.value = saved.supplier;
    orderDate.value = saved.orderDate;
    expectedDate.value = saved.expectedDate;
    terms.text = saved.terms ?? '';
    notes.text = saved.notes ?? '';
    items.assignAll(saved.items);
    showTerms.value = terms.text.trim().isNotEmpty;
    showNotes.value = notes.text.trim().isNotEmpty;
  }

  void selectSupplier(SupplierModel value) {
    supplier.value = value;
    dirty.value = true;
  }

  void setDate(DateTime value) {
    orderDate.value = DateTime(value.year, value.month, value.day);
    dirty.value = true;
  }

  void setExpectedDate(DateTime? value) {
    expectedDate.value = value == null
        ? null
        : DateTime(value.year, value.month, value.day);
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
      );
      dirty.value = true;
      return;
    }
    items.add(
      PurchaseOrderItemModel(
        localId: 'new-${_counter++}',
        productId: product.id,
        name: product.name,
        description: product.description,
        orderedQuantityScaled: 1000,
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
      PurchaseOrderItemModel(
        localId: 'new-${_counter++}',
        name: name.trim(),
        orderedQuantityScaled: quantityScaled,
        unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
        rateMinor: rateMinor,
        hsnSac: hsnSac,
        taxRateBasisPoints: taxRateBasisPoints,
      ),
    );
    dirty.value = true;
  }

  void setOrdered(PurchaseOrderItemModel item, int quantityScaled) {
    final index = items.indexWhere((row) => row.localId == item.localId);
    if (index < 0) return;
    var quantity = quantityScaled < 0 ? 0 : quantityScaled;
    final received = items[index].receivedQuantityScaled;
    if (quantity < received) quantity = received;
    if (quantity <= 0) return;
    items[index] = items[index].copyWith(orderedQuantityScaled: quantity);
    dirty.value = true;
  }

  void removeItem(PurchaseOrderItemModel item) {
    if (item.receivedQuantityScaled > 0 || item.billedQuantityScaled > 0) {
      return;
    }
    items.removeWhere((row) => row.localId == item.localId);
    dirty.value = true;
  }

  Future<bool> save({required bool asDraft, bool pop = true}) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final saved = await _orders.save(
        PurchaseOrderModel(
          id: _existing?.id,
          orderNumber: _number,
          supplier:
              supplier.value ??
              SupplierModel(
                name: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
          orderDate: orderDate.value,
          expectedDate: expectedDate.value,
          status: asDraft
              ? PurchaseOrderStatus.draft
              : PurchaseOrderStatus.open,
          taxMode: _existing?.taxMode ?? 'cgst_sgst',
          terms: terms.text,
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
        Get.offNamed<void>(AppRoutes.purchaseOrderDetails, arguments: saved.id);
      }
      AppNotification.success(
        asDraft
            ? 'Purchase order saved'
            : isEditing
            ? 'Purchase order updated'
            : 'Purchase order issued',
        saved.orderNumber,
      );
      return true;
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot save purchase order',
        error.message.toString(),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    terms.dispose();
    notes.dispose();
    super.onClose();
  }
}

class PurchaseOrderDetailsController extends GetxController {
  PurchaseOrderDetailsController(this._orders, this._business, this._pdf);
  final PurchaseOrderRepository _orders;
  final BusinessRepository _business;
  final PurchaseOrderPdfService _pdf;

  final order = Rxn<PurchaseOrderModel>();
  final currencySymbol = '₹'.obs;
  int? _id;

  @override
  void onInit() {
    super.onInit();
    _id = Get.arguments is int ? Get.arguments as int : null;
    reload();
  }

  Future<void> reload() async {
    final id = _id ?? order.value?.id;
    if (id != null) {
      order.value = await _orders.getById(id);
      order.refresh();
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
    final current = order.value;
    if (current == null) return;
    try {
      await _pdf.share(order: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot share PDF', error.message.toString());
    }
  }

  Future<void> printPdf() async {
    final current = order.value;
    if (current == null) return;
    try {
      await _pdf.print(order: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot print PDF', error.message.toString());
    }
  }

  Future<void> savePdf() async {
    final current = order.value;
    if (current == null) return;
    try {
      await _pdf.save(order: current, business: await _requireBusiness());
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot save PDF', error.message.toString());
    }
  }

  Future<void> openEdit() async {
    final current = order.value;
    if (current?.id == null || !current!.canEdit) return;
    await Get.toNamed<void>(AppRoutes.purchaseOrderEdit, arguments: current.id);
    await reload();
  }

  Future<void> openConvert() async {
    final current = order.value;
    if (current?.id == null || !current!.canConvert) {
      AppNotification.warning(
        'Cannot convert',
        current?.isDraft == true
            ? 'Issue this purchase order before converting.'
            : 'Receive goods before converting remaining quantity to a bill.',
      );
      return;
    }
    await Get.toNamed<void>(
      AppRoutes.purchaseOrderConvert,
      arguments: current.id,
    );
    await reload();
  }

  Future<void> recordQuantities(
    List<PurchaseOrderQuantityUpdate> updates,
  ) async {
    final current = order.value;
    if (current?.id == null) return;
    try {
      order.value = await _orders.recordQuantities(
        orderId: current!.id!,
        updates: updates,
      );
      AppNotification.success(
        'Quantities updated',
        'Received and returned quantities were saved offline.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot update quantities',
        error.message.toString(),
      );
    }
  }

  Future<void> cancel(String reason) async {
    final current = order.value;
    if (current?.id == null) return;
    try {
      order.value = await _orders.cancel(orderId: current!.id!, reason: reason);
      AppNotification.success(
        'Purchase order cancelled',
        'It stays on file and cannot be converted.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot cancel purchase order',
        error.message.toString(),
      );
    }
  }
}

class PurchaseOrderConvertController extends GetxController {
  PurchaseOrderConvertController(this._orders);
  final PurchaseOrderRepository _orders;

  final order = Rxn<PurchaseOrderModel>();
  final quantities = <int, int>{}.obs;
  final quantityInputs = <int, TextEditingController>{};
  final billNumber = TextEditingController();
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
    final loaded = await _orders.getById(id);
    if (loaded == null) {
      order.value = null;
      return;
    }
    quantities.assignAll({
      for (final item in loaded.items)
        if (item.id != null) item.id!: item.remainingToBillScaled,
    });
    for (final item in loaded.items) {
      if (item.id == null) continue;
      quantityInputs[item.id!] = TextEditingController(
        text: QuantityUtils.toInputValue(item.remainingToBillScaled),
      );
    }
    order.value = loaded;
  }

  @override
  void onClose() {
    for (final controller in quantityInputs.values) {
      controller.dispose();
    }
    billNumber.dispose();
    super.onClose();
  }

  void setQuantity(int itemId, String input) {
    final parsed = QuantityUtils.parseScaled(input);
    if (parsed == null) return;
    quantities[itemId] = parsed;
  }

  Future<void> convert() async {
    final current = order.value;
    if (current?.id == null || isSaving.value) return;
    isSaving.value = true;
    try {
      final bill = await _orders.convertToBill(
        orderId: current!.id!,
        billNumber: billNumber.text,
        lines: [
          for (final entry in quantities.entries)
            PurchaseOrderConvertLine(
              itemId: entry.key,
              quantityScaled: entry.value,
            ),
        ],
      );
      AppNotification.success('Purchase bill created', bill.billNumber);
      Get.offNamed<void>(AppRoutes.purchaseBillDetails, arguments: bill.id);
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot convert', error.message.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
