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
import '../models/customer_statement_model.dart';

class CustomerStatementPdfService {
  const CustomerStatementPdfService();

  Future<Uint8List> build(CustomerStatementModel statement) async {
    final regular = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-Regular.ttf',
      ),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: regular),
    );
    final symbol = statement.business.currencySymbol;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              statement.business.businessName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'CUSTOMER STATEMENT',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('${_date(statement.from)} – ${_date(statement.to)}'),
            pw.SizedBox(height: 14),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
        ),
        build: (_) => [
          pw.Text(
            statement.customer.name,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          if (statement.customer.companyName != null)
            pw.Text(statement.customer.companyName!),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _metric('Opening', statement.openingBalanceMinor, symbol),
              _metric('Invoiced', statement.totalInvoicedMinor, symbol),
              _metric('Received', statement.totalReceivedMinor, symbol),
              _metric('Closing', statement.closingBalanceMinor, symbol),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Reference',
              'Description',
              'Debit',
              'Credit',
              'Balance',
            ],
            data: statement.entries
                .map(
                  (entry) => [
                    _date(entry.date),
                    entry.reference,
                    entry.description,
                    entry.debitMinor == 0
                        ? '—'
                        : CurrencyUtils.formatMinor(
                            entry.debitMinor,
                            symbol: symbol,
                          ),
                    entry.creditMinor == 0
                        ? '—'
                        : CurrencyUtils.formatMinor(
                            entry.creditMinor,
                            symbol: symbol,
                          ),
                    CurrencyUtils.formatMinor(
                      entry.balanceMinor,
                      symbol: symbol,
                    ),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            columnWidths: const {
              0: pw.FixedColumnWidth(48),
              1: pw.FixedColumnWidth(64),
              2: pw.FlexColumnWidth(2),
              3: pw.FixedColumnWidth(58),
              4: pw.FixedColumnWidth(58),
              5: pw.FixedColumnWidth(62),
            },
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _metric(String label, int amount, String symbol) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(9),
      margin: const pw.EdgeInsets.only(right: 5),
      color: PdfColors.grey100,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            CurrencyUtils.formatMinor(amount, symbol: symbol),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  String fileName(CustomerStatementModel statement) =>
      'Statement_${_safe(statement.customer.name)}_${_dateFile(statement.from)}_${_dateFile(statement.to)}.pdf';

  Future<void> printStatement(CustomerStatementModel statement) =>
      Printing.layoutPdf(
        name: fileName(statement),
        onLayout: (_) => build(statement),
      );

  Future<void> shareStatement(CustomerStatementModel statement) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(statement)),
    );
    await file.writeAsBytes(await build(statement), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Customer statement · ${statement.customer.name}',
      ),
    );
  }

  Future<String?> saveStatement(CustomerStatementModel statement) async {
    final bytes = await build(statement);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save customer statement',
      fileName: fileName(statement),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (path != null && !await File(path).exists()) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  String _safe(String value) => value
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _dateFile(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
}
