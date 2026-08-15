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
  TextColumn get attributesJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'invoices_number', columns: {#invoiceNumber}, unique: true)
@TableIndex(name: 'invoices_status', columns: {#status})
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  TextColumn get documentType =>
      text().withDefault(const Constant('invoice'))();
  IntColumn get customerId => integer().nullable()();
  TextColumn get customerName => text()();
  TextColumn get customerCompany => text().nullable()();
  TextColumn get customerMobile => text().nullable()();
  TextColumn get customerEmail => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get customerCity => text().nullable()();
  TextColumn get customerState => text().nullable()();
  TextColumn get customerPinCode => text().nullable()();
  TextColumn get customerGstin => text().nullable()();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get taxType => text()();
  TextColumn get discountType => text()();
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get subtotalMinor => integer()();
  IntColumn get itemDiscountMinor => integer()();
  IntColumn get invoiceDiscountMinor => integer()();
  IntColumn get taxableMinor => integer()();
  IntColumn get taxMinor => integer()();
  IntColumn get cgstMinor => integer()();
  IntColumn get sgstMinor => integer()();
  IntColumn get igstMinor => integer()();
  IntColumn get chargesMinor => integer()();
  IntColumn get roundOffMinor => integer()();
  IntColumn get grandTotalMinor => integer()();
  IntColumn get paidAmountMinor => integer()();
  IntColumn get balanceMinor => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get terms => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantityScaled => integer()();
  TextColumn get unit => text()();
  IntColumn get rateMinor => integer()();
  TextColumn get hsnSac => text().nullable()();
  IntColumn get taxRateBasisPoints => integer()();
  TextColumn get attributesJson => text().withDefault(const Constant('[]'))();
  TextColumn get discountType => text()();
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get baseAmountMinor => integer()();
  IntColumn get discountAmountMinor => integer()();
  IntColumn get taxableAmountMinor => integer()();
  IntColumn get taxAmountMinor => integer()();
  IntColumn get totalMinor => integer()();
  IntColumn get sortOrder => integer()();
}

class InvoiceCharges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get amountMinor => integer()();
  IntColumn get sortOrder => integer()();
}

@TableIndex(name: 'invoice_payments_invoice', columns: {#invoiceId})
class InvoicePayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer()();
  TextColumn get method => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get entryType => text().withDefault(const Constant('payment'))();
  IntColumn get reversesPaymentId => integer().nullable()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'suppliers_name', columns: {#name})
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get companyName => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'purchase_bills_number', columns: {#billNumber})
class PurchaseBills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get billNumber => text()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get supplierName => text()();
  DateTimeColumn get billDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get subtotalMinor => integer()();
  IntColumn get taxMinor => integer().withDefault(const Constant(0))();
  IntColumn get totalMinor => integer()();
  IntColumn get paidMinor => integer().withDefault(const Constant(0))();
  IntColumn get balanceMinor => integer()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseBillId =>
      integer().references(PurchaseBills, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get quantityScaled => integer()();
  TextColumn get unit => text()();
  IntColumn get rateMinor => integer()();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalMinor => integer()();
  IntColumn get sortOrder => integer()();
}

class PurchasePayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseBillId =>
      integer().references(PurchaseBills, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer()();
  TextColumn get method => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    DatabaseMetadata,
    BusinessProfiles,
    Customers,
    ProductServices,
    Invoices,
    InvoiceItems,
    InvoiceCharges,
    InvoicePayments,
    Suppliers,
    PurchaseBills,
    PurchaseItems,
    PurchasePayments,
  ],
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
      if (from < 5) {
        await migrator.createTable(invoices);
        await migrator.createTable(invoiceItems);
        await migrator.createTable(invoiceCharges);
      }
      if (from < 6) {
        await migrator.addColumn(invoices, invoices.documentType);
      }
      if (from < 7) {
        await migrator.createTable(invoicePayments);
        // Older versions only stored a cumulative amount. Preserve it as one
        // opening ledger entry so existing partial payments remain auditable.
        await customStatement('''
          INSERT INTO invoice_payments
            (invoice_id, amount_minor, method, note, entry_type, paid_at, created_at)
          SELECT id, paid_amount_minor, 'Previous payment',
                 'Imported during payment-history upgrade', 'imported',
                 updated_at, updated_at
          FROM invoices
          WHERE paid_amount_minor > 0
        ''');
      }
      // From v7 the table already exists without classification columns.
      // Older upgrades create the current table shape above and must not add
      // the same columns twice.
      if (from >= 7 && from < 8) {
        await migrator.addColumn(invoicePayments, invoicePayments.entryType);
        await migrator.addColumn(
          invoicePayments,
          invoicePayments.reversesPaymentId,
        );
        await customStatement('''
          UPDATE invoice_payments
          SET entry_type = CASE
            WHEN method = 'Previous payment' THEN 'imported'
            WHEN method = 'Opening payment' THEN 'opening'
            ELSE 'payment'
          END
        ''');
      }
      final existingTables = (await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get()).map((row) => row.read<String>('name')).toSet();
      if (from >= 4 &&
          from < 9 &&
          existingTables.contains('product_services')) {
        await migrator.addColumn(
          productServices,
          productServices.attributesJson,
        );
      }
      if (from >= 5 && from < 9 && existingTables.contains('invoice_items')) {
        await migrator.addColumn(invoiceItems, invoiceItems.attributesJson);
      }
      if (from < 10) {
        await migrator.createTable(suppliers);
        await migrator.createTable(purchaseBills);
        await migrator.createTable(purchaseItems);
        await migrator.createTable(purchasePayments);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await appDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}

Future<File> appDatabaseFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(p.join(directory.path, AppConstants.databaseFileName));
}
