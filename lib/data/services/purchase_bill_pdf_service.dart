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
import '../models/business_profile_model.dart';
import '../models/purchase_models.dart';

class PurchaseBillPdfService {
  const PurchaseBillPdfService();

  Future<Uint8List> build({
    required PurchaseBillModel bill,
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
              'PURCHASE BILL',
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
                      'Supplier',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      bill.supplierName,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    bill.billNumber,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Bill date ${_date(bill.billDate)}'),
                  if (bill.dueDate != null)
                    pw.Text('Due ${_date(bill.dueDate!)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Item', 'Qty', 'Rate', 'GST', 'Amount'],
            data: [
              for (var i = 0; i < bill.items.length; i++)
                [
                  '${i + 1}',
                  [
                    bill.items[i].name,
                    if ((bill.items[i].hsnSac ?? '').isNotEmpty)
                      'HSN/SAC ${bill.items[i].hsnSac}',
                  ].join('\n'),
                  '${_qty(bill.items[i].quantity)} ${bill.items[i].unit}',
                  CurrencyUtils.formatMinor(
                    bill.items[i].rateMinor,
                    symbol: symbol,
                  ),
                  '${_qty(bill.items[i].taxRate)}%',
                  CurrencyUtils.formatMinor(
                    bill.items[i].totalMinor,
                    symbol: symbol,
                  ),
                ],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            columnWidths: const {
              0: pw.FixedColumnWidth(22),
              1: pw.FlexColumnWidth(3),
              2: pw.FixedColumnWidth(64),
              3: pw.FixedColumnWidth(62),
              4: pw.FixedColumnWidth(40),
              5: pw.FixedColumnWidth(70),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', bill.subtotalMinor, symbol),
                  if (bill.taxMinor > 0)
                    _totalRow('GST', bill.taxMinor, symbol),
                  if (bill.discountMinor > 0)
                    _totalRow('Discount', -bill.discountMinor, symbol),
                  if (bill.additionalChargesMinor > 0)
                    _totalRow(
                      'Other charges',
                      bill.additionalChargesMinor,
                      symbol,
                    ),
                  _totalRow('Total', bill.totalMinor, symbol, bold: true),
                  _totalRow('Paid', bill.paidMinor, symbol),
                  _totalRow('Balance', bill.balanceMinor, symbol, bold: true),
                ],
              ),
            ),
          ),
          if ((bill.placeOfSupply ?? '').isNotEmpty ||
              bill.reverseCharge ||
              !bill.itcEligible) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  pw.Text(
                    'Tax: ${bill.taxMode == 'igst'
                        ? 'IGST'
                        : bill.taxMode == 'exempt'
                        ? 'Exempt'
                        : 'CGST + SGST'}',
                  ),
                  if ((bill.placeOfSupply ?? '').isNotEmpty)
                    pw.Text('Place of supply: ${bill.placeOfSupply}'),
                  pw.Text(
                    'ITC: ${bill.itcEligible ? 'Eligible' : 'Not eligible'}',
                  ),
                  if (bill.reverseCharge) pw.Text('Reverse charge: Applicable'),
                ],
              ),
            ),
          ],
          if ((bill.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(bill.notes!.trim()),
          ],
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _totalRow(
    String label,
    int amount,
    String symbol, {
    bool bold = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
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
          CurrencyUtils.formatMinor(amount, symbol: symbol),
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  String fileName(PurchaseBillModel bill) =>
      'Purchase_${_safe(bill.billNumber)}_${_safe(bill.supplierName)}.pdf';

  Future<void> printBill({
    required PurchaseBillModel bill,
    required BusinessProfileModel business,
  }) => Printing.layoutPdf(
    name: fileName(bill),
    onLayout: (_) => build(bill: bill, business: business),
  );

  Future<void> shareBill({
    required PurchaseBillModel bill,
    required BusinessProfileModel business,
  }) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(bill)),
    );
    await file.writeAsBytes(
      await build(bill: bill, business: business),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: bill.billNumber),
    );
  }

  Future<String?> saveBill({
    required PurchaseBillModel bill,
    required BusinessProfileModel business,
  }) async {
    final bytes = await build(bill: bill, business: business);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save purchase bill PDF',
      fileName: fileName(bill),
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

  String _qty(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
