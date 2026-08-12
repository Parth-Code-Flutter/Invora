import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/utils/currency_utils.dart';
import '../../app/utils/product_attribute_utils.dart';
import '../../app/utils/quantity_utils.dart';
import '../models/business_profile_model.dart';
import '../models/invoice_model.dart';
import 'invoice_validation_service.dart';
import 'product_settings_service.dart';

enum InvoiceTemplate { minimal, professional, modern, elegant, compact }

extension InvoiceTemplateLabel on InvoiceTemplate {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

/// Builds every invoice template from the same persisted snapshot. This keeps
/// rendering concerns separate from invoice calculations and lifecycle rules.
class InvoicePdfService {
  const InvoicePdfService({this.productSettings});

  final ProductSettingsService? productSettings;

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
    final document = pw.Document(theme: await _documentTheme());
    final style = _styleFor(template);
    final logo = await _memoryImage(business.logoPath);
    final signature = await _memoryImage(business.signaturePath);
    final paymentQr = await _memoryImage(business.paymentQrPath);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(style.margin),
        header: (_) => template == InvoiceTemplate.professional
            ? _professionalHeader(business, invoice, style, logo)
            : _header(business, invoice, style, logo),
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
        build: (_) => template == InvoiceTemplate.professional
            ? _professionalBody(business, invoice, style, paymentQr, signature)
            : [
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

  pw.Widget _professionalHeader(
    BusinessProfileModel business,
    InvoiceModel invoice,
    _PdfStyle style,
    pw.MemoryImage? logo,
  ) {
    final businessAddress = _address([
      business.address,
      business.city,
      business.state,
      business.pinCode,
    ]);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            height: 70,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: logo != null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.all(7),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  )
                : pw.Text(
                    business.businessName.trim().substring(0, 1).toUpperCase(),
                    style: pw.TextStyle(
                      color: style.accent,
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  business.businessName,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_hasText(business.ownerName))
                  pw.Text(
                    business.ownerName!,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (businessAddress.isNotEmpty)
                  pw.Text(
                    businessAddress,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (_hasText(business.mobile) || _hasText(business.email))
                  pw.Text(
                    _join([business.mobile, business.email], separator: ' | '),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (_hasText(business.gstin))
                  pw.Text(
                    'GSTIN: ${business.gstin}',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                invoice.documentType == DocumentType.quotation
                    ? 'QUOTATION'
                    : 'INVOICE',
                style: pw.TextStyle(
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                  color: style.accent,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                invoice.invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _professionalBody(
    BusinessProfileModel business,
    InvoiceModel invoice,
    _PdfStyle style,
    pw.MemoryImage? paymentQr,
    pw.MemoryImage? signature,
  ) => [
    pw.SizedBox(height: 16),
    _professionalParties(invoice, style),
    pw.SizedBox(height: 16),
    _professionalItems(invoice, business.currencySymbol, style),
    pw.SizedBox(height: 14),
    _professionalSettlement(
      business,
      invoice,
      business.currencySymbol,
      style,
      paymentQr,
    ),
    if (invoice.notes != null || invoice.terms != null) ...[
      pw.SizedBox(height: 14),
      _professionalNotes(invoice, style),
    ],
    pw.SizedBox(height: 20),
    _professionalAuthorization(business, signature, style),
  ];

  pw.Widget _professionalParties(InvoiceModel invoice, _PdfStyle style) {
    final customer = invoice.customer;
    final customerAddress = _address([
      customer.address,
      customer.city,
      customer.state,
      customer.pinCode,
    ]);
    pw.Widget detail(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 54,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _professionalLabel('BILL TO', style),
              pw.SizedBox(height: 5),
              pw.Text(
                customer.name,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (_hasText(customer.companyName))
                pw.Text(customer.companyName!),
              if (_hasText(customer.mobile)) pw.Text(customer.mobile!),
              if (_hasText(customer.email)) pw.Text(customer.email!),
              if (customerAddress.isNotEmpty) pw.Text(customerAddress),
              if (_hasText(customer.gstin)) pw.Text('GSTIN: ${customer.gstin}'),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.SizedBox(
          width: 185,
          child: pw.Column(
            children: [
              detail('Invoice #', invoice.invoiceNumber),
              detail('Issue date', _date(invoice.invoiceDate)),
              detail(
                'Due date',
                invoice.dueDate == null
                    ? 'On receipt'
                    : _date(invoice.dueDate!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _professionalItems(
    InvoiceModel invoice,
    String symbol,
    _PdfStyle style,
  ) {
    pw.Widget cell(
      pw.Widget child, {
      pw.Alignment alignment = pw.Alignment.centerLeft,
      PdfColor? color,
      double vertical = 7,
    }) => pw.Container(
      alignment: alignment,
      color: color,
      padding: pw.EdgeInsets.symmetric(horizontal: 7, vertical: vertical),
      child: child,
    );
    pw.Widget header(
      String value, {
      pw.Alignment alignment = pw.Alignment.centerLeft,
    }) => cell(
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: style.accent,
        ),
      ),
      alignment: alignment,
      color: const PdfColor.fromInt(0xFFF2F6FA),
      vertical: 6,
    );
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          header('ITEM / DESCRIPTION'),
          header('QTY', alignment: pw.Alignment.centerRight),
          header('RATE', alignment: pw.Alignment.centerRight),
          header('TAX', alignment: pw.Alignment.centerRight),
          header('AMOUNT', alignment: pw.Alignment.centerRight),
        ],
      ),
      ...invoice.items.asMap().entries.map((entry) {
        final item = entry.value;
        final result = invoice.calculation.items[entry.key];
        final background = entry.key.isOdd
            ? PdfColors.grey100
            : PdfColors.white;
        return pw.TableRow(
          children: [
            cell(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _itemTitle(item),
                    style: pw.TextStyle(
                      fontSize: 8.7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (_hasText(item.description))
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        item.description!,
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  if (_hasText(item.hsnSac))
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'HSN/SAC: ${item.hsnSac}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                ],
              ),
              color: background,
            ),
            cell(
              pw.Text(
                '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit}',
                style: const pw.TextStyle(fontSize: 8.2),
              ),
              alignment: pw.Alignment.centerRight,
              color: background,
            ),
            cell(
              pw.Text(
                CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol),
                style: const pw.TextStyle(fontSize: 8.2),
              ),
              alignment: pw.Alignment.centerRight,
              color: background,
            ),
            cell(
              pw.Text(
                '${item.taxRateBasisPoints / 100}%',
                style: const pw.TextStyle(fontSize: 8.2),
              ),
              alignment: pw.Alignment.centerRight,
              color: background,
            ),
            cell(
              pw.Text(
                CurrencyUtils.formatMinor(result.totalMinor, symbol: symbol),
                style: pw.TextStyle(
                  fontSize: 8.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              alignment: pw.Alignment.centerRight,
              color: background,
            ),
          ],
        );
      }),
    ];
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(1.15),
        2: pw.FlexColumnWidth(1.25),
        3: pw.FlexColumnWidth(.9),
        4: pw.FlexColumnWidth(1.45),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: .5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: .7),
      ),
      children: rows,
    );
  }

  pw.Widget _professionalSettlement(
    BusinessProfileModel business,
    InvoiceModel invoice,
    String symbol,
    _PdfStyle style,
    pw.MemoryImage? paymentQr,
  ) {
    final calculation = invoice.calculation;
    pw.Widget totalRow(String label, int value, {bool emphasized = false}) =>
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: emphasized ? const PdfColor.fromInt(0xFFF2F6FA) : null,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: emphasized ? 9 : 8,
                  fontWeight: emphasized ? pw.FontWeight.bold : null,
                ),
              ),
              pw.Text(
                CurrencyUtils.formatMinor(value, symbol: symbol),
                style: pw.TextStyle(
                  fontSize: emphasized ? 9 : 8,
                  fontWeight: emphasized ? pw.FontWeight.bold : null,
                  color: emphasized ? style.accent : PdfColors.black,
                ),
              ),
            ],
          ),
        );
    final hasPaymentDetails = [
      business.bankName,
      business.accountNumber,
      business.ifsc,
      business.upiId,
    ].any(_hasText);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (hasPaymentDetails || paymentQr != null) ...[
                _professionalLabel('PAYMENT INSTRUCTIONS', style),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (_hasText(business.bankName))
                            pw.Text('Bank: ${business.bankName}'),
                          if (_hasText(business.accountNumber))
                            pw.Text('Account: ${business.accountNumber}'),
                          if (_hasText(business.ifsc))
                            pw.Text('IFSC: ${business.ifsc}'),
                          if (_hasText(business.upiId))
                            pw.Text('UPI: ${business.upiId}'),
                        ],
                      ),
                    ),
                    if (paymentQr != null) ...[
                      pw.SizedBox(width: 10),
                      pw.Image(paymentQr, width: 54, height: 54),
                    ],
                  ],
                ),
              ] else
                pw.Text(
                  'Thank you for your business.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 26),
        pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              totalRow('Subtotal', calculation.subtotalMinor),
              if (calculation.itemDiscountTotalMinor > 0)
                totalRow('Item discount', -calculation.itemDiscountTotalMinor),
              if (calculation.invoiceDiscountMinor > 0)
                totalRow('Invoice discount', -calculation.invoiceDiscountMinor),
              if (calculation.cgstMinor > 0)
                totalRow('CGST', calculation.cgstMinor),
              if (calculation.sgstMinor > 0)
                totalRow('SGST', calculation.sgstMinor),
              if (calculation.igstMinor > 0)
                totalRow('IGST', calculation.igstMinor),
              if (calculation.additionalChargeTotalMinor > 0)
                totalRow(
                  'Additional charges',
                  calculation.additionalChargeTotalMinor,
                ),
              pw.Divider(color: PdfColors.grey400, height: 8),
              totalRow('Grand total', calculation.grandTotalMinor),
              totalRow('Paid', calculation.paidAmountMinor),
              pw.SizedBox(height: 3),
              totalRow(
                'AMOUNT DUE',
                calculation.balanceDueMinor,
                emphasized: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _professionalNotes(InvoiceModel invoice, _PdfStyle style) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300),
            bottom: pw.BorderSide(color: PdfColors.grey300),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_hasText(invoice.notes)) ...[
              _professionalLabel('NOTES', style),
              pw.SizedBox(height: 3),
              pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 8)),
            ],
            if (_hasText(invoice.terms)) ...[
              if (_hasText(invoice.notes)) pw.SizedBox(height: 7),
              _professionalLabel('TERMS & CONDITIONS', style),
              pw.SizedBox(height: 3),
              pw.Text(invoice.terms!, style: const pw.TextStyle(fontSize: 8)),
            ],
          ],
        ),
      );

  pw.Widget _professionalAuthorization(
    BusinessProfileModel business,
    pw.MemoryImage? signature,
    _PdfStyle style,
  ) => pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(
          'This is a computer-generated document. Please retain it for your records.',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
        ),
      ),
      pw.SizedBox(width: 28),
      pw.SizedBox(
        width: 175,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (signature != null)
              pw.Image(
                signature,
                width: 100,
                height: 42,
                fit: pw.BoxFit.contain,
              )
            else
              pw.SizedBox(height: 42),
            pw.Container(height: .7, color: PdfColors.grey500),
            pw.SizedBox(height: 4),
            pw.Text(
              'Authorized signature',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: style.accent,
              ),
            ),
            pw.Text(
              business.businessName,
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
        ),
      ),
    ],
  );

  pw.Widget _professionalLabel(String value, _PdfStyle style) => pw.Text(
    value,
    style: pw.TextStyle(
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      color: style.accent,
      letterSpacing: .7,
    ),
  );

  pw.Widget _header(
    BusinessProfileModel business,
    InvoiceModel invoice,
    _PdfStyle style,
    pw.MemoryImage? logo,
  ) {
    final businessAddress = _address([
      business.address,
      business.city,
      business.state,
      business.pinCode,
    ]);
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
                if (_hasText(business.ownerName))
                  _headerDetail('Owner: ${business.ownerName}', style),
                if (_hasText(business.mobile) || _hasText(business.email))
                  _headerDetail(
                    _join([business.mobile, business.email], separator: ' • '),
                    style,
                  ),
                if (businessAddress.isNotEmpty)
                  _headerDetail(businessAddress, style),
                if (_hasText(business.gstin) || _hasText(business.pan))
                  _headerDetail(
                    _join([
                      if (_hasText(business.gstin)) 'GSTIN: ${business.gstin}',
                      if (_hasText(business.pan)) 'PAN: ${business.pan}',
                    ], separator: ' • '),
                    style,
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

  pw.Widget _customer(InvoiceModel invoice, _PdfStyle style) {
    final customer = invoice.customer;
    final customerAddress = _address([
      customer.address,
      customer.city,
      customer.state,
      customer.pinCode,
    ]);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(style.blockPadding),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: style.accent,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            customer.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          if (_hasText(customer.companyName)) pw.Text(customer.companyName!),
          if (_hasText(customer.mobile) || _hasText(customer.email))
            pw.Text(_join([customer.mobile, customer.email], separator: ' • ')),
          if (customerAddress.isNotEmpty) pw.Text(customerAddress),
          if (_hasText(customer.gstin)) pw.Text('GSTIN: ${customer.gstin}'),
        ],
      ),
    );
  }

  pw.Widget _items(InvoiceModel invoice, String symbol, _PdfStyle style) {
    final headers = ['Item', 'HSN/SAC', 'Qty', 'Rate', 'Tax', 'Amount'];
    final data = invoice.items.asMap().entries.map((entry) {
      final item = entry.value;
      final result = invoice.calculation.items[entry.key];
      return [
        _itemTitle(item),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(3.2),
        1: pw.FlexColumnWidth(1.25),
        2: pw.FlexColumnWidth(1.25),
        3: pw.FlexColumnWidth(1.35),
        4: pw.FlexColumnWidth(1.05),
        5: pw.FlexColumnWidth(1.5),
      },
      headerAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      headerDecoration: pw.BoxDecoration(color: style.accent),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: style.compact ? 7.5 : 8.5,
      ),
      cellStyle: pw.TextStyle(fontSize: style.compact ? 7.5 : 8.5),
      cellPadding: pw.EdgeInsets.all(style.compact ? 4 : 7),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
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

  pw.Widget _headerDetail(String value, _PdfStyle style) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 1.5),
    child: pw.Text(
      value,
      style: pw.TextStyle(
        color: style.headerText,
        fontSize: 8.5,
        lineSpacing: 1,
      ),
    ),
  );

  bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;

  String _join(List<String?> values, {String separator = ', '}) => values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join(separator);

  String _address(List<String?> values) => _join(values);

  /// The built-in PDF fonts don't contain the Indian rupee glyph. Embedding
  /// the app's font also keeps previews, saved files, and printed output
  /// visually consistent and ready for user-selectable templates.
  Future<pw.ThemeData> _documentTheme() async {
    final data = await rootBundle.load(
      'assets/fonts/DMSans/DMSans-Regular.ttf',
    );
    final font = pw.Font.ttf(data);
    return pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );
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
      PdfColor.fromInt(0xFFF36F62),
      PdfColor.fromInt(0xFF6A315F),
      PdfColors.white,
      26,
      14,
      9,
      false,
      false,
    ),
    InvoiceTemplate.modern => const _PdfStyle(
      PdfColor.fromInt(0xFFF36F62),
      PdfColor.fromInt(0xFFFFF5F1),
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
      PdfColor.fromInt(0xFF6A315F),
      PdfColor.fromInt(0xFFFFF5F1),
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

  String _itemTitle(InvoiceItemModel item) {
    if (!(productSettings?.showAttributesOnInvoice ?? true)) return item.name;
    final attributes = ProductAttributeUtils.compact(item.attributes);
    return attributes.isEmpty ? item.name : '${item.name}\n$attributes';
  }
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
