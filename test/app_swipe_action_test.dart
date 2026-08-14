import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/widgets/app_swipe_action.dart';

void main() {
  testWidgets('swipe action requires a deliberate complete swipe', (
    tester,
  ) async {
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: AppSwipeAction(
              label: 'Swipe to create invoice',
              onCompleted: () => submissions++,
            ),
          ),
        ),
      ),
    );

    final control = find.byType(AppSwipeAction);
    await tester.drag(control, const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(submissions, 0);

    await tester.drag(control, const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(submissions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled swipe action cannot submit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSwipeAction(
            label: 'Swipe to update invoice',
            onCompleted: null,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(AppSwipeAction), const Offset(400, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Swipe to update invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
