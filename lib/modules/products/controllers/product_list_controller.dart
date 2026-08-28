import 'dart:async';

import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';

class ProductListController extends GetxController {
  ProductListController(this._repository, this._businessRepository);

  final ProductRepository _repository;
  final BusinessRepository _businessRepository;
  final items = <ProductServiceModel>[].obs;
  final catalogItems = <ProductServiceModel>[].obs;
  final isLoading = true.obs;
  final loadError = RxnString();
  final searchQuery = ''.obs;
  final selectedType = Rxn<ItemType>();
  final currencySymbol = '₹'.obs;
  StreamSubscription<List<ProductServiceModel>>? _subscription;
  StreamSubscription<List<ProductServiceModel>>? _catalogSubscription;
  Worker? _searchWorker;
  Worker? _filterWorker;
  int _bindingGeneration = 0;
  int _catalogGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    _bindCatalogSummary();
    _bindItems();
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
    super.onClose();
  }
}
