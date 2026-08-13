import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:creovo_invoice/app/widgets/app_main_navigation.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('modern navigation remains readable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SizedBox.expand(),
          bottomNavigationBar: AppMainNavigation(
            current: MainDestination.invoices,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Symbols.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Create new'), findsOneWidget);
    expect(find.text('Product or service'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
