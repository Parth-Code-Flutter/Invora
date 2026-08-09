import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        Get.find<BusinessRepository>(),
        Get.find<InvoiceRepository>(),
      ),
    );
  }
}
