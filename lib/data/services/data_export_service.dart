import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../app/enums/invoice_status.dart';
import '../../app/utils/tax_utils.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_payment_model.dart';
import '../models/product_service_model.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/product_repository.dart';

enum DataExportType { customers, products, invoices, payments, report }

class ExportArtifact {
  const ExportArtifact({
    required this.fileName,
    required this.bytes,
    required this.extension,
  });

  final String fileName;
  final Uint8List bytes;
  final String extension;
}

class DataExportService {
  const DataExportService(this._customers, this._products, this._invoices);

  final CustomerRepository _customers;
  final ProductRepository _products;
  final InvoiceRepository _invoices;

  Future<ExportArtifact> buildCsv(
    DataExportType type, {
    required DateTime from,
    required DateTime to,
  }) async {
    final suffix = '${_isoDate(from)}_to_${_isoDate(to)}';
    final rows = switch (type) {
      DataExportType.customers => customerRows(
        await _customers.watchCustomers().first,
      ),
      DataExportType.products => productRows(
        await _products.watchItems().first,
      ),
      DataExportType.invoices => _invoiceRows(await _documents(from, to)),
      DataExportType.payments => _paymentRows(
        await _documents(from, to, filterByInvoiceDate: false),
        from,
        to,
      ),
      DataExportType.report => _reportRows(
        await _documents(from, to),
        from,
        to,
      ),
    };
    final name = switch (type) {
      DataExportType.customers => 'creovo_customers.csv',
      DataExportType.products => 'creovo_products_services.csv',
      DataExportType.invoices => 'creovo_invoices_$suffix.csv',
      DataExportType.payments => 'creovo_payments_$suffix.csv',
      DataExportType.report => 'creovo_report_$suffix.csv',
    };
    return ExportArtifact(
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode('\ufeff${encodeCsv(rows)}')),
      extension: 'csv',
    );
  }

  Future<ExportArtifact> buildReportPdf({
    required DateTime from,
    required DateTime to,
  }) async {
    final documents = await _documents(from, to);
    final active = documents
        .where((entry) => entry.invoice.status != InvoiceStatus.cancelled)
        .toList(growable: false);
    final invoiced = active.fold<int>(
      0,
      (sum, entry) => sum + entry.invoice.calculation.grandTotalMinor,
    );
    final received = active.fold<int>(
      0,
      (sum, entry) =>
          sum + entry.payments.fold(0, (value, row) => value + row.amountMinor),
    );
    final document = pw.Document();
    final font = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-Regular.ttf',
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Text(
            'Creovo sales report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('${_displayDate(from)} – ${_displayDate(to)}'),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _pdfMetric('Invoiced', _money(invoiced)),
              pw.SizedBox(width: 10),
              _pdfMetric('Received', _money(received)),
              pw.SizedBox(width: 10),
              _pdfMetric('Outstanding', _money(invoiced - received)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Invoice',
              'Customer',
              'Status',
              'Total',
              'Due',
            ],
            data: active
                .map(
                  (entry) => [
                    _isoDate(entry.invoice.invoiceDate),
                    entry.invoice.invoiceNumber,
                    entry.invoice.customer.name,
                    entry.invoice.status.name,
                    _money(entry.invoice.calculation.grandTotalMinor),
                    _money(entry.invoice.calculation.balanceDueMinor),
                  ],
                )
                .toList(growable: false),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    final suffix = '${_isoDate(from)}_to_${_isoDate(to)}';
    return ExportArtifact(
      fileName: 'creovo_report_$suffix.pdf',
      bytes: await document.save(),
      extension: 'pdf',
    );
  }

  Future<String?> save(ExportArtifact artifact) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ${artifact.extension.toUpperCase()} export',
      fileName: artifact.fileName,
      type: FileType.custom,
      allowedExtensions: [artifact.extension],
      bytes: artifact.bytes,
    );
    if (path != null && !await File(path).exists()) {
      await File(path).writeAsBytes(artifact.bytes, flush: true);
    }
    return path;
  }

  Future<void> share(ExportArtifact artifact) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, artifact.fileName),
    );
    await file.writeAsBytes(artifact.bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: artifact.fileName),
    );
  }

  static List<List<Object?>> customerRows(List<CustomerModel> values) => [
    const [
      'Name',
      'Company',
      'Mobile',
      'Email',
      'GSTIN',
      'Address',
      'City',
      'State',
      'PIN code',
      'Notes',
      'Created at',
    ],
    ...values.map(
      (value) => [
        value.name,
        value.companyName,
        value.mobile,
        value.email,
        value.gstin,
        value.address,
        value.city,
        value.state,
        value.pinCode,
        value.notes,
        value.createdAt.toIso8601String(),
      ],
    ),
  ];

  static List<List<Object?>> productRows(List<ProductServiceModel> values) => [
    const [
      'Name',
      'Type',
      'Description',
      'Unit',
      'Sale price',
      'HSN/SAC',
      'GST rate',
      'Created at',
    ],
    ...values.map(
      (value) => [
        value.name,
        value.type.label,
        value.description,
        value.unit,
        _money(value.salePriceMinor),
        value.hsnSac,
        TaxUtils.formatBasisPoints(value.taxRateBasisPoints),
        value.createdAt.toIso8601String(),
      ],
    ),
  ];

  static String encodeCsv(List<List<Object?>> rows) =>
      rows.map((row) => row.map(_escape).join(',')).join('\r\n');

  static String _escape(Object? raw) {
    final value = raw?.toString() ?? '';
    if (!value.contains(RegExp('[,"\\r\\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static List<List<Object?>> _invoiceRows(List<_ExportDocument> values) => [
    const [
      'Invoice number',
      'Date',
      'Due date',
      'Customer',
      'Company',
      'GSTIN',
      'Status',
      'Tax mode',
      'Subtotal',
      'Taxable value',
      'CGST',
      'SGST',
      'IGST',
      'Total tax',
      'Additional charges',
      'Grand total',
      'Paid',
      'Balance due',
      'Currency format',
    ],
    ...values.map((entry) {
      final value = entry.invoice;
      return [
        value.invoiceNumber,
        _isoDate(value.invoiceDate),
        value.dueDate == null ? null : _isoDate(value.dueDate!),
        value.customer.name,
        value.customer.companyName,
        value.customer.gstin,
        value.status.name,
        value.taxType.name,
        _money(value.calculation.subtotalMinor),
        _money(value.calculation.taxableTotalMinor),
        _money(value.calculation.cgstMinor),
        _money(value.calculation.sgstMinor),
        _money(value.calculation.igstMinor),
        _money(value.calculation.taxTotalMinor),
        _money(value.calculation.additionalChargeTotalMinor),
        _money(value.calculation.grandTotalMinor),
        _money(value.calculation.paidAmountMinor),
        _money(value.calculation.balanceDueMinor),
        'decimal major units',
      ];
    }),
  ];

  static List<List<Object?>> _paymentRows(
    List<_ExportDocument> values,
    DateTime from,
    DateTime to,
  ) {
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return [
      const [
        'Receipt ID',
        'Invoice number',
        'Customer',
        'Paid at',
        'Entry type',
        'Amount',
        'Method',
        'Reference',
        'Note',
        'Reversed',
        'Reverses payment ID',
      ],
      ...values.expand(
        (entry) => entry.payments
            .where(
              (payment) =>
                  !payment.paidAt.isBefore(from) &&
                  !payment.paidAt.isAfter(end),
            )
            .map(
              (payment) => [
                payment.id,
                entry.invoice.invoiceNumber,
                entry.invoice.customer.name,
                payment.paidAt.toIso8601String(),
                payment.entryType.name,
                _money(payment.amountMinor),
                payment.method,
                payment.reference,
                payment.note,
                payment.isReversed,
                payment.reversesPaymentId,
              ],
            ),
      ),
    ];
  }

  static List<List<Object?>> _reportRows(
    List<_ExportDocument> values,
    DateTime from,
    DateTime to,
  ) {
    final active = values.where(
      (entry) => entry.invoice.status != InvoiceStatus.cancelled,
    );
    final invoiced = active.fold<int>(
      0,
      (sum, entry) => sum + entry.invoice.calculation.grandTotalMinor,
    );
    final received = active.fold<int>(
      0,
      (sum, entry) =>
          sum + entry.payments.fold(0, (value, row) => value + row.amountMinor),
    );
    return [
      const [
        'Report from',
        'Report to',
        'Invoice count',
        'Invoiced',
        'Received',
        'Outstanding',
      ],
      [
        _isoDate(from),
        _isoDate(to),
        active.length,
        _money(invoiced),
        _money(received),
        _money(invoiced - received),
      ],
    ];
  }

  Future<List<_ExportDocument>> _documents(
    DateTime from,
    DateTime to, {
    bool filterByInvoiceDate = true,
  }) async {
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final summaries = await _invoices.watchSummaries().first;
    final selected = filterByInvoiceDate
        ? summaries.where(
            (value) =>
                !value.invoiceDate.isBefore(from) &&
                !value.invoiceDate.isAfter(end),
          )
        : summaries;
    final result = <_ExportDocument>[];
    for (final summary in selected) {
      final invoice = await _invoices.getById(summary.id);
      if (invoice == null) continue;
      result.add(
        _ExportDocument(invoice, await _invoices.getPayments(summary.id)),
      );
    }
    return result;
  }

  static pw.Widget _pdfMetric(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [pw.Text(label), pw.SizedBox(height: 4), pw.Text(value)],
      ),
    ),
  );

  static String _money(int minor) => (minor / 100).toStringAsFixed(2);
  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ExportDocument {
  const _ExportDocument(this.invoice, this.payments);
  final InvoiceModel invoice;
  final List<InvoicePaymentModel> payments;
}
