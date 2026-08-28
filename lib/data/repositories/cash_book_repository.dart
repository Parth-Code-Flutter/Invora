import 'dart:async';

import 'package:drift/drift.dart';

import '../../app/enums/invoice_status.dart';
import '../models/cash_book_models.dart';
import '../services/app_database.dart';
import '../services/money_ledger.dart';
import 'base_repository.dart';
import 'invoice_repository.dart';
import 'purchase_repository.dart';

class CashBookRepository extends BaseRepository {
  CashBookRepository(super.database)
    : ledger = MoneyLedger(database),
      _invoices = InvoiceRepository(database),
      _purchases = PurchaseRepository(database);

  final MoneyLedger ledger;
  final InvoiceRepository _invoices;
  final PurchaseRepository _purchases;

  Stream<CashBookSnapshot> watchSnapshot() {
    late StreamController<CashBookSnapshot> controller;
    Future<void> emit() async {
      final value = await _snapshot();
      if (!controller.isClosed) controller.add(value);
    }

    controller = StreamController<CashBookSnapshot>(
      onListen: emit,
      onCancel: () {},
    );
    final subs = [
      database.select(database.moneyAccounts).watch().listen((_) => emit()),
      database.select(database.moneyMovements).watch().listen((_) => emit()),
      database.select(database.partyAdvances).watch().listen((_) => emit()),
    ];
    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };
    return controller.stream;
  }

  Future<CashBookSnapshot> _snapshot() async {
    final accounts = await listAccounts(includeArchived: true);
    final advances = await listOpenAdvances();
    CashClosingModel? todayClosing;
    final cash = accounts.where((account) => account.isCash).firstOrNull;
    if (cash?.id != null) {
      todayClosing = await closingFor(cash!.id!, DateTime.now());
    }
    return CashBookSnapshot(
      accounts: accounts,
      advances: advances,
      todayCashClosing: todayClosing,
    );
  }

  Future<List<MoneyAccountModel>> listAccounts({
    bool includeArchived = false,
  }) async {
    final rows =
        await (database.select(database.moneyAccounts)..orderBy([
              (table) => OrderingTerm.asc(table.sortOrder),
              (table) => OrderingTerm.asc(table.id),
            ]))
            .get();
    final movements = await database.select(database.moneyMovements).get();
    final reversed = movements
        .where((row) => row.reversesMovementId != null)
        .map((row) => row.reversesMovementId!)
        .toSet();
    final models = <MoneyAccountModel>[];
    for (final row in rows) {
      if (!includeArchived && row.isArchived) continue;
      var book = 0;
      var pending = 0;
      for (final movement in movements) {
        if (movement.accountId != row.id) continue;
        final signed = movement.direction == 'in'
            ? movement.amountMinor
            : -movement.amountMinor;
        book += signed;
        if (movement.chequeStatus == ChequeStatus.pending.name &&
            !reversed.contains(movement.id)) {
          pending += signed;
        }
      }
      models.add(_account(row, bookMinor: book, pendingMinor: pending));
    }
    return models;
  }

  Future<List<MoneyAccountModel>> activeAccounts() =>
      listAccounts(includeArchived: false);

  Future<MoneyAccountModel> saveAccount({
    int? id,
    required String name,
    required MoneyAccountType type,
    int openingMinor = 0,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter an account name.');
    }
    final now = DateTime.now();
    if (id == null) {
      final created = await database
          .into(database.moneyAccounts)
          .insertReturning(
            MoneyAccountsCompanion.insert(
              name: trimmed,
              accountType: type.storage,
              sortOrder: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      if (openingMinor > 0) {
        await ledger.post(
          accountId: created.id,
          direction: MoneyDirection.inbound,
          amountMinor: openingMinor,
          occurredAt: now,
          entryType: MoneyEntryType.opening,
          sourceType: MoneySourceType.opening,
          sourceId: created.id,
          note: 'Opening balance',
        );
      }
      return (await listAccounts(
        includeArchived: true,
      )).firstWhere((account) => account.id == created.id);
    }
    final existing = await (database.select(
      database.moneyAccounts,
    )..where((table) => table.id.equals(id))).getSingle();
    await (database.update(
      database.moneyAccounts,
    )..where((table) => table.id.equals(id))).write(
      MoneyAccountsCompanion(
        name: Value(trimmed),
        accountType: existing.isSystem
            ? const Value.absent()
            : Value(type.storage),
        updatedAt: Value(now),
      ),
    );
    return (await listAccounts(
      includeArchived: true,
    )).firstWhere((account) => account.id == id);
  }

  Future<void> archiveAccount(int id, {required bool archived}) async {
    final row = await (database.select(
      database.moneyAccounts,
    )..where((table) => table.id.equals(id))).getSingle();
    if (row.isSystem && archived) {
      final sameType =
          await (database.select(database.moneyAccounts)..where(
                (table) =>
                    table.accountType.equals(row.accountType) &
                    table.isArchived.equals(false) &
                    table.id.equals(id).not(),
              ))
              .get();
      if (sameType.isEmpty) {
        throw StateError(
          'Keep at least one ${MoneyAccountTypeX.fromStorage(row.accountType).label} account.',
        );
      }
    }
    await (database.update(
      database.moneyAccounts,
    )..where((table) => table.id.equals(id))).write(
      MoneyAccountsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<MoneyMovementModel>> watchStatement(
    int accountId, {
    DateTime? from,
    DateTime? to,
  }) {
    return (database.select(database.moneyMovements)
          ..where((table) => table.accountId.equals(accountId)))
        .watch()
        .asyncMap((_) {
          return statement(accountId, from: from, to: to);
        });
  }

  Future<List<MoneyMovementModel>> statement(
    int accountId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final account = await (database.select(
      database.moneyAccounts,
    )..where((table) => table.id.equals(accountId))).getSingle();
    final rows =
        await (database.select(database.moneyMovements)
              ..where((table) => table.accountId.equals(accountId))
              ..orderBy([
                (table) => OrderingTerm.asc(table.occurredAt),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();
    var running = 0;
    final start = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final end = to == null
        ? null
        : DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final result = <MoneyMovementModel>[];
    for (final row in rows) {
      running += row.direction == 'in' ? row.amountMinor : -row.amountMinor;
      if (start != null && row.occurredAt.isBefore(start)) continue;
      if (end != null && row.occurredAt.isAfter(end)) continue;
      result.add(_movement(row, account.name, running));
    }
    return result.reversed.toList(growable: false);
  }

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required DateTime occurredAt,
    String? note,
  }) async {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Choose two different accounts.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero.');
    }
    final accounts = await listAccounts();
    final from = accounts.firstWhere((account) => account.id == fromAccountId);
    if (from.availableMinor < amountMinor) {
      throw ArgumentError('Not enough available balance to transfer.');
    }
    await database.transaction(() async {
      final outId = await ledger.post(
        accountId: fromAccountId,
        direction: MoneyDirection.outbound,
        amountMinor: amountMinor,
        occurredAt: occurredAt,
        entryType: MoneyEntryType.transfer,
        sourceType: MoneySourceType.transfer,
        note: note,
      );
      final inId = await ledger.post(
        accountId: toAccountId,
        direction: MoneyDirection.inbound,
        amountMinor: amountMinor,
        occurredAt: occurredAt,
        entryType: MoneyEntryType.transfer,
        sourceType: MoneySourceType.transfer,
        sourceId: outId,
        pairedMovementId: outId,
        note: note,
      );
      await (database.update(
        database.moneyMovements,
      )..where((table) => table.id.equals(outId))).write(
        MoneyMovementsCompanion(
          sourceId: Value(inId),
          pairedMovementId: Value(inId),
        ),
      );
    });
  }

  Future<void> clearCheque(int movementId) async {
    final row = await (database.select(
      database.moneyMovements,
    )..where((table) => table.id.equals(movementId))).getSingle();
    if (row.chequeStatus != ChequeStatus.pending.name) {
      throw StateError('Only a pending cheque can be cleared.');
    }
    await (database.update(database.moneyMovements)
          ..where((table) => table.id.equals(movementId)))
        .write(const MoneyMovementsCompanion(chequeStatus: Value('cleared')));
  }

  Future<void> bounceCheque(int movementId, {required String reason}) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter a reason for the bounce.');
    }
    await database.transaction(() async {
      final row = await (database.select(
        database.moneyMovements,
      )..where((table) => table.id.equals(movementId))).getSingle();
      if (row.chequeStatus != ChequeStatus.pending.name) {
        throw StateError('Only a pending cheque can be bounced.');
      }
      final sourceType = MoneySourceTypeX.fromStorage(row.sourceType);
      final sourceId = row.sourceId;
      if (sourceType == MoneySourceType.invoicePayment && sourceId != null) {
        final payment = await (database.select(
          database.invoicePayments,
        )..where((table) => table.id.equals(sourceId))).getSingle();
        await _invoices.reversePayment(
          invoiceId: payment.invoiceId,
          paymentId: payment.id,
          reason: trimmed,
          reversedAt: DateTime.now(),
        );
      } else if (sourceType == MoneySourceType.purchasePayment &&
          sourceId != null) {
        await _purchases.reversePayment(sourceId, reason: trimmed);
      } else if (sourceType == MoneySourceType.partyAdvance &&
          sourceId != null) {
        await refundAdvance(sourceId, reason: trimmed);
      } else {
        await ledger.reverseActive(
          sourceType: sourceType,
          sourceId: sourceId ?? row.id,
          occurredAt: DateTime.now(),
          note: trimmed,
        );
      }
      await (database.update(database.moneyMovements)
            ..where((table) => table.id.equals(movementId)))
          .write(const MoneyMovementsCompanion(chequeStatus: Value('bounced')));
    });
  }

  Future<CashClosingModel> closeCash({
    required int accountId,
    required DateTime date,
    required int countedMinor,
    String? note,
  }) async {
    if (countedMinor < 0) {
      throw ArgumentError('Counted cash cannot be negative.');
    }
    final account = (await listAccounts(
      includeArchived: true,
    )).firstWhere((item) => item.id == accountId);
    if (!account.isCash) {
      throw StateError('Daily closing is only for a cash account.');
    }
    final day = DateTime(date.year, date.month, date.day);
    final existing = await closingFor(accountId, day);
    if (existing != null) {
      throw StateError('Cash is already closed for this date.');
    }
    final book = account.availableMinor;
    final difference = countedMinor - book;
    return database.transaction(() async {
      int? movementId;
      if (difference != 0) {
        movementId = await ledger.post(
          accountId: accountId,
          direction: difference > 0
              ? MoneyDirection.inbound
              : MoneyDirection.outbound,
          amountMinor: difference.abs(),
          occurredAt: day,
          entryType: MoneyEntryType.closingAdjust,
          sourceType: MoneySourceType.cashClosing,
          note: note ?? 'Cash closing difference',
        );
      }
      final row = await database
          .into(database.cashClosings)
          .insertReturning(
            CashClosingsCompanion.insert(
              accountId: accountId,
              closingDate: day,
              countedMinor: countedMinor,
              bookMinor: book,
              differenceMinor: difference,
              movementId: Value(movementId),
              note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
            ),
          );
      if (movementId != null) {
        final postedId = movementId;
        await (database.update(database.moneyMovements)
              ..where((table) => table.id.equals(postedId)))
            .write(MoneyMovementsCompanion(sourceId: Value(row.id)));
      }
      return _closing(row);
    });
  }

  Future<CashClosingModel?> closingFor(int accountId, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));
    final row =
        await (database.select(database.cashClosings)..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.closingDate.isBiggerOrEqualValue(day) &
                  table.closingDate.isSmallerThanValue(next),
            ))
            .getSingleOrNull();
    return row == null ? null : _closing(row);
  }

  Future<PartyAdvanceModel> recordAdvance({
    required PartyKind partyType,
    required int partyId,
    required String partyName,
    required int accountId,
    required int amountMinor,
    required DateTime occurredAt,
    String? note,
    String? method,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Advance amount must be greater than zero.');
    }
    final direction = partyType == PartyKind.customer
        ? MoneyDirection.inbound
        : MoneyDirection.outbound;
    return database.transaction(() async {
      final row = await database
          .into(database.partyAdvances)
          .insertReturning(
            PartyAdvancesCompanion.insert(
              partyType: partyType.name,
              partyId: partyId,
              partyName: partyName.trim(),
              accountId: accountId,
              amountMinor: amountMinor,
              remainingMinor: amountMinor,
              direction: direction.storage,
              occurredAt: occurredAt,
              note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
            ),
          );
      await ledger.post(
        accountId: accountId,
        direction: direction,
        amountMinor: amountMinor,
        occurredAt: occurredAt,
        entryType: MoneyEntryType.advance,
        sourceType: MoneySourceType.partyAdvance,
        sourceId: row.id,
        chequeStatus: MoneyAccountTypeX.isCheque(method)
            ? ChequeStatus.pending
            : null,
        note: note,
      );
      return (await getAdvance(row.id))!;
    });
  }

  Future<PartyAdvanceModel?> getAdvance(int id) async {
    final row = await (database.select(
      database.partyAdvances,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _advanceWithAllocations(row);
  }

  Future<List<PartyAdvanceModel>> listAdvancesForParty({
    required PartyKind partyType,
    required int partyId,
  }) async {
    final query = database.select(database.partyAdvances)
      ..where(
        (table) =>
            table.partyType.equals(partyType.name) &
            table.partyId.equals(partyId),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.occurredAt)]);
    final rows = await query.get();
    final result = <PartyAdvanceModel>[];
    for (final row in rows) {
      result.add(await _advanceWithAllocations(row));
    }
    return result;
  }

  Future<List<PartyAdvanceModel>> listOpenAdvances({
    PartyKind? partyType,
    int? partyId,
  }) async {
    final query = database.select(database.partyAdvances)
      ..where((table) => table.remainingMinor.isBiggerThanValue(0));
    if (partyType != null) {
      query.where((table) => table.partyType.equals(partyType.name));
    }
    if (partyId != null) {
      query.where((table) => table.partyId.equals(partyId));
    }
    query.orderBy([(table) => OrderingTerm.desc(table.occurredAt)]);
    final rows = await query.get();
    final result = <PartyAdvanceModel>[];
    for (final row in rows) {
      result.add(await _advanceWithAllocations(row));
    }
    return result;
  }

  Future<List<AllocatableDocument>> allocatableDocuments(
    PartyAdvanceModel advance,
  ) async {
    if (advance.partyType == PartyKind.customer) {
      final invoices = await _invoices
          .watchCustomerInvoices(advance.partyId)
          .first;
      return invoices
          .where(
            (invoice) =>
                invoice.balanceMinor > 0 &&
                invoice.status != InvoiceStatus.draft &&
                invoice.status != InvoiceStatus.cancelled,
          )
          .map(
            (invoice) => AllocatableDocument(
              id: invoice.id,
              number: invoice.invoiceNumber,
              partyName: invoice.customerName,
              date: invoice.invoiceDate,
              balanceMinor: invoice.balanceMinor,
            ),
          )
          .toList(growable: false);
    }
    final bills = await _purchases.watchBills().first;
    return bills
        .where(
          (bill) =>
              bill.supplierId == advance.partyId &&
              bill.balanceMinor > 0 &&
              bill.status != 'cancelled' &&
              bill.status != 'draft',
        )
        .map(
          (bill) => AllocatableDocument(
            id: bill.id,
            number: bill.billNumber,
            partyName: bill.supplierName,
            date: bill.billDate,
            balanceMinor: bill.balanceMinor,
          ),
        )
        .toList(growable: false);
  }

  Future<PartyAdvanceModel> allocateAdvance({
    required int advanceId,
    required int documentId,
    required int amountMinor,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Allocation must be greater than zero.');
    }
    return database.transaction(() async {
      final advance = await getAdvance(advanceId);
      if (advance == null || !advance.canAllocate) {
        throw StateError('This advance has no remaining amount.');
      }
      if (amountMinor > advance.remainingMinor) {
        throw ArgumentError('Allocation cannot exceed the remaining advance.');
      }
      final documents = await allocatableDocuments(advance);
      final document = documents
          .where((item) => item.id == documentId)
          .firstOrNull;
      if (document == null) {
        throw StateError('Choose an open document for this party.');
      }
      if (amountMinor > document.balanceMinor) {
        throw ArgumentError('Allocation cannot exceed the document balance.');
      }
      if (advance.partyType == PartyKind.customer) {
        await _invoices.recordPayment(
          invoiceId: documentId,
          amountMinor: amountMinor,
          paidAt: DateTime.now(),
          method: 'Advance',
          note: 'Applied from advance',
          entryType: 'advance',
          postToCashBook: false,
        );
      } else {
        await _purchases.recordPayment(
          documentId,
          amountMinor,
          method: 'Advance',
          note: 'Applied from advance',
          entryType: 'advance',
          postToCashBook: false,
        );
      }
      await database
          .into(database.partyAdvanceAllocations)
          .insert(
            PartyAdvanceAllocationsCompanion.insert(
              advanceId: advanceId,
              documentType: advance.partyType == PartyKind.customer
                  ? 'invoice'
                  : 'purchase_bill',
              documentId: documentId,
              documentNumber: document.number,
              amountMinor: amountMinor,
              appliedAt: DateTime.now(),
            ),
          );
      final remaining = advance.remainingMinor - amountMinor;
      await (database.update(
        database.partyAdvances,
      )..where((table) => table.id.equals(advanceId))).write(
        PartyAdvancesCompanion(
          remainingMinor: Value(remaining),
          status: Value(
            remaining == 0
                ? AdvanceStatus.allocated.name
                : AdvanceStatus.open.name,
          ),
        ),
      );
      return (await getAdvance(advanceId))!;
    });
  }

  Future<PartyAdvanceModel> refundAdvance(
    int advanceId, {
    required String reason,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter a reason to refund this advance.');
    }
    return database.transaction(() async {
      final advance = await getAdvance(advanceId);
      if (advance == null || !advance.canRefund) {
        throw StateError('This advance cannot be refunded.');
      }
      await ledger.reverseActive(
        sourceType: MoneySourceType.partyAdvance,
        sourceId: advanceId,
        occurredAt: DateTime.now(),
        note: trimmed,
      );
      if (advance.remainingMinor < advance.amountMinor) {
        // Partial leftover refund: reverseActive reversed the original full
        // cash movement. Re-post the already allocated portion so the book
        // still holds money that was applied to documents.
        final allocated = advance.amountMinor - advance.remainingMinor;
        if (allocated > 0) {
          await ledger.post(
            accountId: advance.accountId,
            direction: advance.direction,
            amountMinor: allocated,
            occurredAt: DateTime.now(),
            entryType: MoneyEntryType.advance,
            sourceType: MoneySourceType.partyAdvance,
            sourceId: advanceId,
            note: 'Allocated portion kept after refund',
          );
        }
      }
      await (database.update(
        database.partyAdvances,
      )..where((table) => table.id.equals(advanceId))).write(
        PartyAdvancesCompanion(
          remainingMinor: const Value(0),
          status: Value(AdvanceStatus.refunded.name),
          note: Value(
            [advance.note, 'Refunded: $trimmed']
                .where((value) => value != null && value.trim().isNotEmpty)
                .join(' · '),
          ),
        ),
      );
      return (await getAdvance(advanceId))!;
    });
  }

  MoneyAccountModel _account(
    MoneyAccount row, {
    required int bookMinor,
    required int pendingMinor,
  }) {
    return MoneyAccountModel(
      id: row.id,
      name: row.name,
      accountType: MoneyAccountTypeX.fromStorage(row.accountType),
      isSystem: row.isSystem,
      isArchived: row.isArchived,
      sortOrder: row.sortOrder,
      bookMinor: bookMinor,
      pendingMinor: pendingMinor,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  MoneyMovementModel _movement(
    MoneyMovement row,
    String accountName,
    int running,
  ) {
    return MoneyMovementModel(
      id: row.id,
      accountId: row.accountId,
      accountName: accountName,
      direction: MoneyDirectionX.fromStorage(row.direction),
      amountMinor: row.amountMinor,
      occurredAt: row.occurredAt,
      entryType: MoneyEntryTypeX.fromStorage(row.entryType),
      sourceType: MoneySourceTypeX.fromStorage(row.sourceType),
      sourceId: row.sourceId,
      pairedMovementId: row.pairedMovementId,
      reversesMovementId: row.reversesMovementId,
      chequeStatus: row.chequeStatus == null
          ? null
          : ChequeStatus.values.firstWhere(
              (status) => status.name == row.chequeStatus,
              orElse: () => ChequeStatus.cleared,
            ),
      reference: row.reference,
      note: row.note,
      createdAt: row.createdAt,
      runningBalanceMinor: running,
    );
  }

  Future<PartyAdvanceModel> _advanceWithAllocations(PartyAdvance row) async {
    final account = await (database.select(
      database.moneyAccounts,
    )..where((table) => table.id.equals(row.accountId))).getSingle();
    final allocations =
        await (database.select(database.partyAdvanceAllocations)
              ..where((table) => table.advanceId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.desc(table.appliedAt)]))
            .get();
    return PartyAdvanceModel(
      id: row.id,
      partyType: row.partyType == 'supplier'
          ? PartyKind.supplier
          : PartyKind.customer,
      partyId: row.partyId,
      partyName: row.partyName,
      accountId: row.accountId,
      accountName: account.name,
      amountMinor: row.amountMinor,
      remainingMinor: row.remainingMinor,
      direction: MoneyDirectionX.fromStorage(row.direction),
      occurredAt: row.occurredAt,
      note: row.note,
      status: AdvanceStatus.values.firstWhere(
        (status) => status.name == row.status,
        orElse: () => AdvanceStatus.open,
      ),
      createdAt: row.createdAt,
      allocations: allocations
          .map(
            (item) => AdvanceAllocationModel(
              id: item.id,
              advanceId: item.advanceId,
              documentType: item.documentType,
              documentId: item.documentId,
              documentNumber: item.documentNumber,
              amountMinor: item.amountMinor,
              appliedAt: item.appliedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  CashClosingModel _closing(CashClosing row) => CashClosingModel(
    id: row.id,
    accountId: row.accountId,
    closingDate: row.closingDate,
    countedMinor: row.countedMinor,
    bookMinor: row.bookMinor,
    differenceMinor: row.differenceMinor,
    movementId: row.movementId,
    note: row.note,
    createdAt: row.createdAt,
  );
}
