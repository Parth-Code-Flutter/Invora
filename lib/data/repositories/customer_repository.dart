import 'package:drift/drift.dart';

import '../models/customer_model.dart';
import '../services/app_database.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository {
  const CustomerRepository(super.database);

  Stream<List<CustomerModel>> watchCustomers({String query = ''}) {
    final statement = database.select(database.customers)
      ..where((table) => table.isDeleted.equals(false))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    final search = query.trim();
    if (search.isNotEmpty) {
      statement.where(
        (table) =>
            table.name.contains(search) |
            table.companyName.contains(search) |
            table.mobile.contains(search) |
            table.gstin.contains(search),
      );
    }
    return statement.watch().map(
      (rows) => rows.map(_toModel).toList(growable: false),
    );
  }

  Future<CustomerModel?> getById(int id) async {
    final row = await (database.select(
      database.customers,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<CustomerModel> save(CustomerModel model) async {
    final companion = CustomersCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      name: Value(model.name),
      companyName: Value(model.companyName),
      mobile: Value(model.mobile),
      email: Value(model.email),
      address: Value(model.address),
      city: Value(model.city),
      state: Value(model.state),
      pinCode: Value(model.pinCode),
      gstin: Value(model.gstin),
      notes: Value(model.notes),
      isDeleted: Value(model.isDeleted),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
    final id = await database
        .into(database.customers)
        .insert(companion, mode: InsertMode.insertOrReplace);
    return (await getById(model.id ?? id))!;
  }

  Future<void> softDelete(int id) async {
    await (database.update(
      database.customers,
    )..where((table) => table.id.equals(id))).write(
      CustomersCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  CustomerModel _toModel(Customer row) {
    return CustomerModel(
      id: row.id,
      name: row.name,
      companyName: row.companyName,
      mobile: row.mobile,
      email: row.email,
      address: row.address,
      city: row.city,
      state: row.state,
      pinCode: row.pinCode,
      gstin: row.gstin,
      notes: row.notes,
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
