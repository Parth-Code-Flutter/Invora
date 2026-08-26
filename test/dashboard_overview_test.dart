import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/report_summary_model.dart';
import 'package:creovo_invoice/modules/dashboard/screens/dashboard_screen.dart';

void main() {
  testWidgets('overview shows invoiced, received, and outstanding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardOverviewCard(
            symbol: '₹',
            report: ReportSummaryModel(
              totalSalesMinor: 230800000,
              totalReceivedMinor: 65000,
              outstandingMinor: 230747200,
              invoiceCount: 3,
              monthlySales: [
                MonthlySalesPoint(
                  month: DateTime(2026, 3),
                  amountMinor: 5000000,
                ),
                MonthlySalesPoint(
                  month: DateTime(2026, 8),
                  amountMinor: 230800000,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Invoiced'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('₹2,308,000'), findsWidgets);
    expect(find.text('₹650'), findsOneWidget);
    expect(find.text('₹2,307,472'), findsOneWidget);
    expect(find.text('3 invoices'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview metrics shrink crore values instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardOverviewCard(
            symbol: '₹',
            report: ReportSummaryModel(
              totalSalesMinor: 9999999900,
              totalReceivedMinor: 1234567890,
              outstandingMinor: 8765432100,
              invoiceCount: 12,
            ),
          ),
        ),
      ),
    );

    expect(find.text('₹99,999,999'), findsWidgets);
    expect(find.text('₹12,345,678.90'), findsOneWidget);
    expect(find.text('₹87,654,321'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
