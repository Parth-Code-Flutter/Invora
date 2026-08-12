import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
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
}
