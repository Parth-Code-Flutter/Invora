import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/widgets/app_list_motion.dart';

void main() {
  testWidgets('list rows animate into place', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppListEntrance(index: 2, child: Text('Customer row')),
      ),
    );

    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Customer row'), findsOneWidget);
  });

  testWidgets('list motion is disabled for reduced-motion users', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppListEntrance(index: 3, child: Text('Static row')),
        ),
      ),
    );

    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.text('Static row'), findsOneWidget);
  });

  testWidgets('scroll motion keeps invoice rows readable while scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (_, index) => AppScrollMotion(
              child: SizedBox(height: 80, child: Text('Invoice $index')),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Invoice 0'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pump();
    expect(find.text('Invoice 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
