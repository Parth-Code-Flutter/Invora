import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/widgets/app_invoice_summary_card.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';

void main() {
  testWidgets('invoice row shows number/date, name/status, and amounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInvoiceSummaryCard(
            invoice: InvoiceSummaryModel(
              id: 1,
              customerId: 1,
              invoiceNumber: 'INV-0002',
              customerName: 'Rinkal Ben',
              invoiceDate: DateTime(2026, 8, 11),
              dueDate: DateTime(2099, 8, 13),
              status: InvoiceStatus.unpaid,
              grandTotalMinor: 177200,
              balanceMinor: 177200,
            ),
            currencySymbol: '₹',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('INV-0002'), findsOneWidget);
    expect(find.textContaining('Due 13 Aug 2099'), findsOneWidget);
    expect(find.textContaining('Issued'), findsNothing);
    expect(tester.widget<Text>(find.text('Rinkal Ben')).style?.fontSize, 12);
    expect(find.text('Unpaid'), findsOneWidget);
    expect(find.text('₹1,772'), findsOneWidget);
    expect(find.textContaining('₹1,772 due'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid invoice omits due amount and does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AppInvoiceSummaryCard(
                invoice: InvoiceSummaryModel(
                  id: 1,
                  customerId: 1,
                  invoiceNumber: 'INV-0001',
                  customerName: 'Abhay Designer',
                  invoiceDate: DateTime(2026, 8, 11),
                  dueDate: DateTime(2026, 8, 13),
                  status: InvoiceStatus.paid,
                  grandTotalMinor: 55000,
                  balanceMinor: 0,
                ),
                currencySymbol: '₹',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('INV-0001'), findsOneWidget);
    expect(find.textContaining('11 Aug'), findsNothing);
    expect(find.text('Abhay Designer'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('₹550'), findsOneWidget);
    expect(find.textContaining('due'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow invoice row keeps lakh and crore amounts fully visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInvoiceSummaryCard(
            invoice: InvoiceSummaryModel(
              id: 3,
              customerId: 2,
              invoiceNumber: 'INV-0003',
              customerName: 'B E Dhaval',
              invoiceDate: DateTime(2026, 8, 13),
              dueDate: DateTime(2026, 8, 13),
              status: InvoiceStatus.unpaid,
              grandTotalMinor: 230580000,
              balanceMinor: 230580000,
            ),
            currencySymbol: '₹',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('INV-0003'), findsOneWidget);
    expect(find.text('B E Dhaval'), findsOneWidget);
    expect(find.text('₹2,305,800'), findsOneWidget);
    expect(find.textContaining('₹2,305,800 due'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInvoiceSummaryCard(
            invoice: InvoiceSummaryModel(
              id: 9,
              customerId: 9,
              invoiceNumber: 'INV-0009',
              customerName: 'Very Long Customer Name Private Limited',
              invoiceDate: DateTime(2026, 1, 1),
              dueDate: DateTime(2099, 1, 31),
              status: InvoiceStatus.partiallyPaid,
              grandTotalMinor: 9999999900,
              balanceMinor: 1234567890,
            ),
            currencySymbol: '₹',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('₹99,999,999'), findsOneWidget);
    expect(find.textContaining('₹12,345,678.90 due'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.textContaining('Due 31 Jan 2099'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
