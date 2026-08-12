import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/utils/currency_utils.dart';
import '../models/payment_receipt_model.dart';

class PaymentReceiptPdfService {
  const PaymentReceiptPdfService();

  Future<Uint8List> build(PaymentReceiptModel receipt) async {
    if (receipt.payment.isReversal || receipt.payment.isReversed) {
      throw StateError('A reversed payment cannot generate a receipt.');
    }
    if (receipt.payment.amountMinor <= 0) {
      throw StateError('Only received payments can generate receipts.');
    }
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DMSans/DMSans-Regular.ttf'),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: regular),
    );
    final symbol = receipt.business.currencySymbol;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(34),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      receipt.business.businessName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('PAYMENT RECEIPT'),
                  ],
                ),
                pw.Text(
                  receipt.receiptNumber,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 28),
            pw.Text('AMOUNT RECEIVED'),
            pw.Text(
              CurrencyUtils.formatMinor(
                receipt.payment.amountMinor,
                symbol: symbol,
              ),
              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 24),
            _row('Received from', receipt.invoice.customer.name),
            _row('Invoice', receipt.invoice.invoiceNumber),
            _row('Date', _date(receipt.payment.paidAt)),
            _row('Payment method', receipt.payment.method ?? 'Payment'),
            if (receipt.payment.reference?.isNotEmpty ?? false)
              _row('Reference', receipt.payment.reference!),
            pw.Divider(height: 28),
            _row(
              'Remaining balance',
              CurrencyUtils.formatMinor(
                receipt.balanceAfterMinor,
                symbol: symbol,
              ),
              bold: true,
            ),
            pw.Spacer(),
            pw.Center(child: pw.Text('Thank you for your payment.')),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Generated offline with Creovo Invoice',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      ),
    );
    return document.save();
  }

  pw.Widget _row(String label, String value, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 7),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  String fileName(PaymentReceiptModel receipt) =>
      'Receipt_${receipt.receiptNumber}_${receipt.invoice.invoiceNumber}.pdf';

  Future<void> printReceipt(PaymentReceiptModel receipt) => Printing.layoutPdf(
    name: fileName(receipt),
    onLayout: (_) => build(receipt),
  );

  Future<void> shareReceipt(PaymentReceiptModel receipt) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(receipt)),
    );
    await file.writeAsBytes(await build(receipt), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: receipt.receiptNumber),
    );
  }

  Future<String?> saveReceipt(PaymentReceiptModel receipt) async {
    final bytes = await build(receipt);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save payment receipt',
      fileName: fileName(receipt),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (path != null && !await File(path).exists()) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
