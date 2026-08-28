import 'package:drift/drift.dart';

import '../models/cash_book_models.dart';
import 'app_database.dart';

/// Immutable money-account postings. Amounts are never updated in place.
class MoneyLedger {
  const MoneyLedger(this.database);

  final AppDatabase database;

  Future<int> resolveAccountId({String? method, int? accountId}) async {
    if (accountId != null) {
      final row = await (database.select(
        database.moneyAccounts,
      )..where((table) => table.id.equals(accountId))).getSingleOrNull();
      if (row == null || row.isArchived) {
        throw StateError('Choose an active cash-book account.');
      }
      return row.id;
    }
    final type = MoneyAccountTypeX.fromMethod(method).storage;
    final matches =
        await (database.select(database.moneyAccounts)..where(
              (table) =>
                  table.accountType.equals(type) &
                  table.isArchived.equals(false),
            ))
            .get();
    if (matches.isNotEmpty) return matches.first.id;
    final fallback = await (database.select(
      database.moneyAccounts,
    )..where((table) => table.isArchived.equals(false))).get();
    if (fallback.isEmpty) {
      throw StateError('Set up a cash-book account first.');
    }
    return fallback.first.id;
  }

  Future<List<MoneyMovement>> _bySource({
    required MoneySourceType sourceType,
    required int sourceId,
  }) {
    return (database.select(database.moneyMovements)..where(
          (table) =>
              table.sourceType.equals(sourceType.storage) &
              table.sourceId.equals(sourceId),
        ))
        .get();
  }

  Future<MoneyMovement?> findActiveBySource({
    required MoneySourceType sourceType,
    required int sourceId,
  }) async {
    final rows = await _bySource(sourceType: sourceType, sourceId: sourceId);
    if (rows.isEmpty) return null;
    final reversed = rows
        .where((row) => row.reversesMovementId != null)
        .map((row) => row.reversesMovementId!)
        .toSet();
    final active =
        rows
            .where(
              (row) =>
                  row.entryType != 'reversal' && !reversed.contains(row.id),
            )
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    return active.firstOrNull;
  }

  Future<int> post({
    required int accountId,
    required MoneyDirection direction,
    required int amountMinor,
    required DateTime occurredAt,
    required MoneyEntryType entryType,
    required MoneySourceType sourceType,
    int? sourceId,
    int? pairedMovementId,
    int? reversesMovementId,
    ChequeStatus? chequeStatus,
    String? reference,
    String? note,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Cash-book amount must be greater than zero.');
    }
    return database
        .into(database.moneyMovements)
        .insert(
          MoneyMovementsCompanion.insert(
            accountId: accountId,
            direction: direction.storage,
            amountMinor: amountMinor,
            occurredAt: occurredAt,
            entryType: entryType.storage,
            sourceType: sourceType.storage,
            sourceId: Value(sourceId),
            pairedMovementId: Value(pairedMovementId),
            reversesMovementId: Value(reversesMovementId),
            chequeStatus: Value(chequeStatus?.name),
            reference: Value(_optional(reference)),
            note: Value(_optional(note)),
          ),
        );
  }

  Future<void> postLinked({
    required MoneySourceType sourceType,
    required int sourceId,
    required int amountMinor,
    required DateTime occurredAt,
    required MoneyDirection direction,
    required MoneyEntryType entryType,
    String? method,
    int? accountId,
    String? reference,
    String? note,
  }) async {
    if (amountMinor <= 0) return;
    if (await findActiveBySource(sourceType: sourceType, sourceId: sourceId) !=
        null) {
      return;
    }
    final resolvedAccountId = await resolveAccountId(
      method: method,
      accountId: accountId,
    );
    await post(
      accountId: resolvedAccountId,
      direction: direction,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      entryType: entryType,
      sourceType: sourceType,
      sourceId: sourceId,
      chequeStatus: MoneyAccountTypeX.isCheque(method)
          ? ChequeStatus.pending
          : null,
      reference: reference,
      note: note,
    );
  }

  Future<void> reverseLinked({
    required MoneySourceType sourceType,
    required int originalSourceId,
    required int reversalSourceId,
    required DateTime occurredAt,
    String? note,
  }) async {
    final original = await findActiveBySource(
      sourceType: sourceType,
      sourceId: originalSourceId,
    );
    if (original == null) return;
    final already =
        await (database.select(database.moneyMovements)..where(
              (table) =>
                  table.sourceId.equals(reversalSourceId) &
                  table.sourceType.equals(sourceType.storage) &
                  table.entryType.equals('reversal'),
            ))
            .getSingleOrNull();
    if (already != null) return;
    final reverseDirection = original.direction == 'in'
        ? MoneyDirection.outbound
        : MoneyDirection.inbound;
    await post(
      accountId: original.accountId,
      direction: reverseDirection,
      amountMinor: original.amountMinor,
      occurredAt: occurredAt,
      entryType: MoneyEntryType.reversal,
      sourceType: sourceType,
      sourceId: reversalSourceId,
      reversesMovementId: original.id,
      note: note,
    );
  }

  Future<void> replaceLinked({
    required MoneySourceType sourceType,
    required int sourceId,
    required int amountMinor,
    required DateTime occurredAt,
    required MoneyDirection direction,
    required MoneyEntryType entryType,
    String? method,
    int? accountId,
    String? reference,
    String? note,
  }) async {
    await reverseActive(
      sourceType: sourceType,
      sourceId: sourceId,
      occurredAt: occurredAt,
      note: 'Updated entry',
    );
    await postLinked(
      sourceType: sourceType,
      sourceId: sourceId,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      direction: direction,
      entryType: entryType,
      method: method,
      accountId: accountId,
      reference: reference,
      note: note,
    );
  }

  Future<void> reverseActive({
    required MoneySourceType sourceType,
    required int sourceId,
    required DateTime occurredAt,
    String? note,
  }) async {
    final original = await findActiveBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (original == null) return;
    await post(
      accountId: original.accountId,
      direction: original.direction == 'in'
          ? MoneyDirection.outbound
          : MoneyDirection.inbound,
      amountMinor: original.amountMinor,
      occurredAt: occurredAt,
      entryType: MoneyEntryType.reversal,
      sourceType: sourceType,
      sourceId: sourceId,
      reversesMovementId: original.id,
      note: note,
    );
  }

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
