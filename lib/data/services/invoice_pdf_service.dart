import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/utils/currency_utils.dart';
import '../../app/utils/quantity_utils.dart';
import '../models/business_profile_model.dart';
import '../models/invoice_model.dart';
import 'invoice_validation_service.dart';

enum InvoiceTemplate { minimal, professional, modern, elegant, compact }

extension InvoiceTemplateLabel on InvoiceTemplate {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

/// Builds every invoice template from the same persisted snapshot. This keeps
/// rendering concerns separate from invoice calculations and lifecycle rules.
class InvoicePdfService {
  const InvoicePdfService();

  static const _validator = InvoiceValidationService();

  Future<Uint8List> build({
    required InvoiceModel invoice,
    required BusinessProfileModel business,
    required InvoiceTemplate template,
  }) async {
    final validation = _validator.validateRequired(invoice);
    if (validation != null) throw ArgumentError(validation);
    if (business.businessName.trim().isEmpty) {
      throw ArgumentError('Complete business setup before generating a PDF.');
    }
    final document = pw.Document();
    final style = _styleFor(template);
    final logo = await _memoryImage(business.logoPath);
    final signature = await _memoryImage(business.signaturePath);
    final paymentQr = await _memoryImage(business.paymentQrPath);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(style.margin),
        header: (_) => _header(business, invoice, style, logo),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated offline with Creovo Invoice',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: style.spacing),
          _customer(invoice, style),
          pw.SizedBox(height: style.spacing),
          _items(invoice, business.currencySymbol, style),
          pw.SizedBox(height: style.spacing),
          _totals(invoice, business.currencySymbol, style),
          if (invoice.notes != null || invoice.terms != null) ...[
            pw.SizedBox(height: style.spacing),
            _notes(invoice),
          ],
          pw.SizedBox(height: style.spacing),
          _paymentDetails(business, paymentQr, signature),
        ],
      ),
    );
    return document.save();
  }

  Future<void> printInvoice({
    required InvoiceModel invoice,
    required BusinessProfileModel business,
    required InvoiceTemplate template,
  }) async {
    await Printing.layoutPdf(
      name: fileName(invoice),
      onLayout: (_) =>
          build(invoice: invoice, business: business, template: template),
    );
  }

  Future<void> shareInvoice({
    required InvoiceModel invoice,
    required BusinessProfileModel business,
    required InvoiceTemplate template,
  }) async {
    final bytes = await build(
      invoice: invoice,
      business: business,
      template: template,
    );
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, fileName(invoice)));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: invoice.invoiceNumber),
    );
  }

  Future<String?> saveInvoice({
    required InvoiceModel invoice,
    required BusinessProfileModel business,
    required InvoiceTemplate template,
  }) async {
    final bytes = await build(
      invoice: invoice,
      business: business,
      template: template,
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: fileName(invoice),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (path != null && !await File(path).exists()) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  String fileName(InvoiceModel invoice) {
    final customer = invoice.customer.companyName ?? invoice.customer.name;
    String safe(String value) => value
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final type = invoice.documentType == DocumentType.quotation
        ? 'Quotation'
        : 'Invoice';
    return '${type}_${safe(invoice.invoiceNumber)}_${safe(customer)}.pdf';
  }

  pw.Widget _header(
    BusinessProfileModel business,
    InvoiceModel invoice,
    _PdfStyle style,
    pw.MemoryImage? logo,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(style.headerPadding),
      color: style.headerColor,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.contain),
            pw.SizedBox(width: 10),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  business.businessName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: style.headerText,
                  ),
                ),
                if (business.address != null)
                  pw.Text(
                    business.address!,
                    style: pw.TextStyle(color: style.headerText),
                  ),
                if (business.gstin != null)
                  pw.Text(
                    'GSTIN: ${business.gstin}',
                    style: pw.TextStyle(color: style.headerText),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                invoice.documentType == DocumentType.quotation
                    ? 'QUOTATION'
                    : 'INVOICE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: style.headerText,
                ),
              ),
              pw.Text(
                invoice.invoiceNumber,
                style: pw.TextStyle(color: style.headerText),
              ),
              pw.Text(
                _date(invoice.invoiceDate),
                style: pw.TextStyle(color: style.headerText),
              ),
              if (invoice.dueDate != null)
                pw.Text(
                  'Due ${_date(invoice.dueDate!)}',
                  style: pw.TextStyle(color: style.headerText),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _customer(InvoiceModel invoice, _PdfStyle style) => pw.Container(
    padding: pw.EdgeInsets.all(style.blockPadding),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: style.accent,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          invoice.customer.name,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        if (invoice.customer.companyName != null)
          pw.Text(invoice.customer.companyName!),
        if (invoice.customer.address != null)
          pw.Text(invoice.customer.address!),
        if (invoice.customer.gstin != null)
          pw.Text('GSTIN: ${invoice.customer.gstin}'),
      ],
    ),
  );

  pw.Widget _items(InvoiceModel invoice, String symbol, _PdfStyle style) {
    final headers = ['Item', 'HSN/SAC', 'Qty', 'Rate', 'Tax', 'Amount'];
    final data = invoice.items.asMap().entries.map((entry) {
      final item = entry.value;
      final result = invoice.calculation.items[entry.key];
      return [
        item.name,
        item.hsnSac ?? '-',
        '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit}',
        CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol),
        '${item.taxRateBasisPoints / 100}%',
        CurrencyUtils.formatMinor(result.totalMinor, symbol: symbol),
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerDecoration: pw.BoxDecoration(color: style.accent),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      cellPadding: pw.EdgeInsets.all(style.compact ? 4 : 7),
      border: style.minimal
          ? null
          : pw.TableBorder.all(color: PdfColors.grey300),
    );
  }

  pw.Widget _totals(InvoiceModel invoice, String symbol, _PdfStyle style) {
    final calculation = invoice.calculation;
    pw.Widget row(String label, int value, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
          pw.Text(
            CurrencyUtils.formatMinor(value, symbol: symbol),
            style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
        ],
      ),
    );
    return pw.Row(
      children: [
        pw.Spacer(),
        pw.SizedBox(
          width: 230,
          child: pw.Column(
            children: [
              row('Subtotal', calculation.subtotalMinor),
              if (calculation.itemDiscountTotalMinor > 0)
                row('Item discount', -calculation.itemDiscountTotalMinor),
              if (calculation.invoiceDiscountMinor > 0)
                row('Invoice discount', -calculation.invoiceDiscountMinor),
              if (calculation.cgstMinor > 0) row('CGST', calculation.cgstMinor),
              if (calculation.sgstMinor > 0) row('SGST', calculation.sgstMinor),
              if (calculation.igstMinor > 0) row('IGST', calculation.igstMinor),
              if (calculation.additionalChargeTotalMinor > 0)
                row(
                  'Additional charges',
                  calculation.additionalChargeTotalMinor,
                ),
              pw.Divider(color: style.accent),
              row('Grand total', calculation.grandTotalMinor, bold: true),
              row('Paid', calculation.paidAmountMinor),
              row('Balance due', calculation.balanceDueMinor, bold: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _notes(InvoiceModel invoice) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (invoice.notes != null) ...[
        pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.notes!),
      ],
      if (invoice.terms != null) ...[
        pw.SizedBox(height: 8),
        pw.Text('Terms', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.terms!),
      ],
    ],
  );

  pw.Widget _paymentDetails(
    BusinessProfileModel business,
    pw.MemoryImage? qr,
    pw.MemoryImage? signature,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (business.bankName != null)
                pw.Text('Bank: ${business.bankName}'),
              if (business.accountNumber != null)
                pw.Text('Account: ${business.accountNumber}'),
              if (business.ifsc != null) pw.Text('IFSC: ${business.ifsc}'),
              if (business.upiId != null) pw.Text('UPI: ${business.upiId}'),
            ],
          ),
        ),
        if (qr != null) pw.Image(qr, width: 60, height: 60),
        if (signature != null) ...[
          pw.SizedBox(width: 16),
          pw.Image(signature, width: 90, height: 45),
        ],
      ],
    );
  }

  Future<pw.MemoryImage?> _memoryImage(String? path) async {
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return pw.MemoryImage(await file.readAsBytes());
  }

  _PdfStyle _styleFor(InvoiceTemplate template) => switch (template) {
    InvoiceTemplate.minimal => const _PdfStyle(
      PdfColors.black,
      PdfColors.white,
      PdfColors.black,
      28,
      10,
      8,
      true,
      false,
    ),
    InvoiceTemplate.professional => const _PdfStyle(
      PdfColor.fromInt(0xFF7138E8),
      PdfColor.fromInt(0xFF7138E8),
      PdfColors.white,
      26,
      14,
      9,
      false,
      false,
    ),
    InvoiceTemplate.modern => const _PdfStyle(
      PdfColor.fromInt(0xFF14B8A6),
      PdfColor.fromInt(0xFFEEF2FF),
      PdfColors.black,
      24,
      16,
      10,
      false,
      false,
    ),
    InvoiceTemplate.elegant => const _PdfStyle(
      PdfColor.fromInt(0xFF334155),
      PdfColors.white,
      PdfColors.black,
      34,
      12,
      12,
      true,
      false,
    ),
    InvoiceTemplate.compact => const _PdfStyle(
      PdfColor.fromInt(0xFF7138E8),
      PdfColor.fromInt(0xFFF1F5F9),
      PdfColors.black,
      20,
      8,
      5,
      false,
      true,
    ),
  };

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _PdfStyle {
  const _PdfStyle(
    this.accent,
    this.headerColor,
    this.headerText,
    this.margin,
    this.headerPadding,
    this.spacing,
    this.minimal,
    this.compact,
  );
  final PdfColor accent;
  final PdfColor headerColor;
  final PdfColor headerText;
  final double margin;
  final double headerPadding;
  final double spacing;
  final bool minimal;
  final bool compact;
  double get blockPadding => compact ? 6 : 10;
}
