import 'package:drift/drift.dart';
import 'dart:convert';

import '../../app/enums/item_type.dart';
import '../models/product_service_model.dart';
import '../models/product_attribute_model.dart';
import '../services/app_database.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository {
  const ProductRepository(super.database);

  Stream<List<ProductServiceModel>> watchItems({
    String query = '',
    ItemType? type,
  }) {
    final statement = database.select(database.productServices)
      ..where((table) => table.isDeleted.equals(false))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    final search = query.trim().toLowerCase();
    if (type != null) {
      statement.where((table) => table.type.equals(type.name));
    }
    return statement.watch().map((rows) {
      final values = rows.map(_toModel);
      if (search.isEmpty) return values.toList(growable: false);
      return values
          .where((item) {
            final content = [
              item.name,
              item.description,
              item.hsnSac,
              ...item.attributes.expand((value) => [value.label, value.value]),
            ].whereType<String>().join(' ').toLowerCase();
            return content.contains(search);
          })
          .toList(growable: false);
    });
  }

  Future<List<ProductServiceModel>> listItems({ItemType? type}) async {
    final statement = database.select(database.productServices)
      ..where((table) => table.isDeleted.equals(false))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (type != null) {
      statement.where((table) => table.type.equals(type.name));
    }
    final rows = await statement.get();
    return rows.map(_toModel).toList(growable: false);
  }

  Future<ProductServiceModel?> getById(int id) async {
    final row = await (database.select(
      database.productServices,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Finds an active catalog item whose SKU or barcode attribute matches [code].
  Future<ProductServiceModel?> findByBarcode(String code) async {
    final normalized = code.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return null;
    final rows = await (database.select(
      database.productServices,
    )..where((table) => table.isDeleted.equals(false))).get();
    for (final row in rows) {
      final model = _toModel(row);
      final matches = model.attributes.any((attribute) {
        if (attribute.key != 'sku' && attribute.key != 'barcode') {
          return false;
        }
        return attribute.value.trim().replaceAll(RegExp(r'\s+'), '') ==
            normalized;
      });
      if (matches) return model;
    }
    return null;
  }

  Future<ProductServiceModel> save(ProductServiceModel model) async {
    final companion = ProductServicesCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      name: Value(model.name),
      type: Value(model.type.name),
      description: Value(model.description),
      unit: Value(model.unit),
      salePriceMinor: Value(model.salePriceMinor),
      hsnSac: Value(model.hsnSac),
      taxRateBasisPoints: Value(model.taxRateBasisPoints),
      attributesJson: Value(
        jsonEncode(model.attributes.map((value) => value.toJson()).toList()),
      ),
      isDeleted: Value(model.isDeleted),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
    final id = await database
        .into(database.productServices)
        .insert(companion, mode: InsertMode.insertOrReplace);
    return (await getById(model.id ?? id))!;
  }

  Future<void> softDelete(int id) async {
    await (database.update(
      database.productServices,
    )..where((table) => table.id.equals(id))).write(
      ProductServicesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  ProductServiceModel _toModel(ProductService row) {
    return ProductServiceModel(
      id: row.id,
      name: row.name,
      type: ItemType.fromStorage(row.type),
      description: row.description,
      unit: row.unit,
      salePriceMinor: row.salePriceMinor,
      hsnSac: row.hsnSac,
      taxRateBasisPoints: row.taxRateBasisPoints,
      attributes: _attributes(row.attributesJson),
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  List<ProductAttributeValue> _attributes(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map(
            (value) => ProductAttributeValue.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .where((value) => value.key.isNotEmpty && value.value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
