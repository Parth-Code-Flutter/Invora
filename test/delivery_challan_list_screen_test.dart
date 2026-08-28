import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/delivery_challan_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/delivery_challans/controllers/delivery_challan_controller.dart';
import 'package:creovo_invoice/modules/delivery_challans/screens/delivery_challan_list_screen.dart';

void main() {
  testWidgets('empty delivery challan list shows create action', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final invoices = InvoiceRepository(database);
    final repository = DeliveryChallanRepository(database, invoices);
    Get.put(DeliveryChallanListController(repository));
    addTearDown(() async {
      Get.reset();
      await database.close();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const DeliveryChallanListScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No delivery challans yet'), findsOneWidget);
    expect(find.text('Add challan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
