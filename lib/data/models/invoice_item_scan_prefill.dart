import '../../app/utils/currency_utils.dart';
import '../../app/utils/quantity_utils.dart';
import 'product_attribute_model.dart';
import 'product_service_model.dart';

/// Catalog values copied into the invoice item sheet so the user can edit
/// quantity, rate, or tax before adding the line.
class InvoiceItemScanPrefill {
  const InvoiceItemScanPrefill({
    required this.productId,
    required this.name,
    this.description,
    required this.quantityText,
    required this.unit,
    required this.rateText,
    required this.hsnSac,
    required this.taxRateBasisPoints,
    this.attributes = const [],
  });

  factory InvoiceItemScanPrefill.fromProduct(ProductServiceModel product) {
    return InvoiceItemScanPrefill(
      productId: product.id,
      name: product.name,
      description: product.description,
      quantityText: QuantityUtils.toInputValue(QuantityUtils.scale),
      unit: product.unit,
      rateText: CurrencyUtils.toInputValue(product.salePriceMinor),
      hsnSac: product.hsnSac ?? '',
      taxRateBasisPoints: product.taxRateBasisPoints,
      attributes: product.attributes,
    );
  }

  final int? productId;
  final String name;
  final String? description;
  final String quantityText;
  final String unit;
  final String rateText;
  final String hsnSac;
  final int taxRateBasisPoints;
  final List<ProductAttributeValue> attributes;
}
