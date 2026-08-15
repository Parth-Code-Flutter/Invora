import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/business_workspace_service.dart';
import 'package:creovo_invoice/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:creovo_invoice/modules/onboarding/screens/workspace_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final workspace = BusinessWorkspaceService(storage);
    Get.put(OnboardingController(storage, workspace));
  });

  tearDown(Get.reset);

  testWidgets('workspace choice stays usable on a narrow Android phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WorkspaceSetupScreen()),
    );

    expect(find.text('What do you manage most?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Continue with Sales'), 220);
    expect(find.text('Continue with Sales'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Purchases'), -180);
    await tester.tap(find.text('Purchases'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue with Purchases'), 220);
    expect(find.text('Continue with Purchases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
