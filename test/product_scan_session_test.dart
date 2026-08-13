import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/product_attribute_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/modules/invoices/scan/product_scan_session.dart';

ProductServiceModel _product({
  required int id,
  required String name,
  int price = 500,
}) {
  final now = DateTime(2026, 8, 13);
  return ProductServiceModel(
    id: id,
    name: name,
    type: ItemType.product,
    unit: 'pcs',
    salePriceMinor: price,
    attributes: [
      ProductAttributeValue(key: 'sku', label: 'SKU / Code', value: '$id'),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('repeat scans of the same product increase quantity, not rows', () {
    final session = ProductScanSession(cooldown: Duration.zero);
    final biscuits = _product(id: 1, name: '50-50 Biscuit');
    expect(
      session.applyProduct(product: biscuits, rawCode: '8901'),
      ScanApplyResult.added,
    );
    expect(
      session.applyProduct(product: biscuits, rawCode: '8901'),
      ScanApplyResult.incremented,
    );
    expect(session.uniqueItemCount, 1);
    expect(session.lines.single.quantityScaled, 2000);
    expect(session.totalMinor, 1000);
  });

  test('cooldown ignores the same code fired by a held camera', () {
    final session = ProductScanSession(
      cooldown: const Duration(milliseconds: 1400),
    );
    final biscuits = _product(id: 1, name: '50-50 Biscuit');
    final now = DateTime(2026, 8, 13, 10);
    expect(
      session.applyProduct(product: biscuits, rawCode: '8901', now: now),
      ScanApplyResult.added,
    );
    expect(
      session.applyProduct(
        product: biscuits,
        rawCode: '8901',
        now: now.add(const Duration(milliseconds: 400)),
      ),
      ScanApplyResult.ignored,
    );
    expect(session.lines.single.quantityScaled, 1000);
  });

  test('decrement removes a line when quantity reaches one', () {
    final session = ProductScanSession(cooldown: Duration.zero);
    session.applyProduct(
      product: _product(id: 2, name: 'Bourbon'),
      rawCode: '2',
    );
    expect(session.decrementAt(0), isTrue);
    expect(session.lines, isEmpty);
  });
}
