import 'package:get/get.dart';

import '../controllers/debit_note_create_controller.dart';
import '../controllers/debit_note_details_controller.dart';

class DebitNoteCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DebitNoteCreateController(Get.find(), Get.find()));
  }
}

class DebitNoteDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DebitNoteDetailsController(Get.find(), Get.find(), Get.find()),
    );
  }
}
