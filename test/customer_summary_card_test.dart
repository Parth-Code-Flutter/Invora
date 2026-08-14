import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/modules/customers/screens/customer_list_screen.dart';

void main() {
  testWidgets('narrow customer card keeps large billed amounts off the name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 13);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerSummaryCard(
            customer: CustomerModel(
              id: 2,
              name: 'B E Dhaval',
              mobile: '9876543210',
              createdAt: now,
              updatedAt: now,
            ),
            billedMinor: 230580000,
            balanceMinor: 230580000,
            invoiceCount: 1,
            currencySymbol: '₹',
            onInvoice: () {},
            onEdit: () {},
            onConfirmDelete: () async => false,
            onDelete: () async {},
          ),
        ),
      ),
    );

    expect(find.text('B E Dhaval'), findsOneWidget);
    expect(tester.widget<Text>(find.text('B E Dhaval')).style?.fontSize, 14);
    expect(find.text('₹2,305,800'), findsOneWidget);
    expect(tester.widget<Text>(find.text('₹2,305,800')).style?.fontSize, 13);
    expect(find.text('9876543210'), findsNothing);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.text('1 invoice due'), findsOneWidget);
    expect(find.textContaining('Created'), findsNothing);
    expect(find.text('Due'), findsOneWidget);

    final nameRect = tester.getRect(find.text('B E Dhaval'));
    final amountRect = tester.getRect(find.text('₹2,305,800'));
    expect(nameRect.overlaps(amountRect), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow customer card scales crore totals without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 1, 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerSummaryCard(
            customer: CustomerModel(
              id: 9,
              name: 'Very Long Customer Name Private Limited',
              companyName: 'Northwind Trading Company',
              mobile: '9998887776',
              createdAt: now,
              updatedAt: now,
            ),
            billedMinor: 9999999900,
            balanceMinor: 0,
            invoiceCount: 4,
            currencySymbol: '₹',
            onInvoice: () {},
            onEdit: () {},
            onConfirmDelete: () async => false,
            onDelete: () async {},
          ),
        ),
      ),
    );

    expect(find.text('₹99,999,999'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
