import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_back_button.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/image_storage_service.dart';
import 'package:creovo_invoice/data/services/product_settings_service.dart';
import 'package:creovo_invoice/modules/business_setup/controllers/business_setup_controller.dart';
import 'package:creovo_invoice/modules/business_setup/screens/business_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('existing business opens in edit mode with a back action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = BusinessRepository(database);
    final now = DateTime(2026, 8, 13);
    await repository.saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo MDF',
        ownerName: 'Harsh Mandavia',
        createdAt: now,
        updatedAt: now,
      ),
    );
    Get.put(
      BusinessSetupController(
        repository,
        storage,
        ImageStorageService(),
        ProductSettingsService(storage),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const BusinessSetupScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit business identity'), findsOneWidget);
    expect(find.text('Let’s make it yours'), findsNothing);
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.text('Used across your invoices.'), findsOneWidget);
  });
}
