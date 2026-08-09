import 'package:drift/drift.dart';

import '../../app/enums/item_type.dart';
import '../models/product_service_model.dart';
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
    final search = query.trim();
    if (search.isNotEmpty) {
      statement.where(
        (table) =>
            table.name.contains(search) |
            table.description.contains(search) |
            table.hsnSac.contains(search),
      );
    }
    if (type != null) {
      statement.where((table) => table.type.equals(type.name));
    }
    return statement.watch().map(
      (rows) => rows.map(_toModel).toList(growable: false),
    );
  }

  Future<ProductServiceModel?> getById(int id) async {
    final row = await (database.select(
      database.productServices,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
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
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
