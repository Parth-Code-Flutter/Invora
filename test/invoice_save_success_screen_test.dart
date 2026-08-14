import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/services/invoice_pdf_service.dart';
import 'package:creovo_invoice/modules/invoices/models/invoice_success_args.dart';
import 'package:creovo_invoice/modules/invoices/screens/invoice_save_success_screen.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('created invoice success screen shows actions and done', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: InvoiceSaveSuccessDialog(
            arguments: const InvoiceSaveSuccessArgs(
              invoiceId: 7,
              invoiceNumber: 'INV-0007',
              documentType: DocumentType.invoice,
              template: InvoiceTemplate.professional,
              wasUpdate: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.text('Invoice created successfully'), findsOneWidget);
    expect(find.text('INV-0007'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
    expect(find.text('View PDF'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(InvoiceSuccessAnimation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('updated invoice uses update confirmation copy', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: InvoiceSaveSuccessDialog(
            arguments: const InvoiceSaveSuccessArgs(
              invoiceId: 8,
              invoiceNumber: 'INV-0008',
              documentType: DocumentType.invoice,
              template: InvoiceTemplate.modern,
              wasUpdate: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Invoice updated successfully'), findsOneWidget);
    expect(find.text('UPDATED'), findsOneWidget);
  });
}
