import 'package:get/get.dart';

import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

class InvoiceDetailsController extends GetxController {
  InvoiceDetailsController(this._repository, this._businessRepository);
  final InvoiceRepository _repository;
  final BusinessRepository _businessRepository;
  final invoice = Rxn<InvoiceModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
    final id = Get.arguments;
    if (id is int) invoice.value = await _repository.getById(id);
    isLoading.value = false;
  }
}
