import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/unit_service.dart';
import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
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

    expect(find.byTooltip('Add unit'), findsNothing);
    expect(find.byTooltip('Actions for pcs'), findsOneWidget);

    await tester.tap(find.byTooltip('Actions for pcs'));
    await tester.pumpAndSettle();
    expect(find.text('Current default'), findsOneWidget);
    expect(find.text('Edit unit'), findsOneWidget);
    expect(find.text('Delete unit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(4, 4));
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

  testWidgets('unit selection grid stays compact on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final service = UnitService(await AppStorage.create());
    Get.put(UnitSettingsController(service));

    await tester.pumpWidget(const GetMaterialApp(home: UnitSettingsScreen()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Your default is preselected whenever'),
      findsOneWidget,
    );
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('pcs'), findsWidgets);
    final pcsCenter = tester.getCenter(find.text('pcs').last);
    final boxCenter = tester.getCenter(find.text('box'));
    expect(boxCenter.dy, closeTo(pcsCenter.dy, 2));
    expect(pcsCenter.dx, lessThan(boxCenter.dx));
    expect(tester.getCenter(find.text('set')).dy, greaterThan(pcsCenter.dy));
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

  testWidgets('tapping a unit immediately repaints it as the default', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.managedUnits: ['pcs', '6mm'],
      AppStorageKeyConst.defaultUnit: 'pcs',
    });
    final service = UnitService(await AppStorage.create());
    Get.put(UnitSettingsController(service));

    await tester.pumpWidget(const GetMaterialApp(home: UnitSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6mm'));
    await tester.pump();

    final selectedTile = find.ancestor(
      of: find.text('6mm'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
        of: selectedTile,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(service.defaultUnit, '6mm');
  });
}
