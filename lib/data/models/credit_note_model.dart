import '../../app/enums/tax_type.dart';
import 'invoice_calculation_models.dart';
import 'invoice_model.dart';

enum CreditNoteRemainderAction { applyThenKeep, applyThenRefund }

abstract final class CreditNoteDate {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static (DateTime first, DateTime last) bounds({
    required DateTime invoiceDate,
    DateTime? now,
  }) {
    final first = dateOnly(invoiceDate);
    final today = dateOnly(now ?? DateTime.now());
    var last = today.add(const Duration(days: 365));
    if (last.isBefore(first)) last = first;
    return (first, last);
  }

  static DateTime clamp({
    required DateTime invoiceDate,
    required DateTime proposed,
    DateTime? now,
  }) {
    final range = bounds(invoiceDate: invoiceDate, now: now);
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

class CreditNoteItemDraft {
  const CreditNoteItemDraft({
    required this.invoiceItem,
    required this.originalQuantityScaled,
    required this.returnedQuantityScaled,
    required this.alreadyReturnedScaled,
  });

  final InvoiceItemModel invoiceItem;
  final int originalQuantityScaled;
  final int returnedQuantityScaled;
  final int alreadyReturnedScaled;

  int get remainingScaled => originalQuantityScaled - alreadyReturnedScaled;
}

class CreditNoteItemModel {
  const CreditNoteItemModel({
    this.id,
    this.invoiceItemId,
    required this.name,
    this.description,
    required this.quantityScaled,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
    this.discount = const DiscountInput.none(),
    required this.baseAmountMinor,
    required this.discountAmountMinor,
    required this.taxableAmountMinor,
    required this.taxAmountMinor,
    required this.totalMinor,
  });

  final int? id;
  final int? invoiceItemId;
  final String name;
  final String? description;
  final int quantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final DiscountInput discount;
  final int baseAmountMinor;
  final int discountAmountMinor;
  final int taxableAmountMinor;
  final int taxAmountMinor;
  final int totalMinor;

  bool get isValueAdjustment => invoiceItemId == null;
}

class CreditNoteSummaryModel {
  const CreditNoteSummaryModel({
    required this.id,
    required this.creditNoteNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.creditNoteDate,
    required this.reason,
    required this.grandTotalMinor,
    required this.appliedMinor,
    required this.refundedMinor,
  });

  final int id;
  final String creditNoteNumber;
  final int invoiceId;
  final String invoiceNumber;
  final String customerName;
  final DateTime creditNoteDate;
  final String reason;
  final int grandTotalMinor;
  final int appliedMinor;
  final int refundedMinor;

  int get unappliedMinor => grandTotalMinor - appliedMinor - refundedMinor;
}

class CreditNoteModel {
  const CreditNoteModel({
    this.id,
    required this.creditNoteNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    required this.creditNoteDate,
    required this.reason,
    required this.taxType,
    required this.items,
    required this.subtotalMinor,
    required this.itemDiscountMinor,
    required this.taxableMinor,
    required this.taxMinor,
    required this.cgstMinor,
    required this.sgstMinor,
    required this.igstMinor,
    required this.roundOffMinor,
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
  final String creditNoteNumber;
  final int invoiceId;
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final DateTime creditNoteDate;
  final String reason;
  final TaxType taxType;
  final List<CreditNoteItemModel> items;
  final int subtotalMinor;
  final int itemDiscountMinor;
  final int taxableMinor;
  final int taxMinor;
  final int cgstMinor;
  final int sgstMinor;
  final int igstMinor;
  final int roundOffMinor;
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
