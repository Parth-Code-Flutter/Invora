import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/product_image_service.dart';
import '../../../data/services/stock_ledger.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController(
    this._repository,
    this._businessRepository, {
    this.seededItemId,
    StockLedger? ledger,
  }) : _ledger = ledger ?? StockLedger(_repository.database);

  final ProductRepository _repository;
  final BusinessRepository _businessRepository;
  final StockLedger _ledger;
  final int? seededItemId;
  final item = Rxn<ProductServiceModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;
  final stockEnabled = false.obs;
  final onHandScaled = RxnInt();

  int get itemId => seededItemId ?? Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    refreshItem();
  }

  Future<void> refreshItem() async {
    isLoading.value = true;
    if (Get.isRegistered<ProductImageService>()) {
      await Get.find<ProductImageService>().ensureReady();
    }
    item.value = await _repository.getById(itemId);
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
    final current = item.value;
    stockEnabled.value = current?.trackStock == true;
    if (current != null &&
        current.trackStock &&
        current.type == ItemType.product &&
        current.id != null) {
      onHandScaled.value = await _ledger.onHand(current.id!);
    } else {
      onHandScaled.value = null;
    }
    isLoading.value = false;
  }
}
