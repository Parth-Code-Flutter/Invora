import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/modules/purchases/screens/purchase_workspace_screen.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';

void main() {
  testWidgets('isolated purchase workspace is explicit and overflow free', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put<PurchaseRepository>(PurchaseRepository(database));
    addTearDown(() async {
      Get.reset();
      await database.close();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const PurchaseWorkspaceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payables snapshot'), findsOneWidget);
    expect(find.text('Amount to pay'), findsOneWidget);
    expect(find.text('Bills & payables'), findsOneWidget);
    expect(find.text('New bill'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Supplier'), findsNothing);
    expect(find.text('All bills'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('Record your first purchase bill'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
