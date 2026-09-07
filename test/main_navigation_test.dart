import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/widgets/app_main_navigation.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('floating dock sits above the inset with pill chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SizedBox.expand(key: ValueKey('content')),
          bottomNavigationBar: AppMainNavigation(current: MainDestination.home),
        ),
      ),
    );
    final home = tester.getRect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.home)),
    );
    final more = tester.getRect(
      find.byKey(AppMainNavigation.tabKey(MainDestination.more)),
    );
    expect(home.left, greaterThan(16));
    expect(more.right, lessThan(390 - 16));
    expect(home.bottom, lessThanOrEqualTo(810));
    final surfaces = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AppMainNavigation),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(
      surfaces.any(
        (decoration) => decoration.borderRadius == BorderRadius.circular(999),
      ),
      isTrue,
    );
    expect(surfaces.any((decoration) => decoration.boxShadow != null), isTrue);
    expect(tester.takeException(), isNull);
  });

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
    expect(tester.getSize(find.byType(SvgPicture).first), const Size(26, 26));
    expect(find.byType(BackdropFilter), findsNothing);
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
