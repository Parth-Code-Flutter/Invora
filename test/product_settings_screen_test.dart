import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
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
}
