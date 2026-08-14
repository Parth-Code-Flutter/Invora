import 'package:get/get.dart';

import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/backup_service.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put<DashboardController>(
        DashboardController(
          Get.find<BusinessRepository>(),
          Get.find<InvoiceRepository>(),
          Get.find<BackupService>(),
        ),
        permanent: true,
      );
    }
  }
}
