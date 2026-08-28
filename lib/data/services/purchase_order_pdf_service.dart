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
import '../../app/utils/quantity_utils.dart';
import '../models/business_profile_model.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderPdfService {
  const PurchaseOrderPdfService();

  Future<Uint8List> build({
    required PurchaseOrderModel order,
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
              'PURCHASE ORDER',
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
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(order.supplier.name),
                    if ((order.supplier.companyName ?? '').trim().isNotEmpty)
                      pw.Text(order.supplier.companyName!),
                    if ((order.supplier.address ?? '').trim().isNotEmpty)
                      pw.Text(order.supplier.address!),
                    if ((order.supplier.gstin ?? '').trim().isNotEmpty)
                      pw.Text('GSTIN ${order.supplier.gstin}'),
                    if ((order.supplier.mobile ?? '').trim().isNotEmpty)
                      pw.Text(order.supplier.mobile!),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(order.orderNumber),
                    pw.Text('Date ${_date(order.orderDate)}'),
                    if (order.expectedDate != null)
                      pw.Text('Expected ${_date(order.expectedDate!)}'),
                    pw.Text(PurchaseOrderLabels.status(order.status)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Item', 'HSN/SAC', 'Qty', 'Unit', 'Rate', 'Tax'],
            data: [
              for (final item in order.items)
                [
                  item.name,
                  item.hsnSac ?? '',
                  QuantityUtils.toInputValue(item.orderedQuantityScaled),
                  item.unit,
                  CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol),
                  '${item.taxRateBasisPoints / 100}%',
                ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if ((order.terms ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Terms',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(order.terms!),
          ],
          if ((order.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(order.notes!),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'This purchase order does not change stock or payable until goods are billed.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          if (order.isCancelled) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Cancelled: ${order.cancellationReason ?? ''}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  String fileName(PurchaseOrderModel order) =>
      'Purchase_Order_${_safe(order.orderNumber)}.pdf';

  Future<void> share({
    required PurchaseOrderModel order,
    required BusinessProfileModel business,
  }) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(order)),
    );
    await file.writeAsBytes(
      await build(order: order, business: business),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: order.orderNumber),
    );
  }

  Future<void> print({
    required PurchaseOrderModel order,
    required BusinessProfileModel business,
  }) {
    return Printing.layoutPdf(
      name: fileName(order),
      onLayout: (_) => build(order: order, business: business),
    );
  }

  Future<String?> save({
    required PurchaseOrderModel order,
    required BusinessProfileModel business,
  }) async {
    final bytes = await build(order: order, business: business);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save purchase order',
      fileName: fileName(order),
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
