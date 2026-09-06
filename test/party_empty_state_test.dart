import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_party_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final supplier in [false, true]) {
    for (final height in [320.0, 700.0]) {
      testWidgets(
        'party empty supplier=$supplier height=$height stays actionable',
        (tester) async {
          tester.view.physicalSize = Size(320, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var added = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: Size(320, height),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: AppPartyEmptyState(
                    supplier: supplier,
                    onAdd: () => added = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = find.text(supplier ? 'Add supplier' : 'Add customer');
          await tester.ensureVisible(action);
          await tester.tap(action);
          expect(added, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
