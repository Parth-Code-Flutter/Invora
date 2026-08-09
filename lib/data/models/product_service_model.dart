import '../../app/enums/item_type.dart';

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
    this.isDeleted = false,
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
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}
