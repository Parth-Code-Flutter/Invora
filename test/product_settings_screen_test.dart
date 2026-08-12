import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/constants/app_colors.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/modules/settings/controllers/product_settings_controller.dart';
import 'package:creovo_invoice/modules/settings/screens/product_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets(
    'custom-field dialog closes without using a disposed controller',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = ProductSettingsService(await AppStorage.create());
      Get.put(ProductSettingsController(service));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const ProductSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Custom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Finish');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add custom field'), findsNothing);
    },
  );

  testWidgets('grouped field workspace stays clean on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final service = ProductSettingsService(await AppStorage.create());
    Get.put(ProductSettingsController(service));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const ProductSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configure your catalog'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Invoice essentials'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Invoice essentials'), findsOneWidget);
    final selectedUnit = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Unit'),
    );
    expect(selectedUnit.selected, isTrue);
    expect(selectedUnit.checkmarkColor, Colors.white);
    expect(selectedUnit.selectedColor, AppColors.primary);
    await tester.scrollUntilVisible(
      find.text('Identity'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Identity'), findsOneWidget);
    expect(find.byType(FilterChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
