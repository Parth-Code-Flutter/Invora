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
import '../../app/utils/tax_utils.dart';
import '../models/business_profile_model.dart';
import '../models/expense_model.dart';

class ExpensePdfService {
  const ExpensePdfService();

  Future<Uint8List> build({
    required ExpenseModel expense,
    required BusinessProfileModel business,
  }) async {
    if (business.businessName.trim().isEmpty) {
      throw ArgumentError('Complete business setup before generating a PDF.');
    }
    final regular = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-Regular.ttf',
      ),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-SemiBold.ttf',
      ),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final symbol = business.currencySymbol;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              business.businessName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'EXPENSE',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated offline with Creovo Billing',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Paid to'),
                    pw.Text(
                      expense.payee,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Category: ${expense.category}'),
                    pw.Text('Paid by: ${expense.paymentMethod}'),
                    if (expense.itcEligible) pw.Text('ITC eligible'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(expense.expenseNumber),
                  pw.Text(_date(expense.expenseDate)),
                  if (expense.isCancelled)
                    pw.Text(
                      'CANCELLED',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _amountRow('Taxable', expense.taxableMinor, symbol),
          if (expense.taxMinor > 0)
            _amountRow(
              'GST ${TaxUtils.formatBasisPoints(expense.taxRateBasisPoints)}',
              expense.taxMinor,
              symbol,
            ),
          _amountRow('Total paid', expense.grandTotalMinor, symbol, bold: true),
          if (expense.notes != null && expense.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Note'),
            pw.Text(expense.notes!.trim()),
          ],
          if (expense.isCancelled) ...[
            pw.SizedBox(height: 16),
            pw.Text('Cancelled: ${expense.cancellationReason ?? ''}'),
          ],
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _amountRow(
    String label,
    int amountMinor,
    String symbol, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            CurrencyUtils.formatMinor(amountMinor, symbol: symbol),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String fileName(ExpenseModel expense) =>
      'Expense_${_safe(expense.expenseNumber)}.pdf';

  Future<void> share({
    required ExpenseModel expense,
    required BusinessProfileModel business,
  }) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(expense)),
    );
    await file.writeAsBytes(
      await build(expense: expense, business: business),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: expense.expenseNumber),
    );
  }

  Future<void> print({
    required ExpenseModel expense,
    required BusinessProfileModel business,
  }) {
    return Printing.layoutPdf(
      name: fileName(expense),
      onLayout: (_) => build(expense: expense, business: business),
    );
  }

  Future<String?> save({
    required ExpenseModel expense,
    required BusinessProfileModel business,
  }) async {
    final bytes = await build(expense: expense, business: business);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save expense',
      fileName: fileName(expense),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
