import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/modules/customers/widgets/customer_list_overview.dart';

void main() {
  testWidgets('customer overview fits totals on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerListOverview(
            totalCustomers: 12,
            amountDueMinor: 737000,
            dueCustomers: 1,
            paidAmountMinor: 1221000,
            paidCustomers: 4,
            currencySymbol: '₹',
          ),
        ),
      ),
    );

    expect(find.text('Total customers'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Amount due'), findsOneWidget);
    expect(find.text('₹7,370'), findsOneWidget);
    expect(find.text('Paid amount'), findsOneWidget);
    expect(find.text('₹12,210'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
