import 'package:get/get.dart';

import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController(this._repository, this._businessRepository);

  final ProductRepository _repository;
  final BusinessRepository _businessRepository;
  final item = Rxn<ProductServiceModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;

  int get itemId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    refreshItem();
  }

  Future<void> refreshItem() async {
    isLoading.value = true;
    item.value = await _repository.getById(itemId);
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
    isLoading.value = false;
  }
}
