import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/widgets/app_amount_text.dart';

void main() {
  testWidgets('amount text shrinks to a narrow bound instead of clipping', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 96,
            child: AppAmountText(
              amountMinor: 9999999900,
              symbol: '₹',
              hero: true,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ),
    );

    expect(find.text('₹99,999,999'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppAmountText)).width,
      lessThanOrEqualTo(96),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('small amounts keep their designed size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: AppAmountText(amountMinor: 55000, symbol: '₹'),
          ),
        ),
      ),
    );

    expect(find.text('₹550'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
