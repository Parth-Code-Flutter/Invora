class ProductAttributeValue {
  const ProductAttributeValue({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;

  Map<String, String> toJson() => {'key': key, 'label': label, 'value': value};

  factory ProductAttributeValue.fromJson(Map<String, dynamic> json) =>
      ProductAttributeValue(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );
}

enum ProductCustomFieldType { text, number }

class ProductCustomField {
  const ProductCustomField({
    required this.key,
    required this.label,
    this.type = ProductCustomFieldType.text,
  });
  final String key;
  final String label;
  final ProductCustomFieldType type;

  Map<String, String> toJson() => {
    'key': key,
    'label': label,
    'type': type.name,
  };

  factory ProductCustomField.fromJson(Map<String, dynamic> json) =>
      ProductCustomField(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        type: ProductCustomFieldType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ProductCustomFieldType.text,
        ),
      );
}
