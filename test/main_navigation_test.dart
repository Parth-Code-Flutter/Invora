import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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
    expect(find.byType(SvgPicture), findsNWidgets(5));
    expect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.home)),
      findsOneWidget,
    );
    expect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.documents)),
      findsOneWidget,
    );
    expect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.products)),
      findsOneWidget,
    );
    expect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.parties)),
      findsOneWidget,
    );
    expect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.more)),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byType(SvgPicture).at(0)).center.dy,
      closeTo(tester.getRect(find.byType(SvgPicture).at(1)).center.dy, 1),
    );
    expect(
      tester.getRect(find.byType(SvgPicture).at(2)).center.dy,
      closeTo(tester.getRect(find.byType(SvgPicture).at(3)).center.dy, 1),
    );
    expect(find.text('Create'), findsNothing);
    expect(find.text('Create new'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
