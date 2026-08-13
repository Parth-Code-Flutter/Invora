import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/widgets/app_invoice_summary_card.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';

void main() {
  testWidgets('narrow invoice card keeps issued and due dates readable', (
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
              dueDate: DateTime(2026, 8, 13),
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

    expect(find.textContaining('Issued'), findsOneWidget);
    expect(find.textContaining('11/08/2026'), findsOneWidget);
    expect(find.textContaining('Due'), findsWidgets);
    expect(find.textContaining('13/08/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
