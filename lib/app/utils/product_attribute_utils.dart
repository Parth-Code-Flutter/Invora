import '../../data/models/product_attribute_model.dart';

abstract final class ProductAttributeUtils {
  static const priority = <String>[
    'variant',
    'size',
    'color',
    'material',
    'brand',
    'modelNumber',
    'sku',
    'weight',
    'dimensions',
  ];

  static String compact(
    List<ProductAttributeValue> values, {
    int maximum = 3,
    bool includeLabels = true,
  }) {
    final sorted = [...values]
      ..sort((left, right) {
        final leftIndex = priority.indexOf(left.key);
        final rightIndex = priority.indexOf(right.key);
        return (leftIndex < 0 ? 999 : leftIndex).compareTo(
          rightIndex < 0 ? 999 : rightIndex,
        );
      });
    return sorted
        .where((value) => value.value.trim().isNotEmpty)
        .take(maximum)
        .map(
          (value) =>
              includeLabels ? '${value.label}: ${value.value}' : value.value,
        )
        .join(' • ');
  }
}
