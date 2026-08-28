import 'package:flutter/material.dart';

enum MoneyAccountType { cash, bank, upi, card, other }

enum MoneyDirection { inbound, outbound }

enum MoneyEntryType {
  receipt,
  payment,
  expense,
  refund,
  transfer,
  advance,
  opening,
  closingAdjust,
  reversal,
}

enum MoneySourceType {
  invoicePayment,
  purchasePayment,
  expense,
  creditNote,
  debitNote,
  transfer,
  partyAdvance,
  cashClosing,
  opening,
}

enum ChequeStatus { pending, cleared, bounced }

enum PartyKind { customer, supplier }

enum AdvanceStatus { open, allocated, refunded }

extension MoneyAccountTypeX on MoneyAccountType {
  String get storage => name;

  String get label => switch (this) {
    MoneyAccountType.cash => 'Cash',
    MoneyAccountType.bank => 'Bank',
    MoneyAccountType.upi => 'UPI',
    MoneyAccountType.card => 'Card',
    MoneyAccountType.other => 'Other',
  };

  IconData get icon => switch (this) {
    MoneyAccountType.cash => Icons.payments_outlined,
    MoneyAccountType.bank => Icons.account_balance_outlined,
    MoneyAccountType.upi => Icons.qr_code_2_rounded,
    MoneyAccountType.card => Icons.credit_card_rounded,
    MoneyAccountType.other => Icons.more_horiz_rounded,
  };

  static MoneyAccountType fromStorage(String value) {
    return MoneyAccountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MoneyAccountType.other,
    );
  }

  static MoneyAccountType fromMethod(String? method) {
    final value = (method ?? '').trim().toLowerCase();
    if (value.contains('upi')) return MoneyAccountType.upi;
    if (value.contains('cash')) return MoneyAccountType.cash;
    if (value.contains('card')) return MoneyAccountType.card;
    if (value.contains('cheque') || value.contains('check')) {
      return MoneyAccountType.bank;
    }
    if (value.contains('bank')) return MoneyAccountType.bank;
    return MoneyAccountType.other;
  }

  static bool isCheque(String? method) {
    final value = (method ?? '').toLowerCase();
    return value.contains('cheque') || value.contains('check');
  }
}

extension MoneyDirectionX on MoneyDirection {
  String get storage => this == MoneyDirection.inbound ? 'in' : 'out';

  static MoneyDirection fromStorage(String value) =>
      value == 'out' ? MoneyDirection.outbound : MoneyDirection.inbound;
}

extension MoneyEntryTypeX on MoneyEntryType {
  String get storage => switch (this) {
    MoneyEntryType.closingAdjust => 'closing_adjust',
    _ => name,
  };

  String get label => switch (this) {
    MoneyEntryType.receipt => 'Receipt',
    MoneyEntryType.payment => 'Payment',
    MoneyEntryType.expense => 'Expense',
    MoneyEntryType.refund => 'Refund',
    MoneyEntryType.transfer => 'Transfer',
    MoneyEntryType.advance => 'Advance',
    MoneyEntryType.opening => 'Opening',
    MoneyEntryType.closingAdjust => 'Cash closing',
    MoneyEntryType.reversal => 'Reversal',
  };

  static MoneyEntryType fromStorage(String value) => switch (value) {
    'closing_adjust' => MoneyEntryType.closingAdjust,
    'receipt' => MoneyEntryType.receipt,
    'payment' => MoneyEntryType.payment,
    'expense' => MoneyEntryType.expense,
    'refund' => MoneyEntryType.refund,
    'transfer' => MoneyEntryType.transfer,
    'advance' => MoneyEntryType.advance,
    'opening' => MoneyEntryType.opening,
    'reversal' => MoneyEntryType.reversal,
    _ => MoneyEntryType.payment,
  };
}

extension MoneySourceTypeX on MoneySourceType {
  String get storage => switch (this) {
    MoneySourceType.invoicePayment => 'invoice_payment',
    MoneySourceType.purchasePayment => 'purchase_payment',
    MoneySourceType.creditNote => 'credit_note',
    MoneySourceType.debitNote => 'debit_note',
    MoneySourceType.partyAdvance => 'party_advance',
    MoneySourceType.cashClosing => 'cash_closing',
    _ => name,
  };

  static MoneySourceType fromStorage(String value) => switch (value) {
    'invoice_payment' => MoneySourceType.invoicePayment,
    'purchase_payment' => MoneySourceType.purchasePayment,
    'expense' => MoneySourceType.expense,
    'credit_note' => MoneySourceType.creditNote,
    'debit_note' => MoneySourceType.debitNote,
    'transfer' => MoneySourceType.transfer,
    'party_advance' => MoneySourceType.partyAdvance,
    'cash_closing' => MoneySourceType.cashClosing,
    'opening' => MoneySourceType.opening,
    _ => MoneySourceType.invoicePayment,
  };
}

