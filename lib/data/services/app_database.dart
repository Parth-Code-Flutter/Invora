import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/constants/app_constants.dart';
import '../../app/constants/db_constants.dart';

part 'app_database.g.dart';

class DatabaseMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class BusinessProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get businessName => text()();
  TextColumn get ownerName => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pinCode => text().nullable()();
  BoolColumn get gstRegistered =>
      boolean().withDefault(const Constant(false))();
  TextColumn get gstin => text().nullable()();
  TextColumn get pan => text().nullable()();
  TextColumn get invoicePrefix => text().withDefault(const Constant('INV'))();
  IntColumn get startingInvoiceNumber =>
      integer().withDefault(const Constant(1))();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('₹'))();
  TextColumn get bankName => text().nullable()();
  TextColumn get accountHolderName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get ifsc => text().nullable()();
  TextColumn get upiId => text().nullable()();
  TextColumn get paymentQrPath => text().nullable()();
  TextColumn get signaturePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'customers_name', columns: {#name})
@TableIndex(name: 'customers_mobile', columns: {#mobile})
@TableIndex(name: 'customers_gstin', columns: {#gstin})
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get companyName => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pinCode => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'products_name', columns: {#name})
@TableIndex(name: 'products_type', columns: {#type})
class ProductServices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get salePriceMinor => integer()();
  TextColumn get hsnSac => text().nullable()();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [DatabaseMetadata, BusinessProfiles, Customers, ProductServices],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => DbConstants.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(businessProfiles);
      }
      if (from < 3) {
        await migrator.createTable(customers);
      }
      if (from < 4) {
        await migrator.createTable(productServices);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, AppConstants.databaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
