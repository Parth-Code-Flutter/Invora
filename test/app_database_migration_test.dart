import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
  test('migrates complete v5 invoice data and all payment states', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(setup: _createV5Fixture),
    );

    final invoices = await database.customSelect('''
      SELECT id, document_type, paid_amount_minor, balance_minor
      FROM invoices ORDER BY id
    ''').get();
    expect(invoices, hasLength(3));
    expect(
      invoices.every((row) => row.read<String>('document_type') == 'invoice'),
      isTrue,
    );
    expect(invoices.map((row) => row.read<int>('paid_amount_minor')), [
      0,
      4000,
      10000,
    ]);
    expect(invoices.map((row) => row.read<int>('balance_minor')), [
      10000,
      6000,
      0,
    ]);

    final payments = await database.customSelect('''
      SELECT invoice_id, amount_minor, entry_type
      FROM invoice_payments ORDER BY invoice_id
    ''').get();
    expect(payments, hasLength(2));
    expect(payments.map((row) => row.read<int>('invoice_id')), [2, 3]);
    expect(payments.map((row) => row.read<int>('amount_minor')), [4000, 10000]);
    expect(
      payments.every((row) => row.read<String>('entry_type') == 'imported'),
      isTrue,
    );

    expect(
      (await database.customSelect('SELECT * FROM invoice_items').getSingle())
          .read<String>('name'),
      'Legacy service',
    );
    expect(
      (await database.customSelect('SELECT * FROM invoice_charges').getSingle())
          .read<String>('title'),
      'Delivery',
    );
    await database.close();
  });

  test('migrates a v7 payment table to classified schema v8', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE invoice_payments (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              amount_minor INTEGER NOT NULL,
              method TEXT NULL,
              reference TEXT NULL,
              note TEXT NULL,
              paid_at INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO invoice_payments
              (invoice_id, amount_minor, method, paid_at, created_at)
            VALUES (1, 5000, 'Opening payment', 0, 0)
          ''');
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );

    final row = await database
        .customSelect(
          'SELECT entry_type, reverses_payment_id FROM invoice_payments',
        )
        .getSingle();
    expect(row.read<String>('entry_type'), 'opening');
    expect(row.readNullable<int>('reverses_payment_id'), isNull);
    await database.close();
  });

  test('migrates directly from v6 without adding v8 columns twice', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE invoices (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              paid_amount_minor INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO invoices (paid_amount_minor, updated_at)
            VALUES (7500, 0)
          ''');
          raw.execute('PRAGMA user_version = 6');
        },
      ),
    );

    final row = await database
        .customSelect('SELECT amount_minor, entry_type FROM invoice_payments')
        .getSingle();
    expect(row.read<int>('amount_minor'), 7500);
    expect(row.read<String>('entry_type'), 'imported');
    await database.close();
  });

  test('failed v7 migration preserves version and user data', () async {
    dynamic legacyDatabase;
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          legacyDatabase = raw;
          // Deliberately malformed legacy table: migration classification
          // references `method`, so opening must fail inside Drift's migration
          // sequence and leave the original row/version available for
          // diagnosis or recovery.
          raw.execute('''
            CREATE TABLE invoice_payments (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              amount_minor INTEGER NOT NULL
            )
          ''');
          raw.execute(
            'INSERT INTO invoice_payments (invoice_id, amount_minor) VALUES (7, 9000)',
          );
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );

    await expectLater(
      database.customSelect('SELECT 1').getSingle(),
      throwsA(anything),
    );
    expect(legacyDatabase.userVersion, 7);
    expect(
      legacyDatabase.select(
        'SELECT invoice_id, amount_minor FROM invoice_payments',
      ),
      [containsPair('invoice_id', 7)],
    );
    await database.close();
  });

  test('creates delivery challan tables when upgrading from schema 17', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('PRAGMA user_version = 17');
        },
      ),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'delivery_challan%' ORDER BY name",
        )
        .get();
    expect(tables.map((row) => row.read<String>('name')), [
      'delivery_challan_invoices',
      'delivery_challan_items',
      'delivery_challans',
    ]);
    expect(database.schemaVersion, 22);
    await database.close();
  });

  test('creates purchase order tables when upgrading from schema 18', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('PRAGMA user_version = 18');
        },
      ),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'purchase_order%' ORDER BY name",
        )
        .get();
    expect(tables.map((row) => row.read<String>('name')), [
      'purchase_order_bills',
      'purchase_order_items',
      'purchase_orders',
    ]);
    expect(database.schemaVersion, 22);
    await database.close();
  });

  test('creates stock tables when upgrading from schema 19', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('PRAGMA user_version = 19');
        },
      ),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('stock_settings', 'stock_movements') ORDER BY name",
        )
        .get();
    expect(tables.map((row) => row.read<String>('name')), [
      'stock_movements',
      'stock_settings',
    ]);
    expect(database.schemaVersion, 22);
    final settings = await (database.select(
      database.stockSettings,
    )..where((table) => table.id.equals(1))).getSingle();
    expect(settings.enabled, isFalse);
    await database.close();
  });

  test('schema 20 with stock Off leaves products untracked', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) => _createV20StockFixture(raw, enabled: false),
      ),
    );
    final columns = await database
        .customSelect('PRAGMA table_info(product_services)')
        .get();
    expect(
      columns.any((row) => row.read<String>('name') == 'track_stock'),
      isTrue,
    );
    expect(database.schemaVersion, 22);
    final product = await (database.select(
      database.productServices,
    )..where((table) => table.name.equals('Sheet'))).getSingle();
    expect(product.trackStock, isFalse);
    await database.close();
  });

  test(
    'schema 20 with stock On copies Keep stock onto live products',
    () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (raw) => _createV20StockFixture(raw, enabled: true),
        ),
      );
      final product = await (database.select(
        database.productServices,
      )..where((table) => table.name.equals('Sheet'))).getSingle();
      final service = await (database.select(
        database.productServices,
      )..where((table) => table.name.equals('Install'))).getSingle();
      expect(product.trackStock, isTrue);
      expect(service.trackStock, isFalse);
      await database.close();
    },
  );

  test('schema 21 products gain empty image paths on upgrade', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE product_services (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              description TEXT NULL,
              unit TEXT NOT NULL,
              sale_price_minor INTEGER NOT NULL,
              hsn_sac TEXT NULL,
              tax_rate_basis_points INTEGER NOT NULL DEFAULT 0,
              attributes_json TEXT NOT NULL DEFAULT '[]',
              is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
              track_stock INTEGER NOT NULL DEFAULT 0 CHECK (track_stock IN (0, 1)),
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO product_services
              (name, type, unit, sale_price_minor, tax_rate_basis_points,
               is_deleted, track_stock, created_at, updated_at)
            VALUES ('Sheet', 'product', 'pcs', 10000, 0, 0, 1, 0, 0)
          ''');
          raw.execute('PRAGMA user_version = 21');
        },
      ),
    );
    final columns = await database
        .customSelect('PRAGMA table_info(product_services)')
        .get();
    expect(
      columns.any((row) => row.read<String>('name') == 'image_paths_json'),
      isTrue,
    );
    final product = await (database.select(
      database.productServices,
    )..where((table) => table.name.equals('Sheet'))).getSingle();
    expect(product.imagePathsJson, '[]');
    expect(database.schemaVersion, 22);
    await database.close();
  });
}

void _createV5Fixture(dynamic raw) {
  raw.execute('''
    CREATE TABLE invoices (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT NOT NULL,
      customer_id INTEGER NULL,
      customer_name TEXT NOT NULL,
      customer_company TEXT NULL,
      customer_mobile TEXT NULL,
      customer_email TEXT NULL,
      customer_address TEXT NULL,
      customer_city TEXT NULL,
      customer_state TEXT NULL,
      customer_pin_code TEXT NULL,
      customer_gstin TEXT NULL,
      invoice_date INTEGER NOT NULL,
      due_date INTEGER NULL,
      status TEXT NOT NULL,
      tax_type TEXT NOT NULL,
      discount_type TEXT NOT NULL,
      discount_value INTEGER NOT NULL DEFAULT 0,
      subtotal_minor INTEGER NOT NULL,
      item_discount_minor INTEGER NOT NULL,
      invoice_discount_minor INTEGER NOT NULL,
      taxable_minor INTEGER NOT NULL,
      tax_minor INTEGER NOT NULL,
      cgst_minor INTEGER NOT NULL,
      sgst_minor INTEGER NOT NULL,
      igst_minor INTEGER NOT NULL,
      charges_minor INTEGER NOT NULL,
      round_off_minor INTEGER NOT NULL,
      grand_total_minor INTEGER NOT NULL,
      paid_amount_minor INTEGER NOT NULL,
      balance_minor INTEGER NOT NULL,
      notes TEXT NULL,
      terms TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  for (final values in <List<Object>>[
    ['INV-V5-1', 'Unpaid Client', 'unpaid', 0, 10000],
    ['INV-V5-2', 'Partial Client', 'partiallyPaid', 4000, 6000],
    ['INV-V5-3', 'Paid Client', 'paid', 10000, 0],
  ]) {
    raw.execute('''
      INSERT INTO invoices (
        invoice_number, customer_name, invoice_date, status, tax_type,
        discount_type, subtotal_minor, item_discount_minor,
        invoice_discount_minor, taxable_minor, tax_minor, cgst_minor,
        sgst_minor, igst_minor, charges_minor, round_off_minor,
        grand_total_minor, paid_amount_minor, balance_minor, created_at,
        updated_at
      ) VALUES (
        ?, ?, 0, ?, 'none', 'none', 10000, 0, 0, 10000, 0, 0, 0, 0,
        0, 0, 10000, ?, ?, 0, 0
      )
    ''', values);
  }
  raw.execute('''
    CREATE TABLE invoice_items (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      product_id INTEGER NULL,
      name TEXT NOT NULL,
      description TEXT NULL,
      quantity_scaled INTEGER NOT NULL,
      unit TEXT NOT NULL,
      rate_minor INTEGER NOT NULL,
      hsn_sac TEXT NULL,
      tax_rate_basis_points INTEGER NOT NULL,
      discount_type TEXT NOT NULL,
      discount_value INTEGER NOT NULL DEFAULT 0,
      base_amount_minor INTEGER NOT NULL,
      discount_amount_minor INTEGER NOT NULL,
      taxable_amount_minor INTEGER NOT NULL,
      tax_amount_minor INTEGER NOT NULL,
      total_minor INTEGER NOT NULL,
      sort_order INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    INSERT INTO invoice_items (
      invoice_id, name, quantity_scaled, unit, rate_minor,
      tax_rate_basis_points, discount_type, base_amount_minor,
      discount_amount_minor, taxable_amount_minor, tax_amount_minor,
      total_minor, sort_order
    ) VALUES (1, 'Legacy service', 1000, 'service', 10000, 0, 'none',
              10000, 0, 10000, 0, 10000, 0)
  ''');
  raw.execute('''
    CREATE TABLE invoice_charges (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      amount_minor INTEGER NOT NULL,
      sort_order INTEGER NOT NULL
    )
  ''');
  raw.execute(
    "INSERT INTO invoice_charges (invoice_id, title, amount_minor, sort_order) VALUES (1, 'Delivery', 500, 0)",
  );
  raw.execute('PRAGMA user_version = 5');
}

void _createV20StockFixture(dynamic raw, {required bool enabled}) {
  raw.execute('''
    CREATE TABLE product_services (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      description TEXT NULL,
      unit TEXT NOT NULL,
      sale_price_minor INTEGER NOT NULL,
      hsn_sac TEXT NULL,
      tax_rate_basis_points INTEGER NOT NULL DEFAULT 0,
      attributes_json TEXT NOT NULL DEFAULT '[]',
      is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    INSERT INTO product_services
      (name, type, unit, sale_price_minor, tax_rate_basis_points, is_deleted, created_at, updated_at)
    VALUES
      ('Sheet', 'product', 'pcs', 10000, 0, 0, 0, 0),
      ('Install', 'service', 'service', 20000, 0, 0, 0, 0)
  ''');
  raw.execute('''
    CREATE TABLE stock_settings (
      id INTEGER NOT NULL PRIMARY KEY,
      enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1)),
      enabled_at INTEGER NULL,
      opening_as_of INTEGER NULL
    )
  ''');
  raw.execute('INSERT INTO stock_settings (id, enabled) VALUES (1, ?)', [
    enabled ? 1 : 0,
  ]);
  raw.execute('''
    CREATE TABLE stock_movements (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      quantity_scaled INTEGER NOT NULL,
      type TEXT NOT NULL,
      reason TEXT NULL,
      source_type TEXT NOT NULL,
      source_id INTEGER NULL,
      reverses_movement_id INTEGER NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  raw.execute('PRAGMA user_version = 20');
}
