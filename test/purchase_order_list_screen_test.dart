import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/purchase_order_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/purchase_orders/controllers/purchase_order_controller.dart';
import 'package:creovo_invoice/modules/purchase_orders/screens/purchase_order_list_screen.dart';

void main() {
  testWidgets('empty purchase order list shows create action', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final purchases = PurchaseRepository(database);
    Get.put(
      PurchaseOrderListController(PurchaseOrderRepository(database, purchases)),
    );
    addTearDown(() async {
      Get.reset();
      await database.close();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const PurchaseOrderListScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No purchase orders yet'), findsOneWidget);
    expect(find.text('Add purchase order'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
