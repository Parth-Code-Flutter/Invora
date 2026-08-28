import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/data_import_models.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/csv_codec.dart';
import 'package:creovo_invoice/data/services/data_import_service.dart';
import 'package:creovo_invoice/data/services/import_value_parsers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CSV decoder keeps Unicode, quotes and Indian commas', () {
    final rows = CsvCodec.decode(
      '\uFEFFName,Notes\r\n"શ્રી Ram, Traders","Prefers ""email"""\r\n',
    );
    expect(rows, hasLength(2));
    expect(rows.last, ['શ્રી Ram, Traders', 'Prefers "email"']);
  });

  test('parses Indian dates, money and GSTIN', () {
    expect(ImportValueParsers.parseDate('15/03/2026'), DateTime(2026, 3, 15));
    expect(ImportValueParsers.parseDate('2026-04-01'), DateTime(2026, 4, 1));
    expect(ImportValueParsers.parseMoneyMinor('1,23,456.78'), 12345678);
    expect(ImportValueParsers.parseMoneyMinor('₹ 1,180'), 118000);
    expect(ImportValueParsers.parseGstin('27aapfu0939f1zv'), '27AAPFU0939F1ZV');
    expect(ImportValueParsers.hasInvalidGstin('ABC'), isTrue);
    expect(ImportValueParsers.parseGstBasisPoints('18%'), 1800);
    expect(ImportValueParsers.hasOddHsn('12'), isTrue);
  });

  group('DataImportService', () {
    late AppDatabase database;
    late DataImportService importer;
    late CustomerRepository customers;
    late ProductRepository products;
    late InvoiceRepository invoices;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      customers = CustomerRepository(database);
      products = ProductRepository(database);
      invoices = InvoiceRepository(database);
      importer = DataImportService(
        database: database,
        customers: customers,
        products: products,
        invoices: invoices,
        purchases: PurchaseRepository(database),
      );
    });

    tearDown(() => database.close());

    test('imports Unicode customers and skips GSTIN duplicates', () async {
      await customers.save(
        CustomerModel(
          name: 'Existing',
          gstin: '27AAPFU0939F1ZV',
          mobile: '9000000000',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      final preview = importer.preview(
        kind: DataImportKind.customers,
        sourceFileName: 'customers.csv',
        table: [
          ['Name', 'Mobile', 'GSTIN'],
          ['શ્રી Ram', '9876543210', '27AAPFU0939F1ZV'],
          ['New Party', '9123456780', ''],
        ],
      );
      expect(preview.validCount, 2);
      final result = await importer.commit(
        preview: preview,
        policy: DuplicateImportPolicy.skip,
      );
      expect(result.importedCount, 1);
      expect(result.skippedCount, 1);
      final saved = await customers.watchCustomers().first;
      expect(
        saved.map((row) => row.name),
        containsAll(['Existing', 'New Party']),
      );
      expect(saved.any((row) => row.name == 'શ્રી Ram'), isFalse);
    });

    test('updates a matching catalog item', () async {
      await products.save(
        ProductServiceModel(
          name: 'Notebook A5',
          type: ItemType.product,
          unit: 'Pcs',
          salePriceMinor: 4000,
          hsnSac: '4820',
          taxRateBasisPoints: 1800,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      final preview = importer.preview(
        kind: DataImportKind.products,
        sourceFileName: 'products.csv',
        table: [
          ['Name', 'Sale price', 'HSN/SAC', 'GST rate'],
          ['Notebook A5', '55.00', '4820', '18'],
        ],
      );
      final result = await importer.commit(
        preview: preview,
        policy: DuplicateImportPolicy.update,
      );
      expect(result.importedCount, 1);
      final saved = await products.watchItems().first;
      expect(saved, hasLength(1));
      expect(saved.single.salePriceMinor, 5500);
    });

    test('rejects bad GSTIN and still imports valid unpaid invoices', () async {
      final preview = importer.preview(
        kind: DataImportKind.unpaidInvoices,
        sourceFileName: 'invoices.csv',
        table: [
          [
            'Customer name',
            'GSTIN',
            'Invoice number',
            'Date',
            'Taxable value',
            'GST rate',
          ],
          ['Bad GST', 'NOTAGSTIN', 'INV-1', '01/04/2026', '1000', '18'],
          ['Good GST', '27AAPFU0939F1ZV', 'INV-2', '01/04/2026', '1000', '18'],
        ],
      );
      expect(preview.rejectedCount, 1);
      expect(preview.validCount, 1);
      final result = await importer.commit(
        preview: preview,
        policy: DuplicateImportPolicy.skip,
      );
      expect(result.importedCount, 1);
      final documents = await invoices.watchSummaries().first;
      expect(documents.single.invoiceNumber, 'INV-2');
    });

    test(
      'rolls back the whole batch when a later row cannot be saved',
      () async {
        final preview = importer.preview(
          kind: DataImportKind.unpaidInvoices,
          sourceFileName: 'invoices.csv',
          table: [
            [
              'Customer name',
              'Invoice number',
              'Date',
              'Taxable value',
              'GST rate',
            ],
            ['A', 'INV-KEEP', '2026-04-01', '500', '0'],
            ['B', 'INV-DUP', '2026-04-01', '500', '0'],
          ],
        );
        await importer.commit(
          preview: importer.preview(
            kind: DataImportKind.unpaidInvoices,
            sourceFileName: 'seed.csv',
            table: [
              [
                'Customer name',
                'Invoice number',
                'Date',
                'Taxable value',
                'GST rate',
              ],
              ['Seed', 'INV-DUP', '2026-03-01', '100', '0'],
            ],
          ),
          policy: DuplicateImportPolicy.skip,
        );
        await expectLater(
          importer.commit(
            preview: preview,
            policy: DuplicateImportPolicy.update,
          ),
          throwsA(isA<StateError>()),
        );
        final documents = await invoices.watchSummaries().first;
        expect(documents.map((row) => row.invoiceNumber), ['INV-DUP']);
      },
    );

    test(
      'imports 10,000 customer rows in one transaction',
      () async {
        final table = <List<String>>[
          ['Name', 'Mobile'],
          for (var i = 0; i < 10000; i++)
            [
              'Party ${i.toString().padLeft(5, '0')}',
              '9${i.toString().padLeft(9, '0')}',
            ],
        ];
        final preview = importer.preview(
          kind: DataImportKind.customers,
          sourceFileName: 'bulk.csv',
          table: table,
        );
        expect(preview.validCount, 10000);
        final result = await importer.commit(
          preview: preview,
          policy: DuplicateImportPolicy.skip,
        );
        expect(result.importedCount, 10000);
        expect(await customers.watchCustomers().first, hasLength(10000));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
