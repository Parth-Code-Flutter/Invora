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

    expect(find.text('Purchase overview'), findsOneWidget);
    expect(find.text('Bills & payables'), findsOneWidget);
    expect(find.text('New bill'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Record your first purchase bill'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
