import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';
import 'package:creovo_invoice/modules/settings/controllers/unit_settings_controller.dart';
import 'package:creovo_invoice/modules/settings/screens/unit_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('unit editor closes without using a disposed controller', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = UnitService(await AppStorage.create());
    final controller = Get.put(UnitSettingsController(service));

    await tester.pumpWidget(const GetMaterialApp(home: UnitSettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Add a unit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bundle');
    await tester.tap(find.widgetWithText(FilledButton, 'Add unit'));
    await tester.pumpAndSettle();

    expect(find.text('Add a unit'), findsNothing);
    expect(controller.units, contains('bundle'));
    expect(tester.takeException(), isNull);
  });

  test(
    'default selection updates before preference persistence completes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = UnitService(await AppStorage.create());
      final controller = UnitSettingsController(service)..onInit();

      final saving = controller.setDefault('kg');
      expect(controller.selectedDefault.value, 'kg');
      await saving;
      expect(service.defaultUnit, 'kg');
    },
  );
}
