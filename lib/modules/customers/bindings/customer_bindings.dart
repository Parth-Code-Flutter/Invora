import 'package:get/get.dart';

import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/cash_book_repository.dart';
import '../controllers/customer_details_controller.dart';
import '../controllers/customer_form_controller.dart';
import '../controllers/customer_list_controller.dart';
import '../controllers/customer_statement_controller.dart';
import '../../../data/services/customer_statement_pdf_service.dart';
import '../../../data/services/customer_statement_service.dart';

class CustomerListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerListController>(
      () => CustomerListController(
        Get.find<CustomerRepository>(),
        Get.find<InvoiceRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}

class CustomerFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerFormController>(
      () => CustomerFormController(Get.find<CustomerRepository>()),
    );
  }
}

class CustomerDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerDetailsController>(
      () => CustomerDetailsController(
        Get.find<CustomerRepository>(),
        Get.find<InvoiceRepository>(),
        Get.find<BusinessRepository>(),
      ),
    );
  }
}

class CustomerStatementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CustomerStatementController(
        Get.find(),
        Get.find(),
        CustomerStatementService(
          Get.find(),
          Get.find(),
          Get.find<CashBookRepository>(),
        ),
        const CustomerStatementPdfService(),
      ),
    );
  }
}
