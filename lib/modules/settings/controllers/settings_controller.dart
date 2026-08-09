import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/controllers/app_controller.dart';

class SettingsController extends GetxController {
  SettingsController(this.appController);
  final AppController appController;
  final appVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    PackageInfo.fromPlatform().then(
      (info) => appVersion.value = '${info.version} (${info.buildNumber})',
    );
  }
}
