import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/enums/tax_type.dart';
import '../../app/utils/currency_utils.dart';
import '../../app/utils/quantity_utils.dart';
import '../models/business_profile_model.dart';
import '../models/credit_note_model.dart';

class CreditNotePdfService {
  const CreditNotePdfService();

  Future<Uint8List> build({
    required CreditNoteModel note,
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
              'CREDIT NOTE',
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
                    pw.Text(
                      'Customer',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(note.customerName),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(note.creditNoteNumber),
                  pw.Text(_date(note.creditNoteDate)),
                  pw.Text('Against ${note.invoiceNumber}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Reason: ${note.reason}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const ['Sr.', 'Item', 'Qty', 'Rate', 'Tax', 'Amount'],
            data: [
              for (var index = 0; index < note.items.length; index++)
                [
                  '${index + 1}',
                  note.items[index].name,
                  QuantityUtils.toInputValue(note.items[index].quantityScaled),
                  CurrencyUtils.formatMinor(
                    note.items[index].rateMinor,
                    symbol: symbol,
                  ),
                  '${(note.items[index].taxRateBasisPoints / 100).toStringAsFixed(0)}%',
                  CurrencyUtils.formatMinor(
                    note.items[index].totalMinor,
                    symbol: symbol,
                  ),
                ],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', note.subtotalMinor, symbol),
                  if (note.itemDiscountMinor > 0)
                    _totalRow('Discount', -note.itemDiscountMinor, symbol),
                  if (note.taxType != TaxType.none)
                    _totalRow(
                      note.taxType == TaxType.igst ? 'IGST' : 'GST',
                      note.taxMinor,
                      symbol,
                    ),
                  _totalRow('Total', note.grandTotalMinor, symbol, bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _totalRow(
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

  String fileName(CreditNoteModel note) =>
      'CreditNote_${_safe(note.creditNoteNumber)}.pdf';

  Future<void> share({
    required CreditNoteModel note,
    required BusinessProfileModel business,
  }) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(note)),
    );
    await file.writeAsBytes(
      await build(note: note, business: business),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: note.creditNoteNumber),
    );
  }

  Future<void> print({
    required CreditNoteModel note,
    required BusinessProfileModel business,
  }) {
    return Printing.layoutPdf(
      name: fileName(note),
      onLayout: (_) => build(note: note, business: business),
    );
  }

  Future<String?> save({
    required CreditNoteModel note,
    required BusinessProfileModel business,
  }) async {
    final bytes = await build(note: note, business: business);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save credit note',
      fileName: fileName(note),
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
