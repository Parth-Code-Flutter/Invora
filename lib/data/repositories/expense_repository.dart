import 'package:drift/drift.dart';

import '../models/cash_book_models.dart';
import '../models/expense_model.dart';
import '../services/app_database.dart';
import '../services/money_ledger.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  const ExpenseRepository(super.database);

  Future<String> nextNumber() async {
    const prefix = 'EXP';
    final rows = await (database.select(
      database.expenses,
    )..where((table) => table.expenseNumber.like('$prefix-%'))).get();
    var next = 1;
    for (final row in rows) {
      final value = int.tryParse(row.expenseNumber.split('-').last);
      if (value != null && value >= next) next = value + 1;
    }
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  Stream<List<ExpenseSummaryModel>> watchAll() {
    final statement = database.select(database.expenses)
      ..orderBy([(table) => OrderingTerm.desc(table.expenseDate)]);
    return statement.watch().map(
      (rows) => rows.map(_toSummary).toList(growable: false),
    );
  }

  Future<ExpenseModel?> getById(int id) async {
    final row = await (database.select(
      database.expenses,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<ExpenseModel> save(ExpenseModel model) async {
    final payee = model.payee.trim();
    final category = model.category.trim();
    if (payee.isEmpty) {
      throw ArgumentError('Enter who was paid.');
    }
    if (category.isEmpty) {
      throw ArgumentError('Choose a category.');
    }
    if (model.grandTotalMinor <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    if (model.id != null) {
      final existing = await getById(model.id!);
      if (existing == null) {
        throw ArgumentError('This expense could not be found.');
      }
      if (existing.isCancelled) {
        throw ArgumentError('Cancelled expenses cannot be edited.');
      }
    }
    final split = ExpenseMath.split(
      paidMinor: model.grandTotalMinor,
      taxRateBasisPoints: model.taxRateBasisPoints,
    );
    final now = DateTime.now();
    final number = model.expenseNumber.trim().isEmpty
        ? await nextNumber()
        : model.expenseNumber.trim();
    final companion = ExpensesCompanion(
      expenseNumber: Value(number),
      expenseDate: Value(
        DateTime(
          model.expenseDate.year,
          model.expenseDate.month,
          model.expenseDate.day,
        ),
      ),
      category: Value(category),
      payee: Value(payee),
      amountMinor: Value(split.grandTotalMinor),
      taxRateBasisPoints: Value(model.taxRateBasisPoints),
      taxMinor: Value(split.taxMinor),
      taxableMinor: Value(split.taxableMinor),
      grandTotalMinor: Value(split.grandTotalMinor),
      itcEligible: Value(split.taxMinor > 0 ? model.itcEligible : false),
      paymentMethod: Value(
        model.paymentMethod.trim().isEmpty
            ? 'Cash'
            : model.paymentMethod.trim(),
      ),
      notes: Value(
        model.notes?.trim().isEmpty == true ? null : model.notes?.trim(),
      ),
      status: Value(ExpenseStatus.recorded.name),
      createdAt: Value(model.id == null ? now : model.createdAt),
      updatedAt: Value(now),
    );
    if (model.id == null) {
      final id = await database.into(database.expenses).insert(companion);
      await MoneyLedger(database).postLinked(
        sourceType: MoneySourceType.expense,
        sourceId: id,
        amountMinor: split.grandTotalMinor,
        occurredAt: companion.expenseDate.value,
        direction: MoneyDirection.outbound,
        entryType: MoneyEntryType.expense,
        method: companion.paymentMethod.value,
        note: '$category · $payee',
      );
      return (await getById(id))!;
    }
    await (database.update(
      database.expenses,
    )..where((table) => table.id.equals(model.id!))).write(companion);
    await MoneyLedger(database).replaceLinked(
      sourceType: MoneySourceType.expense,
      sourceId: model.id!,
      amountMinor: split.grandTotalMinor,
      occurredAt: companion.expenseDate.value,
      direction: MoneyDirection.outbound,
      entryType: MoneyEntryType.expense,
      method: companion.paymentMethod.value,
      note: '$category · $payee',
    );
    return (await getById(model.id!))!;
  }

  Future<ExpenseModel> cancel({required int id, required String reason}) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter a reason to cancel this expense.');
    }
    final existing = await getById(id);
    if (existing == null) {
      throw ArgumentError('This expense could not be found.');
    }
    if (existing.isCancelled) {
      throw ArgumentError('This expense is already cancelled.');
    }
    final now = DateTime.now();
    await (database.update(
      database.expenses,
    )..where((table) => table.id.equals(id))).write(
      ExpensesCompanion(
        status: Value(ExpenseStatus.cancelled.name),
        cancellationReason: Value(trimmed),
        cancelledAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await MoneyLedger(database).reverseActive(
      sourceType: MoneySourceType.expense,
      sourceId: id,
      occurredAt: now,
      note: trimmed,
    );
    return (await getById(id))!;
  }

  ExpenseSummaryModel _toSummary(Expense row) => ExpenseSummaryModel(
    id: row.id,
    expenseNumber: row.expenseNumber,
    expenseDate: row.expenseDate,
    category: row.category,
    payee: row.payee,
    grandTotalMinor: row.grandTotalMinor,
    status: ExpenseMath.statusFrom(row.status),
  );

  ExpenseModel _toModel(Expense row) => ExpenseModel(
    id: row.id,
    expenseNumber: row.expenseNumber,
    expenseDate: row.expenseDate,
    category: row.category,
    payee: row.payee,
    amountMinor: row.amountMinor,
    taxRateBasisPoints: row.taxRateBasisPoints,
    taxMinor: row.taxMinor,
    taxableMinor: row.taxableMinor,
    grandTotalMinor: row.grandTotalMinor,
    itcEligible: row.itcEligible,
    paymentMethod: row.paymentMethod,
    notes: row.notes,
    status: ExpenseMath.statusFrom(row.status),
    cancellationReason: row.cancellationReason,
    cancelledAt: row.cancelledAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
