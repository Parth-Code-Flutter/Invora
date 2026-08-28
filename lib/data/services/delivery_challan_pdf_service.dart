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
import '../models/delivery_challan_model.dart';

class DeliveryChallanPdfService {
  const DeliveryChallanPdfService();

  Future<Uint8List> build({
    required DeliveryChallanModel challan,
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
              'DELIVERY CHALLAN',
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
                      'Consignee',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(challan.customer.name),
                    if ((challan.customer.companyName ?? '').trim().isNotEmpty)
                      pw.Text(challan.customer.companyName!),
                    if ((challan.deliveryAddress ??
                            challan.customer.address ??
                            '')
                        .trim()
                        .isNotEmpty)
                      pw.Text(
                        challan.deliveryAddress ?? challan.customer.address!,
                      ),
                    pw.Text(
                      [
                            challan.deliveryCity ?? challan.customer.city,
                            challan.deliveryState ?? challan.customer.state,
                            challan.deliveryPinCode ?? challan.customer.pinCode,
                          ]
                          .whereType<String>()
                          .where((value) => value.trim().isNotEmpty)
                          .join(', '),
                    ),
                    if ((challan.customer.gstin ?? '').trim().isNotEmpty)
                      pw.Text('GSTIN ${challan.customer.gstin}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(challan.challanNumber),
                    pw.Text('Date ${_date(challan.challanDate)}'),
                    pw.Text(
                      DeliveryChallanLabels.reason(challan.movementReason),
                    ),
                    pw.Text(DeliveryChallanLabels.status(challan.status)),
                    if (challan.sourceCaption != null)
                      pw.Text(challan.sourceCaption!),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Item', 'HSN', 'Qty', 'Unit', 'Rate', 'Amount'],
            data: [
              for (final item in challan.items)
                [
                  item.name,
                  item.hsnSac ?? '',
                  QuantityUtils.toInputValue(item.dispatchedQuantityScaled),
                  item.unit,
                  CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol),
                  CurrencyUtils.formatMinor(
                    ((item.rateMinor * item.dispatchedQuantityScaled) /
                            QuantityUtils.scale)
                        .round(),
                    symbol: symbol,
                  ),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              2: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
          if ((challan.dispatchAddress ?? '').trim().isNotEmpty) ...[
            pw.Text(
              'Dispatch from',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              [
                    challan.dispatchAddress,
                    challan.dispatchCity,
                    challan.dispatchState,
                    challan.dispatchPinCode,
                  ]
                  .whereType<String>()
                  .where((value) => value.trim().isNotEmpty)
                  .join(', '),
            ),
            pw.SizedBox(height: 8),
          ],
          if (challan.hasTransportDetails) ...[
            pw.Text(
              'Transport',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if ((challan.transporterName ?? '').trim().isNotEmpty)
              pw.Text('Transporter ${challan.transporterName}'),
            if ((challan.transporterId ?? '').trim().isNotEmpty)
              pw.Text('Transporter ID ${challan.transporterId}'),
            if ((challan.vehicleNumber ?? '').trim().isNotEmpty)
              pw.Text('Vehicle ${challan.vehicleNumber}'),
            if ((challan.transportDocumentNumber ?? '').trim().isNotEmpty)
              pw.Text(
                'Document ${challan.transportDocumentNumber}${challan.transportDocumentDate == null ? '' : ' · ${_date(challan.transportDocumentDate!)}'}',
              ),
            if (challan.distanceKm != null)
              pw.Text('Distance ${challan.distanceKm} km'),
            pw.SizedBox(height: 8),
          ],
          pw.Text(_ewayLine(challan)),
          if ((challan.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(challan.notes!),
          ],
          if (challan.isCancelled) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Cancelled: ${challan.cancellationReason ?? ''}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  String fileName(DeliveryChallanModel challan) =>
      'Delivery_Challan_${_safe(challan.challanNumber)}.pdf';

  Future<void> share({
    required DeliveryChallanModel challan,
    required BusinessProfileModel business,
  }) async {
    final file = File(
      p.join((await getTemporaryDirectory()).path, fileName(challan)),
    );
    await file.writeAsBytes(
      await build(challan: challan, business: business),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: challan.challanNumber),
    );
  }

  Future<void> print({
    required DeliveryChallanModel challan,
    required BusinessProfileModel business,
  }) {
    return Printing.layoutPdf(
      name: fileName(challan),
      onLayout: (_) => build(challan: challan, business: business),
    );
  }

  Future<String?> save({
    required DeliveryChallanModel challan,
    required BusinessProfileModel business,
  }) async {
    final bytes = await build(challan: challan, business: business);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save delivery challan',
      fileName: fileName(challan),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
  }

  String _ewayLine(DeliveryChallanModel challan) {
    switch (challan.ewayStatus) {
      case EwayStatus.generated:
        return 'E-way bill ${challan.ewayNumber} (imported acknowledgement)';
      case EwayStatus.prepared:
        return 'E-way bill: Prepared (not generated in this app)';
      case EwayStatus.none:
        return 'E-way bill: Not prepared';
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
