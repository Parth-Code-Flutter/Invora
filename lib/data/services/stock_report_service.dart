import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/enums/item_type.dart';
import '../models/gst_export_model.dart';
import '../models/product_service_model.dart';
import '../models/stock_models.dart';
import '../models/stock_report_model.dart';
import '../repositories/product_repository.dart';
import 'csv_codec.dart';
import 'data_export_service.dart';
import 'stock_ledger.dart';

class StockReportService {
  const StockReportService(this._ledger, this._products);

  final StockLedger _ledger;
  final ProductRepository _products;

  Future<StockReportPack> buildOnHand(DateTime asOf) async {
    final enabled = await _ledger.isEnabled();
    final catalog = (await _products.listItems(
      type: ItemType.product,
    )).where((product) => product.trackStock).toList(growable: false);
    final names = await _namesById(catalog);
    final ids = {
      for (final product in catalog)
        if (product.id != null) product.id!,
    };
    final totals = await _ledger.onHandAsOf(asOf);
    final extraIds = totals.keys.where((id) => !ids.contains(id));
    for (final id in extraIds) {
      final extra = await _fallbackProduct(id);
      if (extra == null || !extra.trackStock) continue;
      names[id] = extra;
    }
    final rows = [
      for (final product in catalog)
        if (product.id != null)
          StockOnHandRow(
            productId: product.id!,
            name: product.name,
            unit: product.unit,
            quantityScaled: totals[product.id!] ?? 0,
          ),
      for (final id in extraIds)
        if (names.containsKey(id))
          StockOnHandRow(
            productId: id,
            name: names[id]?.name ?? 'Product',
            unit: names[id]?.unit ?? 'pcs',
            quantityScaled: totals[id] ?? 0,
          ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final day = StockDay.start(asOf);
    return StockReportPack(
      kind: StockReportKind.onHand,
      enabled: enabled,
      asOf: day,
      period: GstExportPeriod(
        from: day,
        to: day,
        preset: GstExportPeriodPreset.custom,
      ),
      onHand: rows,
      movements: const [],
    );
  }

  Future<StockReportPack> buildMovements(GstExportPeriod period) async {
    final enabled = await _ledger.isEnabled();
    final catalog = await _products.listItems(type: ItemType.product);
    final names = await _namesById(catalog);
    final movements = await _ledger.movementsInRange(
      from: period.from,
      to: period.to,
    );
    final extraIds = movements
        .map((row) => row.productId)
        .where((id) => !names.containsKey(id))
        .toSet();
    for (final id in extraIds) {
      final extra = await _fallbackProduct(id);
      if (extra != null) names[id] = extra;
    }
    return StockReportPack(
      kind: StockReportKind.movements,
      enabled: enabled,
      asOf: period.to,
      period: period,
      onHand: const [],
      movements: [
        for (final movement in movements)
          StockMovementReportRow(
            movement: movement,
            productName: names[movement.productId]?.name ?? 'Product',
            unit: names[movement.productId]?.unit ?? 'pcs',
          ),
      ],
    );
  }

  Future<ExportArtifact> buildCsv(StockReportPack pack) async {
    final rows = pack.kind == StockReportKind.onHand
        ? _onHandCsv(pack)
        : _movementCsv(pack);
    return ExportArtifact(
      fileName: _fileName(pack, 'csv'),
      bytes: Uint8List.fromList(utf8.encode('\ufeff${CsvCodec.encode(rows)}')),
      extension: 'csv',
    );
  }

  Future<ExportArtifact> buildPdf(StockReportPack pack) async {
    final font = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/PlusJakartaSans/PlusJakartaSans-Regular.ttf',
      ),
    );
    final document = pw.Document();
    final onHand = pack.kind == StockReportKind.onHand;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Text(
            onHand ? 'Creovo stock on hand' : 'Creovo stock movements',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            onHand
                ? 'As of ${StockDay.display(pack.asOf)}'
                : pack.period.rangeLabel,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Quantities use when stock was posted, not the invoice date.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          if (onHand && pack.onHand.isEmpty)
            pw.Text('No products to show')
          else if (!onHand && pack.movements.isEmpty)
            pw.Text('No movements in this period')
          else if (onHand)
            pw.TableHelper.fromTextArray(
              headers: const ['Product', 'Unit', 'On hand'],
              data: [
                for (final row in pack.onHand)
                  [row.name, row.unit, row.quantityLabel],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'When posted',
                'Product',
                'Type',
                'Qty',
                'Unit',
                'Source',
                'Reason',
              ],
              data: [
                for (final row in pack.movements)
                  [
                    StockDay.displayDateTime(row.movement.createdAt),
                    row.productName,
                    row.type.label,
                    row.quantityLabel,
                    row.unit,
                    row.source.label,
                    row.movement.reason?.trim() ?? '',
                  ],
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
      fileName: _fileName(pack, 'pdf'),
      bytes: await document.save(),
      extension: 'pdf',
    );
  }

  Future<String?> save(ExportArtifact artifact) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save stock report',
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

  Future<Map<int, ProductServiceModel>> _namesById(
    List<ProductServiceModel> catalog,
  ) async {
    return {
      for (final product in catalog)
        if (product.id != null) product.id!: product,
    };
  }

  Future<ProductServiceModel?> _fallbackProduct(int id) =>
      _products.getById(id);

  List<List<Object?>> _onHandCsv(StockReportPack pack) => [
    const ['Product', 'Unit', 'On hand'],
    for (final row in pack.onHand) [row.name, row.unit, row.quantityLabel],
  ];

  List<List<Object?>> _movementCsv(StockReportPack pack) => [
    const [
      'When posted',
      'Product',
      'Type',
      'Quantity',
      'Unit',
      'Source',
      'Reason',
    ],
    for (final row in pack.movements)
      [
        StockDay.displayDateTime(row.movement.createdAt),
        row.productName,
        row.type.label,
        row.quantityLabel,
        row.unit,
        row.source.label,
        row.movement.reason?.trim() ?? '',
      ],
  ];

  String _fileName(StockReportPack pack, String extension) {
    if (pack.kind == StockReportKind.onHand) {
      return 'creovo_stock_on_hand_${StockDay.iso(pack.asOf)}.$extension';
    }
    return 'creovo_stock_movements_${StockDay.iso(pack.period.from)}_to_${StockDay.iso(pack.period.to)}.$extension';
  }
}
