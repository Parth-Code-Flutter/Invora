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
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedType = Rxn<ItemType>();
  final currencySymbol = '₹'.obs;
  StreamSubscription<List<ProductServiceModel>>? _subscription;
  Worker? _searchWorker;
  Worker? _filterWorker;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
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

  Future<void> deleteItem(ProductServiceModel item) async {
    if (item.id != null) await _repository.softDelete(item.id!);
  }

  Future<void> _loadCurrency() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
  }

  void _bindItems() {
    isLoading.value = true;
    _subscription?.cancel();
    _subscription = _repository
        .watchItems(query: searchQuery.value, type: selectedType.value)
        .listen((results) {
          items.assignAll(results);
          isLoading.value = false;
        });
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    _filterWorker?.dispose();
    _subscription?.cancel();
    super.onClose();
  }
}
