import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/expense_pdf_service.dart';
import '../controllers/expense_controller.dart';

class ExpenseListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExpenseListController(Get.find<ExpenseRepository>()));
  }
}

class ExpenseFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExpenseFormController(Get.find<ExpenseRepository>()));
  }
}

class ExpenseDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ExpenseDetailsController(
        Get.find<ExpenseRepository>(),
        Get.find<BusinessRepository>(),
        Get.find<ExpensePdfService>(),
      ),
    );
  }
}
