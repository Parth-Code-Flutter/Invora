import 'dart:async';

import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/product_image_service.dart';
import '../../../data/services/stock_ledger.dart';

class ProductListController extends GetxController {
  ProductListController(
    this._repository,
    this._businessRepository, [
    StockLedger? ledger,
  ]) : _ledger = ledger ?? StockLedger(_repository.database);

  final ProductRepository _repository;
  final BusinessRepository _businessRepository;
  final StockLedger _ledger;
  final items = <ProductServiceModel>[].obs;
  final catalogItems = <ProductServiceModel>[].obs;
  final isLoading = true.obs;
  final loadError = RxnString();
  final searchQuery = ''.obs;
  final selectedType = Rxn<ItemType>();
  final currencySymbol = '₹'.obs;
  final stockEnabled = false.obs;
  final onHandByProduct = <int, int>{}.obs;
  StreamSubscription<List<ProductServiceModel>>? _subscription;
  StreamSubscription<List<ProductServiceModel>>? _catalogSubscription;
  StreamSubscription<bool>? _stockSubscription;
  Worker? _searchWorker;
  Worker? _filterWorker;
  int _bindingGeneration = 0;
  int _catalogGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    if (Get.isRegistered<ProductImageService>()) {
      unawaited(Get.find<ProductImageService>().ensureReady());
    }
    _bindCatalogSummary();
    _bindItems();
    _stockSubscription = _ledger.watchEnabled().listen((enabled) {
      stockEnabled.value = enabled;
      _refreshOnHand();
    });
    _searchWorker = debounce<String>(
      searchQuery,
      (_) => _bindItems(),
      time: const Duration(milliseconds: 300),
    );
    _filterWorker = ever<ItemType?>(selectedType, (_) => _bindItems());
  }

  void updateSearch(String value) => searchQuery.value = value;
  void selectType(ItemType? type) => selectedType.value = type;
  void retry() {
    _bindCatalogSummary();
    _bindItems();
  }

  Future<void> deleteItem(ProductServiceModel item) async {
    if (item.id != null) await _repository.softDelete(item.id!);
  }

  int? onHandFor(ProductServiceModel item) {
    if (!stockEnabled.value ||
        !item.trackStock ||
        item.type != ItemType.product ||
        item.id == null) {
      return null;
    }
    return onHandByProduct[item.id!] ?? 0;
  }

  Future<void> _loadCurrency() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
  }

  void _bindItems() {
    final generation = ++_bindingGeneration;
    isLoading.value = true;
    loadError.value = null;
    _subscription?.cancel();
    _subscription = _repository
        .watchItems(query: searchQuery.value, type: selectedType.value)
        .listen(
          (results) {
            if (generation != _bindingGeneration || isClosed) return;
            items.assignAll(results);
            isLoading.value = false;
            _refreshOnHand();
          },
          onError: (_) {
            if (generation != _bindingGeneration || isClosed) return;
            loadError.value = 'Could not load your catalog';
            isLoading.value = false;
          },
        );
  }

  void _bindCatalogSummary() {
    final generation = ++_catalogGeneration;
    _catalogSubscription?.cancel();
    _catalogSubscription = _repository.watchItems().listen(
      (results) {
        if (generation != _catalogGeneration || isClosed) return;
        catalogItems.assignAll(results);
      },
      onError: (_) {
        if (generation != _catalogGeneration || isClosed) return;
        loadError.value = 'Could not load your catalog';
      },
    );
  }

  Future<void> _refreshOnHand() async {
    if (!stockEnabled.value) {
      onHandByProduct.clear();
      return;
    }
    final ids = items
        .where(
          (item) =>
              item.trackStock &&
              item.type == ItemType.product &&
              item.id != null,
        )
        .map((item) => item.id!);
    onHandByProduct.assignAll(await _ledger.onHandByProduct(ids));
  }

  int countFor(ItemType? type) => type == null
      ? catalogItems.length
      : catalogItems.where((item) => item.type == type).length;

  @override
  void onClose() {
    _bindingGeneration++;
    _catalogGeneration++;
    _searchWorker?.dispose();
    _filterWorker?.dispose();
    _subscription?.cancel();
    _catalogSubscription?.cancel();
    _stockSubscription?.cancel();
    super.onClose();
  }
}
