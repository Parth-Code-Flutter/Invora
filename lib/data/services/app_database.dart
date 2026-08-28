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
  IntColumn get creditedAmountMinor =>
      integer().withDefault(const Constant(0))();
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

@TableIndex(
  name: 'credit_notes_number',
  columns: {#creditNoteNumber},
  unique: true,
)
@TableIndex(name: 'credit_notes_invoice', columns: {#invoiceId})
class CreditNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get creditNoteNumber => text()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get customerId => integer().nullable()();
  TextColumn get customerName => text()();
  DateTimeColumn get creditNoteDate => dateTime()();
  TextColumn get reason => text()();
  TextColumn get taxType => text()();
  IntColumn get subtotalMinor => integer()();
  IntColumn get itemDiscountMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxableMinor => integer()();
  IntColumn get taxMinor => integer()();
  IntColumn get cgstMinor => integer()();
  IntColumn get sgstMinor => integer()();
  IntColumn get igstMinor => integer()();
  IntColumn get roundOffMinor => integer().withDefault(const Constant(0))();
  IntColumn get grandTotalMinor => integer()();
  IntColumn get refundedMinor => integer().withDefault(const Constant(0))();
  TextColumn get refundMethod => text().nullable()();
  DateTimeColumn get refundedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CreditNoteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get creditNoteId =>
      integer().references(CreditNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get invoiceItemId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantityScaled => integer()();
  TextColumn get unit => text()();
  IntColumn get rateMinor => integer()();
  TextColumn get hsnSac => text().nullable()();
  IntColumn get taxRateBasisPoints => integer()();
  TextColumn get discountType => text()();
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get baseAmountMinor => integer()();
  IntColumn get discountAmountMinor => integer()();
  IntColumn get taxableAmountMinor => integer()();
  IntColumn get taxAmountMinor => integer()();
  IntColumn get totalMinor => integer()();
  IntColumn get sortOrder => integer()();
}

@TableIndex(name: 'credit_note_applications_note', columns: {#creditNoteId})
@TableIndex(name: 'credit_note_applications_invoice', columns: {#invoiceId})
class CreditNoteApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get creditNoteId =>
      integer().references(CreditNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get appliedAt => dateTime()();
}

@TableIndex(name: 'suppliers_name', columns: {#name})
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get companyName => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get gstRegistrationType =>
      text().withDefault(const Constant('unregistered'))();
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
  IntColumn get debitedAmountMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get balanceMinor => integer()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get cancellationReason => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get placeOfSupply => text().nullable()();
  TextColumn get taxMode => text().withDefault(const Constant('cgst_sgst'))();
  BoolColumn get reverseCharge =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get itcEligible => boolean().withDefault(const Constant(true))();
  IntColumn get discountMinor => integer().withDefault(const Constant(0))();
  IntColumn get additionalChargesMinor =>
      integer().withDefault(const Constant(0))();
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
  TextColumn get hsnSac => text().nullable()();
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
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get entryType => text().withDefault(const Constant('payment'))();
  IntColumn get reversesPaymentId => integer().nullable()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PurchaseBillAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseBillId =>
      integer().references(PurchaseBills, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get localPath => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(
  name: 'debit_notes_number',
  columns: {#debitNoteNumber},
  unique: true,
)
@TableIndex(name: 'debit_notes_bill', columns: {#purchaseBillId})
class DebitNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get debitNoteNumber => text()();
  IntColumn get purchaseBillId => integer().references(PurchaseBills, #id)();
  IntColumn get supplierId => integer().nullable()();
  TextColumn get supplierName => text()();
  DateTimeColumn get debitNoteDate => dateTime()();
  TextColumn get reason => text()();
  TextColumn get taxMode => text().withDefault(const Constant('cgst_sgst'))();
  BoolColumn get itcEligible => boolean().withDefault(const Constant(true))();
  IntColumn get subtotalMinor => integer()();
  IntColumn get taxMinor => integer()();
  IntColumn get cgstMinor => integer().withDefault(const Constant(0))();
  IntColumn get sgstMinor => integer().withDefault(const Constant(0))();
  IntColumn get igstMinor => integer().withDefault(const Constant(0))();
  IntColumn get grandTotalMinor => integer()();
  IntColumn get refundedMinor => integer().withDefault(const Constant(0))();
  TextColumn get refundMethod => text().nullable()();
  DateTimeColumn get refundedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class DebitNoteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debitNoteId =>
      integer().references(DebitNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get purchaseItemId => integer().nullable()();
  TextColumn get name => text()();
  IntColumn get quantityScaled => integer()();
  TextColumn get unit => text()();
  IntColumn get rateMinor => integer()();
  TextColumn get hsnSac => text().nullable()();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  IntColumn get baseAmountMinor => integer()();
  IntColumn get taxAmountMinor => integer()();
  IntColumn get totalMinor => integer()();
  IntColumn get sortOrder => integer()();
}

@TableIndex(name: 'debit_note_applications_note', columns: {#debitNoteId})
@TableIndex(name: 'debit_note_applications_bill', columns: {#purchaseBillId})
class DebitNoteApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debitNoteId =>
      integer().references(DebitNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get purchaseBillId => integer().references(PurchaseBills, #id)();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get appliedAt => dateTime()();
}

@TableIndex(name: 'expenses_number', columns: {#expenseNumber}, unique: true)
@TableIndex(name: 'expenses_date', columns: {#expenseDate})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get expenseNumber => text()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get category => text()();
  TextColumn get payee => text()();
  IntColumn get amountMinor => integer()();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  IntColumn get taxMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxableMinor => integer().withDefault(const Constant(0))();
  IntColumn get grandTotalMinor => integer()();
  BoolColumn get itcEligible => boolean().withDefault(const Constant(false))();
  TextColumn get paymentMethod => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('recorded'))();
  TextColumn get cancellationReason => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'money_accounts_type', columns: {#accountType})
class MoneyAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get accountType => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'money_movements_account', columns: {#accountId})
@TableIndex(name: 'money_movements_occurred', columns: {#occurredAt})
@TableIndex(name: 'money_movements_source', columns: {#sourceType, #sourceId})
class MoneyMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(MoneyAccounts, #id)();
  TextColumn get direction => text()();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get entryType => text()();
  TextColumn get sourceType => text()();
  IntColumn get sourceId => integer().nullable()();
  IntColumn get pairedMovementId => integer().nullable()();
  IntColumn get reversesMovementId => integer().nullable()();
  TextColumn get chequeStatus => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'party_advances_party', columns: {#partyType, #partyId})
class PartyAdvances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get partyType => text()();
  IntColumn get partyId => integer()();
  TextColumn get partyName => text()();
  IntColumn get accountId => integer().references(MoneyAccounts, #id)();
  IntColumn get amountMinor => integer()();
  IntColumn get remainingMinor => integer()();
  TextColumn get direction => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'party_advance_allocations_advance', columns: {#advanceId})
class PartyAdvanceAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get advanceId =>
      integer().references(PartyAdvances, #id, onDelete: KeyAction.cascade)();
  TextColumn get documentType => text()();
  IntColumn get documentId => integer()();
  TextColumn get documentNumber => text()();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get appliedAt => dateTime()();
}

@TableIndex(
  name: 'cash_closings_account_date',
  columns: {#accountId, #closingDate},
  unique: true,
)
class CashClosings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(MoneyAccounts, #id)();
  DateTimeColumn get closingDate => dateTime()();
  IntColumn get countedMinor => integer()();
  IntColumn get bookMinor => integer()();
  IntColumn get differenceMinor => integer()();
  IntColumn get movementId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'import_batches_created', columns: {#createdAt})
class ImportBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get sourceFileName => text()();
  TextColumn get duplicatePolicy => text()();
  IntColumn get importedCount => integer()();
  IntColumn get skippedCount => integer()();
  IntColumn get rejectedCount => integer()();
  IntColumn get warningCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'import_batch_records_batch', columns: {#batchId})
class ImportBatchRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get batchId =>
      integer().references(ImportBatches, #id, onDelete: KeyAction.cascade)();
  TextColumn get recordType => text()();
  IntColumn get recordId => integer()();
  TextColumn get action => text()();
}

@TableIndex(name: 'import_batch_errors_batch', columns: {#batchId})
class ImportBatchErrors extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get batchId =>
      integer().references(ImportBatches, #id, onDelete: KeyAction.cascade)();
  IntColumn get rowNumber => integer()();
  TextColumn get severity => text()();
  TextColumn get message => text()();
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
    CreditNotes,
    CreditNoteItems,
    CreditNoteApplications,
    Suppliers,
    PurchaseBills,
    PurchaseItems,
    PurchasePayments,
    PurchaseBillAttachments,
    DebitNotes,
    DebitNoteItems,
    DebitNoteApplications,
    Expenses,
    MoneyAccounts,
    MoneyMovements,
    PartyAdvances,
    PartyAdvanceAllocations,
    CashClosings,
    ImportBatches,
    ImportBatchRecords,
    ImportBatchErrors,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => DbConstants.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await seedDefaultMoneyAccounts();
    },
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
        await migrator.createTable(purchaseBillAttachments);
      }
      if (from >= 10 && from < 11) {
        final tables = (await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (tables.contains('purchase_bills')) {
          await migrator.addColumn(
            purchaseBills,
            purchaseBills.cancellationReason,
          );
          await migrator.addColumn(purchaseBills, purchaseBills.cancelledAt);
          await migrator.addColumn(purchaseBills, purchaseBills.placeOfSupply);
          await migrator.addColumn(purchaseBills, purchaseBills.taxMode);
          await migrator.addColumn(purchaseBills, purchaseBills.reverseCharge);
          await migrator.addColumn(purchaseBills, purchaseBills.itcEligible);
          await migrator.addColumn(purchaseBills, purchaseBills.discountMinor);
          await migrator.addColumn(
            purchaseBills,
            purchaseBills.additionalChargesMinor,
          );
        }
        if (tables.contains('purchase_items')) {
          await migrator.addColumn(purchaseItems, purchaseItems.hsnSac);
        }
        if (tables.contains('purchase_payments')) {
          await migrator.addColumn(
            purchasePayments,
            purchasePayments.reference,
          );
          await migrator.addColumn(
            purchasePayments,
            purchasePayments.entryType,
          );
          await migrator.addColumn(
            purchasePayments,
            purchasePayments.reversesPaymentId,
          );
        }
        await migrator.createTable(purchaseBillAttachments);
      }
      if (from >= 10 && from < 12) {
        final tables = (await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (tables.contains('suppliers')) {
          await migrator.addColumn(suppliers, suppliers.gstRegistrationType);
        }
      }
      if (from >= 5 && from < 13) {
        final tables = (await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (tables.contains('invoices')) {
          await migrator.addColumn(invoices, invoices.creditedAmountMinor);
        }
      }
      if (from < 13) {
        await migrator.createTable(creditNotes);
        await migrator.createTable(creditNoteItems);
        await migrator.createTable(creditNoteApplications);
      }
      if (from < 14) {
        await migrator.createTable(expenses);
      }
      if (from >= 10 && from < 15) {
        final tables = (await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (tables.contains('purchase_bills')) {
          await migrator.addColumn(
            purchaseBills,
            purchaseBills.debitedAmountMinor,
          );
        }
      }
      if (from < 15) {
        await migrator.createTable(debitNotes);
        await migrator.createTable(debitNoteItems);
        await migrator.createTable(debitNoteApplications);
      }
      if (from < 16) {
        await migrator.createTable(moneyAccounts);
        await migrator.createTable(moneyMovements);
        await migrator.createTable(partyAdvances);
        await migrator.createTable(partyAdvanceAllocations);
        await migrator.createTable(cashClosings);
        await seedDefaultMoneyAccounts();
        await backfillMoneyMovements();
      }
      if (from < 17) {
        await migrator.createTable(importBatches);
        await migrator.createTable(importBatchRecords);
        await migrator.createTable(importBatchErrors);
      }
    },
  );

  Future<void> seedDefaultMoneyAccounts() async {
    final existing = await select(moneyAccounts).get();
    if (existing.isNotEmpty) return;
    const defaults = <(String, String, int)>[
      ('Cash', 'cash', 0),
      ('Bank', 'bank', 1),
      ('UPI', 'upi', 2),
      ('Card', 'card', 3),
      ('Other', 'other', 4),
    ];
    for (final row in defaults) {
      await into(moneyAccounts).insert(
        MoneyAccountsCompanion.insert(
          name: row.$1,
          accountType: row.$2,
          isSystem: const Value(true),
          sortOrder: Value(row.$3),
        ),
      );
    }
  }

  Future<void> backfillMoneyMovements() async {
    final existing = await select(moneyMovements).get();
    if (existing.isNotEmpty) return;
    final accounts = await select(moneyAccounts).get();
    if (accounts.isEmpty) return;
    int accountIdFor(String? method) {
      final type = _accountTypeForMethod(method);
      return accounts
          .firstWhere(
            (account) => account.accountType == type,
            orElse: () => accounts.last,
          )
          .id;
    }

    Future<void> insertMovement({
      required int accountId,
      required String direction,
      required int amountMinor,
      required DateTime occurredAt,
      required String entryType,
      required String sourceType,
      required int sourceId,
      String? chequeStatus,
      String? reference,
      String? note,
      DateTime? createdAt,
    }) async {
      if (amountMinor <= 0) return;
      await into(moneyMovements).insert(
        MoneyMovementsCompanion.insert(
          accountId: accountId,
          direction: direction,
          amountMinor: amountMinor,
          occurredAt: occurredAt,
          entryType: entryType,
          sourceType: sourceType,
          sourceId: Value(sourceId),
          chequeStatus: Value(chequeStatus),
          reference: Value(reference),
          note: Value(note),
          createdAt: Value(createdAt ?? occurredAt),
        ),
      );
    }

    for (final row in await select(invoicePayments).get()) {
      await insertMovement(
        accountId: accountIdFor(row.method),
        direction: row.amountMinor >= 0 ? 'in' : 'out',
        amountMinor: row.amountMinor.abs(),
        occurredAt: row.paidAt,
        entryType: row.entryType == 'reversal' ? 'reversal' : 'receipt',
        sourceType: 'invoice_payment',
        sourceId: row.id,
        chequeStatus: _historicalChequeStatus(row.method, row.entryType),
        reference: row.reference,
        note: row.note,
        createdAt: row.createdAt,
      );
    }
    for (final row in await select(purchasePayments).get()) {
      await insertMovement(
        accountId: accountIdFor(row.method),
        direction: row.amountMinor >= 0 ? 'out' : 'in',
        amountMinor: row.amountMinor.abs(),
        occurredAt: row.paidAt,
        entryType: row.entryType == 'reversal' ? 'reversal' : 'payment',
        sourceType: 'purchase_payment',
        sourceId: row.id,
        chequeStatus: _historicalChequeStatus(row.method, row.entryType),
        reference: row.reference,
        note: row.note,
        createdAt: row.createdAt,
      );
    }
    for (final row in await select(expenses).get()) {
      if (row.status == 'cancelled') continue;
      await insertMovement(
        accountId: accountIdFor(row.paymentMethod),
        direction: 'out',
        amountMinor: row.grandTotalMinor,
        occurredAt: row.expenseDate,
        entryType: 'expense',
        sourceType: 'expense',
        sourceId: row.id,
        note: '${row.category} · ${row.payee}',
        createdAt: row.createdAt,
      );
    }
    for (final row in await select(creditNotes).get()) {
      if (row.refundedMinor <= 0) continue;
      await insertMovement(
        accountId: accountIdFor(row.refundMethod),
        direction: 'out',
        amountMinor: row.refundedMinor,
        occurredAt: row.refundedAt ?? row.creditNoteDate,
        entryType: 'refund',
        sourceType: 'credit_note',
        sourceId: row.id,
        note: row.refundMethod,
        createdAt: row.createdAt,
      );
    }
    for (final row in await select(debitNotes).get()) {
      if (row.refundedMinor <= 0) continue;
      await insertMovement(
        accountId: accountIdFor(row.refundMethod),
        direction: 'in',
        amountMinor: row.refundedMinor,
        occurredAt: row.refundedAt ?? row.debitNoteDate,
        entryType: 'refund',
        sourceType: 'debit_note',
        sourceId: row.id,
        note: row.refundMethod,
        createdAt: row.createdAt,
      );
    }
  }
}

String _accountTypeForMethod(String? method) {
  final value = (method ?? '').trim().toLowerCase();
  if (value.contains('upi')) return 'upi';
  if (value.contains('cash')) return 'cash';
  if (value.contains('card')) return 'card';
  if (value.contains('cheque') || value.contains('check')) return 'bank';
  if (value.contains('bank')) return 'bank';
  return 'other';
}

String? _historicalChequeStatus(String? method, String entryType) {
  if (entryType == 'reversal') return null;
  final value = (method ?? '').toLowerCase();
  if (value.contains('cheque') || value.contains('check')) return 'cleared';
  return null;
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
