import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/routes/app_routes.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/business_workspace_service.dart';
import 'package:creovo_invoice/modules/onboarding/controllers/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    storage = await AppStorage.create();
    Get.put(OnboardingController(storage, BusinessWorkspaceService(storage)));
  });

  tearDown(Get.reset);

  testWidgets('onboarding complete skips workspace choice and opens setup', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(
            name: AppRoutes.businessSetup,
            page: () => const Scaffold(body: Text('Business setup')),
          ),
          GetPage(
            name: AppRoutes.workspaceSetup,
            page: () => const Scaffold(body: Text('Workspace choice')),
          ),
        ],
        home: const SizedBox.shrink(),
      ),
    );

    await Get.find<OnboardingController>().complete();
    await tester.pumpAndSettle();

    expect(find.text('Business setup'), findsOneWidget);
    expect(find.text('Workspace choice'), findsNothing);
    expect(storage.getBool(AppStorageKeyConst.onboardingCompleted), isTrue);
  });
}
