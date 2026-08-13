/// Route arguments for the product create/edit form.
class ProductFormArgs {
  const ProductFormArgs({this.productId, this.initialSku});

  /// Existing catalog row when editing.
  final int? productId;

  /// Barcode captured by the scanner, stored as the product SKU.
  final String? initialSku;
}
