import 'package:get/get.dart';

import '../../../app/routes/startup_navigator.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    resolveInitialRoute();
  }

  Future<void> resolveInitialRoute() =>
      StartupNavigator.continueSession(holdSplash: true);
}
