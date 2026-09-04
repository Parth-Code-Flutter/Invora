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
            current: MainDestination.documents,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Documents'), findsNothing);
    expect(find.text('Parties'), findsNothing);
    expect(find.text('More'), findsNothing);
    expect(find.text('Create'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byIcon(Symbols.add_rounded)).dy,
      lessThan(tester.getTopLeft(find.byIcon(Symbols.home_rounded)).dy),
    );

    await tester.tap(find.byIcon(Symbols.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Create new'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Purchase bill'), findsOneWidget);
    expect(find.text('Purchase order'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Product or service'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
