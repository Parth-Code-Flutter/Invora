import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/modules/invoices/widgets/invoice_list_overview.dart';

void main() {
  testWidgets('invoice overview calculates totals and fits a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvoiceListOverview(
            currencySymbol: '₹',
            now: DateTime(2026, 8, 14),
            invoices: [
              InvoiceSummaryModel(
                id: 1,
                invoiceNumber: 'INV-1',
                customerName: 'Paid customer',
                invoiceDate: DateTime(2026, 8, 10),
                status: InvoiceStatus.paid,
                grandTotalMinor: 1100000,
                balanceMinor: 0,
              ),
              InvoiceSummaryModel(
                id: 2,
                invoiceNumber: 'INV-2',
                customerName: 'Overdue customer',
                invoiceDate: DateTime(2026, 8, 10),
                dueDate: DateTime(2026, 8, 12),
                status: InvoiceStatus.unpaid,
                grandTotalMinor: 858000,
                balanceMinor: 858000,
              ),
              InvoiceSummaryModel(
                id: 3,
                invoiceNumber: 'INV-3',
                customerName: 'Pending customer',
                invoiceDate: DateTime(2026, 8, 13),
                dueDate: DateTime(2026, 8, 20),
                status: InvoiceStatus.unpaid,
                grandTotalMinor: 1876000,
                balanceMinor: 1876000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('RECEIVED'), findsOneWidget);
    expect(find.text('₹11,000'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('₹18,760'), findsOneWidget);
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('₹8,580'), findsOneWidget);
    expect(find.text('This month'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
