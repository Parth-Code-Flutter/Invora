import 'purchase_models.dart';

enum DebitNoteRemainderAction { applyThenKeep, applyThenRefund }

abstract final class DebitNoteDate {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static (DateTime first, DateTime last) bounds({
    required DateTime billDate,
    DateTime? now,
  }) {
    final first = dateOnly(billDate);
    final today = dateOnly(now ?? DateTime.now());
    var last = today.add(const Duration(days: 365));
    if (last.isBefore(first)) last = first;
    return (first, last);
  }

  static DateTime clamp({
    required DateTime billDate,
    required DateTime proposed,
    DateTime? now,
  }) {
    final range = bounds(billDate: billDate, now: now);
    return clampToBounds(proposed: proposed, first: range.$1, last: range.$2);
  }

  static DateTime clampToBounds({
    required DateTime proposed,
    required DateTime first,
    required DateTime last,
  }) {
    final current = dateOnly(proposed);
    if (current.isBefore(first)) return first;
    if (current.isAfter(last)) return last;
    return current;
  }
}

class DebitNoteItemDraft {
  const DebitNoteItemDraft({
    required this.purchaseItem,
    required this.originalQuantityScaled,
    required this.returnedQuantityScaled,
    required this.alreadyReturnedScaled,
  });

  final PurchaseItemModel purchaseItem;
  final int originalQuantityScaled;
  final int returnedQuantityScaled;
  final int alreadyReturnedScaled;

  int get remainingScaled => originalQuantityScaled - alreadyReturnedScaled;
}

class DebitNoteItemModel {
  const DebitNoteItemModel({
    this.id,
    this.purchaseItemId,
    required this.name,
    required this.quantityScaled,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
    required this.baseAmountMinor,
    required this.taxAmountMinor,
    required this.totalMinor,
  });

  final int? id;
  final int? purchaseItemId;
  final String name;
  final int quantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final int baseAmountMinor;
  final int taxAmountMinor;
  final int totalMinor;

  bool get isValueAdjustment => purchaseItemId == null;
}

class DebitNoteSummaryModel {
  const DebitNoteSummaryModel({
    required this.id,
    required this.debitNoteNumber,
    required this.purchaseBillId,
    required this.billNumber,
    required this.supplierName,
    required this.debitNoteDate,
    required this.reason,
    required this.grandTotalMinor,
    required this.appliedMinor,
    required this.refundedMinor,
  });

  final int id;
  final String debitNoteNumber;
  final int purchaseBillId;
  final String billNumber;
  final String supplierName;
  final DateTime debitNoteDate;
  final String reason;
  final int grandTotalMinor;
  final int appliedMinor;
  final int refundedMinor;

  int get unappliedMinor => grandTotalMinor - appliedMinor - refundedMinor;
}

class DebitNoteModel {
  const DebitNoteModel({
    this.id,
    required this.debitNoteNumber,
    required this.purchaseBillId,
    required this.billNumber,
    this.supplierId,
    required this.supplierName,
    required this.debitNoteDate,
    required this.reason,
    required this.taxMode,
    required this.itcEligible,
    required this.items,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.cgstMinor,
    required this.sgstMinor,
    required this.igstMinor,
    required this.grandTotalMinor,
    required this.appliedMinor,
    required this.refundedMinor,
    this.refundMethod,
    this.refundedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String debitNoteNumber;
  final int purchaseBillId;
  final String billNumber;
  final int? supplierId;
  final String supplierName;
  final DateTime debitNoteDate;
  final String reason;
  final String taxMode;
  final bool itcEligible;
  final List<DebitNoteItemModel> items;
  final int subtotalMinor;
  final int taxMinor;
  final int cgstMinor;
  final int sgstMinor;
  final int igstMinor;
  final int grandTotalMinor;
  final int appliedMinor;
  final int refundedMinor;
  final String? refundMethod;
  final DateTime? refundedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get unappliedMinor => grandTotalMinor - appliedMinor - refundedMinor;
}
