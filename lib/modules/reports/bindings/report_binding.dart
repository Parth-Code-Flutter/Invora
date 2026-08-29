import 'package:get/get.dart';

import '../../../data/repositories/product_repository.dart';
import '../../../data/services/stock_ledger.dart';
import '../../../data/services/stock_report_service.dart';
import '../controllers/gst_export_controller.dart';
import '../controllers/ageing_controller.dart';
import '../controllers/report_controller.dart';
import '../controllers/stock_report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ReportController(
        Get.find(),
        Get.find(),
        Get.isRegistered<StockLedger>() ? Get.find<StockLedger>() : null,
      ),
    );
  }
}

class GstExportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GstExportController(Get.find()));
  }
}

class AgeingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AgeingController(Get.find()));
  }
}

class StockReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => StockReportController(
        StockReportService(
          Get.find<StockLedger>(),
          Get.find<ProductRepository>(),
        ),
      ),
    );
  }
}
