enum ItemType {
  product,
  service;

  String get label => switch (this) {
    ItemType.product => 'Product',
    ItemType.service => 'Service',
  };

  static ItemType fromStorage(String value) {
    return ItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ItemType.product,
    );
  }
}
