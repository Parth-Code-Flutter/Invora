import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/gst_export_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/models/stock_models.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/csv_codec.dart';
import 'package:creovo_invoice/data/services/stock_ledger.dart';
import 'package:creovo_invoice/data/services/stock_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late StockLedger ledger;
  late ProductRepository products;
  late StockReportService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = StockLedger(database);
    products = ProductRepository(database);
    service = StockReportService(ledger, products);
  });

  tearDown(() => database.close());

  test('on-hand CSV uses as-of date and keeps later sales out', () async {
    final product = await _product(products, name: 'Teak board');
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 0},
    );
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: product.id!,
            quantityScaled: 8000,
            type: StockMovementType.opening.storage,
            sourceType: StockSourceType.opening.storage,
            sourceId: Value(product.id),
            createdAt: Value(DateTime(2026, 8, 1, 8)),
          ),
        );
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: product.id!,
            quantityScaled: -3000,
            type: StockMovementType.sale.storage,
            sourceType: StockSourceType.invoice.storage,
            sourceId: const Value(9),
            createdAt: Value(DateTime(2026, 8, 25, 12)),
          ),
        );

    final beforeSale = await service.buildOnHand(DateTime(2026, 8, 10));
    expect(beforeSale.enabled, isTrue);
    expect(beforeSale.onHand.single.quantityScaled, 8000);

    final csv = await service.buildCsv(beforeSale);
    expect(csv.fileName, 'creovo_stock_on_hand_2026-08-10.csv');
    final rows = CsvCodec.decode(utf8.decode(csv.bytes));
    expect(rows.first, ['Product', 'Unit', 'On hand']);
    expect(rows[1], ['Teak board', 'pcs', '8']);

    final afterSale = await service.buildOnHand(DateTime(2026, 8, 25));
    expect(afterSale.onHand.single.quantityScaled, 5000);

    final movements = await service.buildMovements(
      GstExportPeriod(
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 31),
        preset: GstExportPeriodPreset.custom,
      ),
    );
    expect(movements.movements, hasLength(2));
    expect(movements.inScaled, 8000);
    expect(movements.outScaled, 3000);

    final pdf = await service.buildPdf(afterSale);
    expect(pdf.extension, 'pdf');
    expect(pdf.bytes.length, greaterThan(100));
    expect(pdf.fileName, 'creovo_stock_on_hand_2026-08-25.pdf');
  });

  test('reports stay available to query when tracking is off', () async {
    final product = await _product(products);
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: product.id!,
            quantityScaled: 1000,
            type: StockMovementType.opening.storage,
            sourceType: StockSourceType.opening.storage,
            createdAt: Value(DateTime(2026, 8, 1)),
          ),
        );
    final pack = await service.buildOnHand(DateTime(2026, 8, 29));
    expect(pack.enabled, isFalse);
    expect(pack.onHand, isEmpty);
  });
}

Future<ProductServiceModel> _product(
  ProductRepository products, {
  String name = 'MDF Circle',
}) {
  final now = DateTime(2026, 8, 1);
  return products.save(
    ProductServiceModel(
      name: name,
      type: ItemType.product,
      unit: 'pcs',
      salePriceMinor: 10000,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