class MoneyAccountModel {
  const MoneyAccountModel({
    this.id,
    required this.name,
    required this.accountType,
    this.isSystem = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.bookMinor = 0,
    this.pendingMinor = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final MoneyAccountType accountType;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;
  final int bookMinor;
  final int pendingMinor;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get availableMinor => bookMinor - pendingMinor;
  bool get isCash => accountType == MoneyAccountType.cash;

  MoneyAccountModel copyWith({
    int? bookMinor,
    int? pendingMinor,
    bool? isArchived,
    String? name,
  }) {
    return MoneyAccountModel(
      id: id,
      name: name ?? this.name,
      accountType: accountType,
      isSystem: isSystem,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder,
      bookMinor: bookMinor ?? this.bookMinor,
      pendingMinor: pendingMinor ?? this.pendingMinor,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MoneyMovementModel {
  const MoneyMovementModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.direction,
    required this.amountMinor,
    required this.occurredAt,
    required this.entryType,
    required this.sourceType,
    this.sourceId,
    this.pairedMovementId,
    this.reversesMovementId,
    this.chequeStatus,
    this.reference,
    this.note,
    required this.createdAt,
    this.runningBalanceMinor = 0,
  });

  final int id;
  final int accountId;
  final String accountName;
  final MoneyDirection direction;
  final int amountMinor;
  final DateTime occurredAt;
  final MoneyEntryType entryType;
  final MoneySourceType sourceType;
  final int? sourceId;
  final int? pairedMovementId;
  final int? reversesMovementId;
  final ChequeStatus? chequeStatus;
  final String? reference;
  final String? note;
  final DateTime createdAt;
  final int runningBalanceMinor;

  int get signedMinor =>
      direction == MoneyDirection.inbound ? amountMinor : -amountMinor;

  bool get isPendingCheque => chequeStatus == ChequeStatus.pending;
  bool get canClearCheque => chequeStatus == ChequeStatus.pending;
  bool get canBounceCheque =>
      chequeStatus == ChequeStatus.pending &&
      (sourceType == MoneySourceType.invoicePayment ||
          sourceType == MoneySourceType.purchasePayment ||
          sourceType == MoneySourceType.partyAdvance);

  String get title {
    if (chequeStatus == ChequeStatus.pending) {
      return 'Cheque pending';
    }
    if (chequeStatus == ChequeStatus.bounced) {
      return 'Cheque bounced';
    }
    return entryType.label;
  }
}

class PartyAdvanceModel {
  const PartyAdvanceModel({
    required this.id,
    required this.partyType,
    required this.partyId,
    required this.partyName,
    required this.accountId,
    required this.accountName,
    required this.amountMinor,
    required this.remainingMinor,
    required this.direction,
    required this.occurredAt,
    this.note,
    required this.status,
    required this.createdAt,
    this.allocations = const [],
  });

  final int id;
  final PartyKind partyType;
  final int partyId;
  final String partyName;
  final int accountId;
  final String accountName;
  final int amountMinor;
  final int remainingMinor;
  final MoneyDirection direction;
  final DateTime occurredAt;
  final String? note;
  final AdvanceStatus status;
  final DateTime createdAt;
  final List<AdvanceAllocationModel> allocations;

  bool get canAllocate => remainingMinor > 0 && status == AdvanceStatus.open;
  bool get canRefund => remainingMinor > 0 && status != AdvanceStatus.refunded;
}

class AdvanceAllocationModel {
  const AdvanceAllocationModel({
    required this.id,
    required this.advanceId,
    required this.documentType,
    required this.documentId,
    required this.documentNumber,
    required this.amountMinor,
    required this.appliedAt,
  });

  final int id;
  final int advanceId;
  final String documentType;
  final int documentId;
  final String documentNumber;
  final int amountMinor;
  final DateTime appliedAt;
}

class CashClosingModel {
  const CashClosingModel({
    required this.id,
    required this.accountId,
    required this.closingDate,
    required this.countedMinor,
    required this.bookMinor,
    required this.differenceMinor,
    this.movementId,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int accountId;
  final DateTime closingDate;
  final int countedMinor;
  final int bookMinor;
  final int differenceMinor;
  final int? movementId;
  final String? note;
  final DateTime createdAt;
}

class CashBookSnapshot {
  const CashBookSnapshot({
    required this.accounts,
    required this.advances,
    this.todayCashClosing,
  });

  final List<MoneyAccountModel> accounts;
  final List<PartyAdvanceModel> advances;
  final CashClosingModel? todayCashClosing;

  List<MoneyAccountModel> get active =>
      accounts.where((account) => !account.isArchived).toList(growable: false);

  int get bookMinor =>
      active.fold<int>(0, (sum, account) => sum + account.bookMinor);

  int get availableMinor =>
      active.fold<int>(0, (sum, account) => sum + account.availableMinor);

  int get pendingMinor =>
      active.fold<int>(0, (sum, account) => sum + account.pendingMinor);

  int get openAdvanceMinor =>
      advances.fold<int>(0, (sum, advance) => sum + advance.remainingMinor);
}

class CashBookAdvanceArgs {
  const CashBookAdvanceArgs({this.partyType, this.partyId, this.partyName});

  final PartyKind? partyType;
  final int? partyId;
  final String? partyName;
}

class AllocatableDocument {
  const AllocatableDocument({
    required this.id,
    required this.number,
    required this.partyName,
    required this.date,
    required this.balanceMinor,
  });

  final int id;
  final String number;
  final String partyName;
  final DateTime date;
  final int balanceMinor;
}
