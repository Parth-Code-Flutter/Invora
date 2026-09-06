import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/widgets/app_main_navigation.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('fixed bar spans screen and keeps controls above bottom inset', (
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
    final bar = tester.getRect(find.byType(AppMainNavigation));
    expect(bar.left, 0);
    expect(bar.right, 390);
    expect(bar.bottom, 844);
    expect(
      tester.getRect(find.byKey(const ValueKey('content'))).bottom,
      bar.top,
    );
    final surface =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(AppMainNavigation),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(surface.borderRadius, isNull);
    expect(surface.boxShadow, isNull);
    expect(surface.color, isNotNull);
    for (final destination in MainDestination.values) {
      expect(
        tester
            .getRect(find.byKey(AppMainNavigation.tabKey(destination)))
            .bottom,
        lessThanOrEqualTo(810),
      );
    }
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
