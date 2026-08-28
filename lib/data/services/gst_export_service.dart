import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../models/credit_note_model.dart';
import '../models/debit_note_model.dart';
import '../models/gst_export_model.dart';
import '../models/invoice_model.dart';
import '../models/purchase_models.dart';
import '../repositories/business_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/debit_note_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/purchase_repository.dart';
import 'data_export_service.dart';

class GstExportService {
  const GstExportService(
    this._business,
    this._invoices,
    this._creditNotes,
    this._purchases,
    this._debitNotes,
  );

  final BusinessRepository _business;
  final InvoiceRepository _invoices;
  final CreditNoteRepository _creditNotes;
  final PurchaseRepository _purchases;
  final DebitNoteRepository _debitNotes;

  Future<GstExportPack> build(GstExportPeriod period) async {
    final profile = await _business.getProfile();
    final invoices = await _postedInvoices(period);
    final notes = await _creditNotes.listInRange(period.from, period.to);
    final debitNotes = await _debitNotes.listInRange(period.from, period.to);
    final purchaseExports = await _postedPurchases(period);
    final invoiceById = <int, InvoiceModel>{
      for (final invoice in invoices)
        if (invoice.id != null) invoice.id!: invoice,
    };
    for (final note in notes) {
      if (invoiceById.containsKey(note.invoiceId)) continue;
      final source = await _invoices.getById(note.invoiceId);
      if (source != null) invoiceById[note.invoiceId] = source;
    }
    final sales = invoices.map(_salesRow).toList(growable: false);
    final creditRows = [
      for (final note in notes)
        _creditRow(
          note,
          gstin: _normalizedGstin(invoiceById[note.invoiceId]?.customer.gstin),
        ),
    ];
    final purchaseRows = [for (final entry in purchaseExports) entry.row];
    final gstinByBillId = <int, String?>{
      for (final entry in purchaseExports)
        if (entry.bill.id != null) entry.bill.id!: entry.row.gstin,
    };
    for (final note in debitNotes) {
      if (gstinByBillId.containsKey(note.purchaseBillId)) continue;
      final source = await _purchases.getBill(note.purchaseBillId);
      final supplierId = source?.supplierId ?? note.supplierId;
      gstinByBillId[note.purchaseBillId] = supplierId == null
          ? null
          : _normalizedGstin((await _purchases.getSupplier(supplierId))?.gstin);
    }
    final debitRows = [
      for (final note in debitNotes)
        _debitRow(note, gstin: gstinByBillId[note.purchaseBillId]),
    ];
    final exceptions = _exceptions(
      invoices,
      notes,
      purchaseExports,
      debitNotes,
    );
    return GstExportPack(
      period: period,
      businessName: profile?.businessName.trim().isNotEmpty == true
          ? profile!.businessName.trim()
          : 'Creovo Billing',
      gstin: _normalizedGstin(profile?.gstin),
      generatedAt: DateTime.now(),
      summary: GstExportSummary(
        invoiceCount: sales.length,
        creditNoteCount: creditRows.length,
        purchaseCount: purchaseRows.length,
        debitNoteCount: debitRows.length,
        exceptionCount: exceptions.length,
        b2bCount: sales
            .where((row) => row.supplyType == GstSupplyType.b2b)
            .length,
        b2cCount: sales
            .where((row) => row.supplyType == GstSupplyType.b2c)
            .length,
        taxableSalesMinor: sales.fold(0, (sum, row) => sum + row.taxableMinor),
        outputTaxMinor: sales.fold(0, (sum, row) => sum + row.taxMinor),
        creditNoteTotalMinor: creditRows.fold(
          0,
          (sum, row) => sum + row.grandTotalMinor,
        ),
        purchaseTotalMinor: purchaseRows.fold(
          0,
          (sum, row) => sum + row.totalMinor,
        ),
        debitNoteTotalMinor: debitRows.fold(
          0,
          (sum, row) => sum + row.grandTotalMinor,
        ),
        itcMinor:
            purchaseRows
                .where((row) => row.itcEligible)
                .fold(0, (sum, row) => sum + row.taxMinor) -
            debitRows
                .where((row) => row.itcEligible)
                .fold(0, (sum, row) => sum + row.taxMinor),
      ),
      sales: sales,
      creditNotes: creditRows,
      purchases: purchaseRows,
      debitNotes: debitRows,
      hsn: _hsnRows(invoices, notes, purchaseExports, debitNotes),
      exceptions: exceptions,
    );
  }

