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
    expect(find.text('Products'), findsNothing);
    expect(find.text('Parties'), findsNothing);
    expect(find.text('More'), findsNothing);
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Documents'), findsOneWidget);
    expect(find.bySemanticsLabel('Products'), findsOneWidget);
    expect(find.bySemanticsLabel('Parties'), findsOneWidget);
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    expect(find.byIcon(Symbols.home_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.receipt_long_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.package_2_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.groups_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.apps_rounded), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(Symbols.home_rounded)).center.dy,
      closeTo(
        tester.getRect(find.byIcon(Symbols.receipt_long_rounded)).center.dy,
        1,
      ),
    );
    expect(
      tester.getRect(find.byIcon(Symbols.package_2_rounded)).center.dy,
      closeTo(tester.getRect(find.byIcon(Symbols.groups_rounded)).center.dy, 1),
    );
    expect(find.byIcon(Symbols.add_rounded), findsNothing);
    expect(find.text('Create'), findsNothing);
    expect(find.text('Create new'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
