import '../models/product_service_model.dart';

/// One catalog product captured during a scan session, with invoice quantity.
class ScannedInvoiceLine {
  const ScannedInvoiceLine({
    required this.product,
    required this.barcode,
    this.quantityScaled = 1000,
  });

  final ProductServiceModel product;
  final String barcode;

  /// Quantity using the invoice scale (1000 = 1 unit).
  final int quantityScaled;

  int get lineTotalMinor => (product.salePriceMinor * quantityScaled) ~/ 1000;

  ScannedInvoiceLine increment() => ScannedInvoiceLine(
    product: product,
    barcode: barcode,
    quantityScaled: quantityScaled + 1000,
  );

  ScannedInvoiceLine decrement() => ScannedInvoiceLine(
    product: product,
    barcode: barcode,
    quantityScaled: quantityScaled <= 1000 ? 1000 : quantityScaled - 1000,
  );
}