  Future<ExportArtifact> buildCsv(
    GstExportKind kind,
    GstExportPack pack,
  ) async {
    final suffix = _suffix(pack.period);
    final (name, rows) = switch (kind) {
      GstExportKind.sales => ('creovo_gst_sales_$suffix.csv', _salesCsv(pack)),
      GstExportKind.creditNotes => (
        'creovo_gst_credit_notes_$suffix.csv',
        _creditCsv(pack),
      ),
      GstExportKind.purchases => (
        'creovo_gst_purchases_$suffix.csv',
        _purchaseCsv(pack),
      ),
      GstExportKind.debitNotes => (
        'creovo_gst_debit_notes_$suffix.csv',
        _debitCsv(pack),
      ),
      GstExportKind.hsn => ('creovo_gst_hsn_$suffix.csv', _hsnCsv(pack)),
      GstExportKind.exceptions => (
        'creovo_gst_exceptions_$suffix.csv',
        _exceptionCsv(pack),
      ),
    };
    return ExportArtifact(
      fileName: name,
      bytes: Uint8List.fromList(
        utf8.encode('\ufeff${DataExportService.encodeCsv(rows)}'),
      ),
      extension: 'csv',
    );
  }

  Future<ExportArtifact> buildPdf(GstExportPack pack) async {
    final font = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-Regular.ttf',
      ),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            pack.businessName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'GST / ACCOUNTANT EXPORT',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Status: ${GstExportPack.filingStatus} — ${GstExportPack.portalStatus}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${_display(pack.period.from)} – ${_display(pack.period.to)}',
          ),
          if (pack.gstin != null) pw.Text('GSTIN ${pack.gstin}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'This file was prepared offline. It is not a GST portal filing and has not been submitted.',
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _metric('Taxable sales', _money(pack.summary.taxableSalesMinor)),
              _metric('Output tax', _money(pack.summary.outputTaxMinor)),
              _metric(
                'Credit notes',
                _money(pack.summary.creditNoteTotalMinor),
              ),
              _metric('ITC (eligible)', _money(pack.summary.itcMinor)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Invoices ${pack.summary.invoiceCount}  ·  B2B ${pack.summary.b2bCount}  ·  B2C ${pack.summary.b2cCount}  ·  Credit notes ${pack.summary.creditNoteCount}  ·  Purchases ${pack.summary.purchaseCount}  ·  Debit notes ${pack.summary.debitNoteCount}  ·  Exceptions ${pack.summary.exceptionCount}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Exceptions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (pack.exceptions.isEmpty)
            pw.Text(
              'No missing GSTIN, HSN/SAC, or tax-mode issues in this period.',
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Document', 'Issue'],
              data: [
                for (final item in pack.exceptions.take(40))
                  [_iso(item.documentDate), item.documentNumber, item.message],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
    return ExportArtifact(
      fileName: 'creovo_gst_ca_${_suffix(pack.period)}.pdf',
      bytes: await document.save(),
      extension: 'pdf',
    );
  }

  Future<ExportArtifact> buildZip(GstExportPack pack) async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        'README_PREPARED.txt',
        'Creovo Billing GST / accountant pack\n'
            'Status: ${GstExportPack.filingStatus}\n'
            'GST portal: ${GstExportPack.portalStatus}\n'
            'Period: ${_iso(pack.period.from)} to ${_iso(pack.period.to)}\n'
            'Business: ${pack.businessName}\n'
            '${pack.gstin == null ? '' : 'GSTIN: ${pack.gstin}\n'}'
            '\nThis pack was prepared offline. It is not a GST return and has not been submitted.\n',
      ),
    );
    for (final kind in GstExportKind.values) {
      final csv = await buildCsv(kind, pack);
      archive.addFile(ArchiveFile(csv.fileName, csv.bytes.length, csv.bytes));
    }
    final pdf = await buildPdf(pack);
    archive.addFile(ArchiveFile(pdf.fileName, pdf.bytes.length, pdf.bytes));
    return ExportArtifact(
      fileName: 'creovo_gst_ca_${_suffix(pack.period)}.zip',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      extension: 'zip',
    );
  }

  Future<String?> save(ExportArtifact artifact) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save GST export',
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

  Future<void> printPdf(ExportArtifact artifact) => Printing.layoutPdf(
    onLayout: (_) async => artifact.bytes,
    name: artifact.fileName,
  );

  Future<List<InvoiceModel>> _postedInvoices(GstExportPeriod period) async {
    final start = GstExportPeriod.dateOnly(period.from);
    final end = DateTime(
      period.to.year,
      period.to.month,
      period.to.day,
      23,
      59,
      59,
      999,
    );
    final summaries = await _invoices.watchSummaries().first;
    final result = <InvoiceModel>[];
    for (final summary in summaries) {
      if (summary.invoiceDate.isBefore(start) ||
          summary.invoiceDate.isAfter(end)) {
        continue;
      }
      if (summary.status == InvoiceStatus.draft ||
          summary.status == InvoiceStatus.cancelled) {
        continue;
      }
      final invoice = await _invoices.getById(summary.id);
      if (invoice == null || invoice.documentType != DocumentType.invoice) {
        continue;
      }
      result.add(invoice);
    }
    result.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    return result;
  }

  Future<List<_PurchaseExport>> _postedPurchases(GstExportPeriod period) async {
    final start = GstExportPeriod.dateOnly(period.from);
    final end = DateTime(
      period.to.year,
      period.to.month,
      period.to.day,
      23,
      59,
      59,
      999,
    );
    final summaries = await _purchases.watchBills().first;
    final result = <_PurchaseExport>[];
    for (final summary in summaries) {
      if (summary.billDate.isBefore(start) || summary.billDate.isAfter(end)) {
        continue;
      }
      if (summary.status == 'cancelled') continue;
      final bill = await _purchases.getBill(summary.id);
      if (bill == null) continue;
      final supplierId = bill.supplierId;
      final supplier = supplierId == null
          ? null
          : await _purchases.getSupplier(supplierId);
      result.add(
        _PurchaseExport(
          bill,
          GstPurchaseRegisterRow(
            billId: bill.id,
            billDate: bill.billDate,
            billNumber: bill.billNumber,
            supplierName: bill.supplierName,
            gstin: _normalizedGstin(supplier?.gstin),
            taxMode: bill.taxMode,
            reverseCharge: bill.reverseCharge,
            itcEligible: bill.itcEligible,
            taxableMinor: bill.subtotalMinor - bill.discountMinor,
            taxMinor: bill.taxMinor,
            totalMinor: bill.totalMinor,
          ),
        ),
      );
    }
    return result;
  }

  GstSalesRegisterRow _salesRow(InvoiceModel invoice) {
    final gstin = _normalizedGstin(invoice.customer.gstin);
    return GstSalesRegisterRow(
      invoiceId: invoice.id,
      invoiceDate: invoice.invoiceDate,
      invoiceNumber: invoice.invoiceNumber,
      customerName: invoice.customer.name,
      gstin: gstin,
      supplyType: _isB2b(gstin) ? GstSupplyType.b2b : GstSupplyType.b2c,
      taxMode: invoice.taxType.name,
      taxableMinor: invoice.calculation.taxableTotalMinor,
      cgstMinor: invoice.calculation.cgstMinor,
      sgstMinor: invoice.calculation.sgstMinor,
      igstMinor: invoice.calculation.igstMinor,
      taxMinor: invoice.calculation.taxTotalMinor,
      grandTotalMinor: invoice.calculation.grandTotalMinor,
    );
  }

  GstCreditNoteRegisterRow _creditRow(CreditNoteModel note, {String? gstin}) =>
      GstCreditNoteRegisterRow(
        creditNoteId: note.id,
        creditNoteDate: note.creditNoteDate,
        creditNoteNumber: note.creditNoteNumber,
        invoiceNumber: note.invoiceNumber,
        customerName: note.customerName,
        gstin: gstin,
        taxMode: note.taxType.name,
        taxableMinor: note.taxableMinor,
        taxMinor: note.taxMinor,
        grandTotalMinor: note.grandTotalMinor,
        reason: note.reason,
      );

  GstDebitNoteRegisterRow _debitRow(DebitNoteModel note, {String? gstin}) =>
      GstDebitNoteRegisterRow(
        debitNoteId: note.id,
        debitNoteDate: note.debitNoteDate,
        debitNoteNumber: note.debitNoteNumber,
        billNumber: note.billNumber,
        supplierName: note.supplierName,
        gstin: gstin,
        taxMode: note.taxMode,
        itcEligible: note.itcEligible,
        taxableMinor: note.subtotalMinor,
        taxMinor: note.taxMinor,
        grandTotalMinor: note.grandTotalMinor,
        reason: note.reason,
      );

  List<GstHsnSummaryRow> _hsnRows(
    List<InvoiceModel> invoices,
    List<CreditNoteModel> notes,
    List<_PurchaseExport> purchases,
    List<DebitNoteModel> debitNotes,
  ) {
    final buckets = <String, _HsnBucket>{};
    _HsnBucket bucket(String? hsn) {
      final key = (hsn == null || hsn.trim().isEmpty) ? 'MISSING' : hsn.trim();
      return buckets.putIfAbsent(key, _HsnBucket.new);
    }

    for (final invoice in invoices) {
      for (var index = 0; index < invoice.items.length; index++) {
        final item = invoice.items[index];
        final calc = index < invoice.calculation.items.length
            ? invoice.calculation.items[index]
            : null;
        final current = bucket(item.hsnSac);
        current.documents.add(invoice.invoiceNumber);
        current.taxable += calc?.taxableMinor ?? 0;
        current.tax += calc?.taxMinor ?? 0;
        current.total += calc?.totalMinor ?? 0;
      }
    }
    for (final note in notes) {
      for (final item in note.items) {
        final current = bucket(item.hsnSac);
        current.documents.add(note.creditNoteNumber);
        current.taxable -= item.taxableAmountMinor;
        current.tax -= item.taxAmountMinor;
        current.total -= item.totalMinor;
      }
    }
    for (final entry in purchases) {
      for (final item in entry.bill.items) {
        final current = bucket(item.hsnSac);
        current.documents.add(entry.bill.billNumber);
        current.taxable += item.subtotalMinor;
        current.tax += item.taxMinor;
        current.total += item.totalMinor;
      }
    }
    for (final note in debitNotes) {
      for (final item in note.items) {
        final current = bucket(item.hsnSac);
        current.documents.add(note.debitNoteNumber);
        current.taxable -= item.baseAmountMinor;
        current.tax -= item.taxAmountMinor;
        current.total -= item.totalMinor;
      }
    }
    final rows = buckets.entries
        .map(
          (entry) => GstHsnSummaryRow(
            hsnSac: entry.key,
            documentCount: entry.value.documents.length,
            taxableMinor: entry.value.taxable,
            taxMinor: entry.value.tax,
            totalMinor: entry.value.total,
          ),
        )
        .toList();
    rows.sort((a, b) => a.hsnSac.compareTo(b.hsnSac));
    return rows;
  }

  List<GstExportException> _exceptions(
    List<InvoiceModel> invoices,
    List<CreditNoteModel> notes,
    List<_PurchaseExport> purchases,
    List<DebitNoteModel> debitNotes,
  ) {
    final items = <GstExportException>[];
    for (final invoice in invoices) {
      final gstin = invoice.customer.gstin?.trim() ?? '';
      if (gstin.isNotEmpty && gstin.length != 15) {
        items.add(
          GstExportException(
            documentNumber: invoice.invoiceNumber,
            documentDate: invoice.invoiceDate,
            kind: 'GSTIN',
            message: 'Customer GSTIN is not 15 characters.',
            source: GstExportSource.invoice,
            documentId: invoice.id,
          ),
        );
      }
      if (invoice.taxType == TaxType.none) {
        final validGstin = _normalizedGstin(invoice.customer.gstin);
        if (_isB2b(validGstin)) {
          items.add(
            GstExportException(
              documentNumber: invoice.invoiceNumber,
              documentDate: invoice.invoiceDate,
              kind: 'Tax mode',
              message:
                  'GSTIN is present but the invoice was issued without GST.',
              source: GstExportSource.invoice,
              documentId: invoice.id,
            ),
          );
        }
      } else {
        final missingHsn = invoice.items.any(
          (item) => (item.hsnSac == null || item.hsnSac!.trim().isEmpty),
        );
        if (missingHsn) {
          items.add(
            GstExportException(
              documentNumber: invoice.invoiceNumber,
              documentDate: invoice.invoiceDate,
              kind: 'HSN/SAC',
              message: 'GST invoice has a line without HSN/SAC.',
              source: GstExportSource.invoice,
              documentId: invoice.id,
            ),
          );
        }
      }
    }
    for (final note in notes) {
      if (note.taxType == TaxType.none) continue;
      final missingHsn = note.items.any(
        (item) =>
            !item.isValueAdjustment &&
            (item.hsnSac == null || item.hsnSac!.trim().isEmpty),
      );
      if (missingHsn) {
        items.add(
          GstExportException(
            documentNumber: note.creditNoteNumber,
            documentDate: note.creditNoteDate,
            kind: 'HSN/SAC',
            message: 'GST credit note has a line without HSN/SAC.',
            source: GstExportSource.creditNote,
            documentId: note.id,
          ),
        );
      }
    }
    for (final note in debitNotes) {
      if (note.taxMode == 'exempt') continue;
      final missingHsn = note.items.any(
        (item) =>
            !item.isValueAdjustment &&
            (item.hsnSac == null || item.hsnSac!.trim().isEmpty),
      );
      if (missingHsn) {
        items.add(
          GstExportException(
            documentNumber: note.debitNoteNumber,
            documentDate: note.debitNoteDate,
            kind: 'HSN/SAC',
            message: 'GST debit note has a line without HSN/SAC.',
            source: GstExportSource.debitNote,
            documentId: note.id,
          ),
        );
      }
    }
    for (final entry in purchases) {
      final gstin = entry.row.gstin ?? '';
      if (gstin.isNotEmpty && gstin.length != 15) {
        items.add(
          GstExportException(
            documentNumber: entry.bill.billNumber,
            documentDate: entry.bill.billDate,
            kind: 'GSTIN',
            message: 'Supplier GSTIN is not 15 characters.',
            source: GstExportSource.purchase,
            documentId: entry.bill.id,
          ),
        );
      }
      if (entry.bill.items.any(
        (item) =>
            item.taxRate > 0 &&
            (item.hsnSac == null || item.hsnSac!.trim().isEmpty),
      )) {
        items.add(
          GstExportException(
            documentNumber: entry.bill.billNumber,
            documentDate: entry.bill.billDate,
            kind: 'HSN/SAC',
            message: 'Taxed purchase line is missing HSN/SAC.',
            source: GstExportSource.purchase,
            documentId: entry.bill.id,
          ),
        );
      }
    }
    return items;
  }

  List<List<Object?>> _salesCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const [
      'Date',
      'Invoice number',
      'Customer',
      'GSTIN',
      'Supply type',
      'Tax mode',
      'Taxable value',
      'CGST',
      'SGST',
      'IGST',
      'Total tax',
      'Grand total',
      'Filing status',
    ],
    ...pack.sales.map(
      (row) => [
        _iso(row.invoiceDate),
        row.invoiceNumber,
        row.customerName,
        row.gstin,
        row.supplyType.name.toUpperCase(),
        row.taxMode,
        _money(row.taxableMinor),
        _money(row.cgstMinor),
        _money(row.sgstMinor),
        _money(row.igstMinor),
        _money(row.taxMinor),
        _money(row.grandTotalMinor),
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<List<Object?>> _creditCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const [
      'Date',
      'Credit note number',
      'Against invoice',
      'Customer',
      'GSTIN',
      'Tax mode',
      'Taxable value',
      'Tax',
      'Total',
      'Reason',
      'Filing status',
    ],
    ...pack.creditNotes.map(
      (row) => [
        _iso(row.creditNoteDate),
        row.creditNoteNumber,
        row.invoiceNumber,
        row.customerName,
        row.gstin,
        row.taxMode,
        _money(row.taxableMinor),
        _money(row.taxMinor),
        _money(row.grandTotalMinor),
        row.reason,
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<List<Object?>> _debitCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const [
      'Date',
      'Debit note number',
      'Against bill',
      'Supplier',
      'GSTIN',
      'Tax mode',
      'ITC eligible',
      'Taxable value',
      'Tax',
      'Total',
      'Reason',
      'Filing status',
    ],
    ...pack.debitNotes.map(
      (row) => [
        _iso(row.debitNoteDate),
        row.debitNoteNumber,
        row.billNumber,
        row.supplierName,
        row.gstin,
        row.taxMode,
        row.itcEligible ? 'Yes' : 'No',
        _money(row.taxableMinor),
        _money(row.taxMinor),
        _money(row.grandTotalMinor),
        row.reason,
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<List<Object?>> _purchaseCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const [
      'Date',
      'Bill number',
      'Supplier',
      'GSTIN',
      'Tax mode',
      'Reverse charge',
      'ITC eligible',
      'Taxable value',
      'Tax',
      'Total',
      'Filing status',
    ],
    ...pack.purchases.map(
      (row) => [
        _iso(row.billDate),
        row.billNumber,
        row.supplierName,
        row.gstin,
        row.taxMode,
        row.reverseCharge,
        row.itcEligible,
        _money(row.taxableMinor),
        _money(row.taxMinor),
        _money(row.totalMinor),
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<List<Object?>> _hsnCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const [
      'HSN/SAC',
      'Documents',
      'Taxable value',
      'Tax',
      'Total',
      'Filing status',
    ],
    ...pack.hsn.map(
      (row) => [
        row.hsnSac,
        row.documentCount,
        _money(row.taxableMinor),
        _money(row.taxMinor),
        _money(row.totalMinor),
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<List<Object?>> _exceptionCsv(GstExportPack pack) => [
    _statusHeader(pack),
    const ['Date', 'Document', 'Kind', 'Issue', 'Filing status'],
    ...pack.exceptions.map(
      (row) => [
        _iso(row.documentDate),
        row.documentNumber,
        row.kind,
        row.message,
        GstExportPack.filingStatus,
      ],
    ),
  ];

  List<Object?> _statusHeader(GstExportPack pack) => [
    'Prepared (not submitted)',
    _iso(pack.period.from),
    _iso(pack.period.to),
    pack.businessName,
    pack.gstin ?? '',
  ];

  pw.Widget _metric(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      margin: const pw.EdgeInsets.only(right: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ),
  );

  static String? _normalizedGstin(String? value) {
    final gstin = value?.trim().toUpperCase();
    if (gstin == null || gstin.isEmpty) return null;
    return gstin;
  }

  static bool _isB2b(String? gstin) => gstin != null && gstin.length == 15;

  static String _money(int minor) => (minor / 100).toStringAsFixed(2);
  static String _iso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static String _display(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _suffix(GstExportPeriod period) =>
      '${_iso(period.from)}_to_${_iso(period.to)}';
}

class _PurchaseExport {
  const _PurchaseExport(this.bill, this.row);
  final PurchaseBillModel bill;
  final GstPurchaseRegisterRow row;
}

class _HsnBucket {
  final documents = <String>{};
  int taxable = 0;
  int tax = 0;
  int total = 0;
}
