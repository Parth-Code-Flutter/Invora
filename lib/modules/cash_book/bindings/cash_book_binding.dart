import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/cash_book_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../controllers/cash_book_controller.dart';

class CashBookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CashBookController(
        Get.find<CashBookRepository>(),
        Get.find<BusinessRepository>(),
        Get.find<CustomerRepository>(),
        Get.find<PurchaseRepository>(),
      ),
    );
  }
}

class AccountStatementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AccountStatementController(
        Get.find<CashBookRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}

class AdvanceFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AdvanceFormController(
        Get.find<CashBookRepository>(),
        Get.find<CustomerRepository>(),
        Get.find<PurchaseRepository>(),
      ),
    );
  }
}
