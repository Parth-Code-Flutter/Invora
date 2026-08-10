import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:creovo_invoice/app/utils/responsive_utils.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:creovo_invoice/modules/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  testWidgets('responsive helpers distinguish phone and tablet layouts', (
    tester,
  ) async {
    AppDeviceType? type;
    int? columns;

    Future<void> render(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              type = ResponsiveUtils.deviceType(context);
              columns = ResponsiveUtils.gridColumns(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    await render(const Size(390, 844));
    expect(type, AppDeviceType.phone);
    expect(columns, 1);

    await render(const Size(834, 1194));
    expect(type, AppDeviceType.tablet);
    expect(columns, 2);

    await render(const Size(1194, 834));
    expect(type, AppDeviceType.largeTablet);
    expect(columns, 3);
  });

  testWidgets('onboarding renders without overflow on tablet landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    final storage = await AppStorage.create();
    Get.put(OnboardingController(storage));

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
