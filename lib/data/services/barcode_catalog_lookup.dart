import '../models/product_service_model.dart';
import '../repositories/product_repository.dart';

/// Resolves a scanned barcode to a saved catalog product.
///
/// Codes are matched against SKU and barcode attributes so scanning stays
/// offline and does not need a dedicated barcode column.
class BarcodeCatalogLookup {
  const BarcodeCatalogLookup(this._repository);

  final ProductRepository _repository;

  /// Keys that represent a scannable product code in catalog attributes.
  static const codeKeys = {'sku', 'barcode'};

  Future<ProductServiceModel?> find(String rawCode) {
    return _repository.findByBarcode(normalize(rawCode));
  }

  static String normalize(String rawCode) =>
      rawCode.trim().replaceAll(RegExp(r'\s+'), '');

  static bool hasCode(ProductServiceModel product, String normalizedCode) {
    if (normalizedCode.isEmpty) return false;
    for (final attribute in product.attributes) {
      if (!codeKeys.contains(attribute.key)) continue;
      if (normalize(attribute.value) == normalizedCode) return true;
    }
    return false;
  }
}
