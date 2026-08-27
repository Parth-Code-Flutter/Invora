import 'package:get/get.dart';

import '../controllers/gst_export_controller.dart';
import '../controllers/ageing_controller.dart';
import '../controllers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReportController(Get.find(), Get.find()));
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
