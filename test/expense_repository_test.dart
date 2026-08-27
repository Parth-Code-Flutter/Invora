import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/expense_model.dart';
import 'package:creovo_invoice/data/repositories/expense_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('splits GST-inclusive payments into taxable and tax', () {
    final split = ExpenseMath.split(paidMinor: 11800, taxRateBasisPoints: 1800);
    expect(split.grandTotalMinor, 11800);
    expect(split.taxableMinor, 10000);
    expect(split.taxMinor, 1800);
  });

  test('keeps a zero-GST payment as taxable only', () {
    final split = ExpenseMath.split(paidMinor: 50000, taxRateBasisPoints: 0);
    expect(split.taxableMinor, 50000);
    expect(split.taxMinor, 0);
    expect(split.grandTotalMinor, 50000);
  });

  group('ExpenseRepository', () {
    late AppDatabase database;
    late ExpenseRepository expenses;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      expenses = ExpenseRepository(database);
    });

    tearDown(() => database.close());

    test('numbers, records, and excludes cancelled totals', () async {
      final first = await expenses.save(
        ExpenseModel(
          expenseNumber: '',
          expenseDate: DateTime(2026, 8, 11),
          category: 'Rent',
          payee: 'Shop landlord',
          amountMinor: 11800,
          taxRateBasisPoints: 1800,
          grandTotalMinor: 11800,
          itcEligible: true,
          paymentMethod: 'UPI',
          createdAt: DateTime(2026, 8, 11),
          updatedAt: DateTime(2026, 8, 11),
        ),
      );
      expect(first.expenseNumber, 'EXP-0001');
      expect(first.taxableMinor, 10000);
      expect(first.taxMinor, 1800);
      expect(first.itcEligible, isTrue);

      final second = await expenses.save(
        ExpenseModel(
          expenseNumber: '',
          expenseDate: DateTime(2026, 8, 12),
          category: 'Fuel',
          payee: 'HP pump',
          amountMinor: 200000,
          grandTotalMinor: 200000,
          paymentMethod: 'Cash',
          createdAt: DateTime(2026, 8, 12),
          updatedAt: DateTime(2026, 8, 12),
        ),
      );
      expect(second.expenseNumber, 'EXP-0002');

      await expenses.cancel(id: first.id!, reason: 'Entered twice');
      final cancelled = await expenses.getById(first.id!);
      expect(cancelled?.isCancelled, isTrue);
      expect(cancelled?.cancellationReason, 'Entered twice');

      await expectLater(
        expenses.save(cancelled!),
        throwsA(isA<ArgumentError>()),
      );

      final rows = await expenses.watchAll().first;
      expect(rows.length, 2);
      expect(rows.first.expenseNumber, 'EXP-0002');
    });

    test('requires payee, category, amount, and a cancel reason', () async {
      final now = DateTime(2026, 8, 27);
      await expectLater(
        expenses.save(
          ExpenseModel(
            expenseNumber: '',
            expenseDate: now,
            category: 'Rent',
            payee: '  ',
            amountMinor: 100,
            grandTotalMinor: 100,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        expenses.save(
          ExpenseModel(
            expenseNumber: '',
            expenseDate: now,
            category: 'Rent',
            payee: 'Landlord',
            amountMinor: 0,
            grandTotalMinor: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final saved = await expenses.save(
        ExpenseModel(
          expenseNumber: '',
          expenseDate: now,
          category: 'Office',
          payee: 'Stationery',
          amountMinor: 2500,
          grandTotalMinor: 2500,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await expectLater(
        expenses.cancel(id: saved.id!, reason: ' '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
