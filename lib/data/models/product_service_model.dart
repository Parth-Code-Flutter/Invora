import '../../app/enums/item_type.dart';
import 'product_attribute_model.dart';

class ProductServiceModel {
  const ProductServiceModel({
    this.id,
    required this.name,
    required this.type,
    this.description,
    required this.unit,
    required this.salePriceMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
    this.attributes = const [],
    this.isDeleted = false,
    this.trackStock = false,
    this.imagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final ItemType type;
  final String? description;
  final String unit;
  final int salePriceMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final List<ProductAttributeValue> attributes;
  final bool isDeleted;
  final bool trackStock;
  final List<String> imagePaths;
  final DateTime createdAt;
  final DateTime updatedAt;
}
