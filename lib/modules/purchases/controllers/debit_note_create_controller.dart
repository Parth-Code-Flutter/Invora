import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/debit_note_model.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/debit_note_repository.dart';
import '../../../data/repositories/purchase_repository.dart';

class DebitNoteCreateController extends GetxController {
  DebitNoteCreateController(this._purchases, this._debitNotes);

  final PurchaseRepository _purchases;
  final DebitNoteRepository _debitNotes;

  final bill = Rxn<PurchaseBillModel>();
  final lines = <DebitNoteItemDraft>[].obs;
  final isValueAdjustment = false.obs;
  static const otherReason = 'Other';
  static const reasonPresets = [
    'Damaged goods',
    'Wrong item received',
    'Short quantity',
    'Quality issue',
    'Price correction',
    'Goods returned to supplier',
    otherReason,
  ];

  final remainder = DebitNoteRemainderAction.applyThenKeep.obs;
  final debitNoteDate = DateTime.now().obs;
  final reasonChoice = reasonPresets.first.obs;
  final reasonController = TextEditingController();
  final adjustmentController = TextEditingController();
  final adjustmentTaxRateBasisPoints = 0.obs;
  final refundMethod = 'UPI'.obs;
  final isWorking = false.obs;
  final previewTotalMinor = 0.obs;

  int get billId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final loaded = await _purchases.getBill(billId);
    bill.value = loaded;
    if (loaded == null) return;
    final returned = await _debitNotes.returnedQuantityByItem(loaded.id!);
    lines.assignAll(
      loaded.items.map((item) {
        final prior = item.id == null ? 0 : (returned[item.id!] ?? 0);
        return DebitNoteItemDraft(
          purchaseItem: item,
          originalQuantityScaled: (item.quantity * 1000).round(),
          returnedQuantityScaled: 0,
          alreadyReturnedScaled: prior,
        );
      }),
    );
    final rates = loaded.items
        .map((item) => (item.taxRate * 100).round())
        .toSet();
    if (rates.isNotEmpty) {
      adjustmentTaxRateBasisPoints.value = rates.first;
    }
    debitNoteDate.value = DebitNoteDate.clamp(
      billDate: loaded.billDate,
      proposed: debitNoteDate.value,
    );
    recalculate();
  }

  bool get isOtherReason => reasonChoice.value == otherReason;

  String get resolvedReason =>
      isOtherReason ? reasonController.text.trim() : reasonChoice.value;

  (DateTime first, DateTime last) get pickerBounds {
    final loaded = bill.value;
    if (loaded == null) {
      final today = DebitNoteDate.dateOnly(DateTime.now());
      return (today, today.add(const Duration(days: 365)));
    }
    return DebitNoteDate.bounds(billDate: loaded.billDate);
  }

  DateTime get pickerInitialDate {
    final range = pickerBounds;
    return DebitNoteDate.clampToBounds(
      proposed: debitNoteDate.value,
      first: range.$1,
      last: range.$2,
    );
  }

  void setReturnDate(DateTime value) {
    final loaded = bill.value;
    debitNoteDate.value = loaded == null
        ? DebitNoteDate.dateOnly(value)
        : DebitNoteDate.clamp(billDate: loaded.billDate, proposed: value);
  }

  void setReasonChoice(String value) {
    reasonChoice.value = value;
    if (value != otherReason) {
      reasonController.clear();
    }
  }

  void setReturnedQuantity(int index, int quantityScaled) {
    final current = lines[index];
    final capped = quantityScaled.clamp(0, current.remainingScaled);
    lines[index] = DebitNoteItemDraft(
      purchaseItem: current.purchaseItem,
      originalQuantityScaled: current.originalQuantityScaled,
      returnedQuantityScaled: capped,
      alreadyReturnedScaled: current.alreadyReturnedScaled,
    );
    lines.refresh();
    recalculate();
  }

  void stepReturnedQuantity(int index, int direction) {
    final current = lines[index];
    if (direction > 0) {
      final remaining =
          current.remainingScaled - current.returnedQuantityScaled;
      if (remaining <= 0) return;
      final delta = remaining < QuantityUtils.scale
          ? remaining
          : QuantityUtils.scale;
      setReturnedQuantity(index, current.returnedQuantityScaled + delta);
      return;
    }
    final next = current.returnedQuantityScaled - QuantityUtils.scale;
    setReturnedQuantity(index, next < 0 ? 0 : next);
  }

  int linePreviewMinor(DebitNoteItemDraft line) {
    final loaded = bill.value;
    if (loaded == null || line.returnedQuantityScaled <= 0) return 0;
    return _lineTotal(
      quantityScaled: line.returnedQuantityScaled,
      rateMinor: line.purchaseItem.rateMinor,
      taxRate: line.purchaseItem.taxRate,
      taxMode: loaded.taxMode,
    );
  }

  @override
  void onClose() {
    reasonController.dispose();
    adjustmentController.dispose();
    super.onClose();
  }

  void setValueAdjustment(bool value) {
    isValueAdjustment.value = value;
    recalculate();
  }

  void recalculate() {
    final loaded = bill.value;
    if (loaded == null) {
      previewTotalMinor.value = 0;
      return;
    }
    var total = 0;
    if (isValueAdjustment.value) {
      final amount = CurrencyUtils.parseMinor(adjustmentController.text) ?? 0;
      if (amount > 0) {
        total = _lineTotal(
          quantityScaled: 1000,
          rateMinor: amount,
          taxRate: adjustmentTaxRateBasisPoints.value / 100,
          taxMode: loaded.taxMode,
        );
      }
    } else {
      for (final line in lines) {
        if (line.returnedQuantityScaled <= 0) continue;
        total += _lineTotal(
          quantityScaled: line.returnedQuantityScaled,
          rateMinor: line.purchaseItem.rateMinor,
          taxRate: line.purchaseItem.taxRate,
          taxMode: loaded.taxMode,
        );
      }
    }
    previewTotalMinor.value = total;
  }

  int get leftoverMinor {
    final loaded = bill.value;
    if (loaded == null) return 0;
    final leftover = previewTotalMinor.value - loaded.balanceMinor;
    return leftover > 0 ? leftover : 0;
  }

  Future<void> submit() async {
    final loaded = bill.value;
    if (loaded == null) return;
    if (loaded.status == 'cancelled') {
      AppNotification.warning(
        'Cannot issue debit note',
        'Debit notes can only be issued for posted purchase bills.',
      );
      return;
    }
    if (resolvedReason.isEmpty) {
      AppNotification.warning(
        'Cannot issue debit note',
        isOtherReason
            ? 'Enter a reason for this debit note.'
            : 'Choose a reason for this debit note.',
      );
      return;
    }
    isWorking.value = true;
    try {
      final note = await _debitNotes.issue(
        bill: loaded,
        debitNoteDate: debitNoteDate.value,
        reason: resolvedReason,
        returnedItems: isValueAdjustment.value ? const [] : lines.toList(),
        valueAdjustmentMinor: isValueAdjustment.value
            ? CurrencyUtils.parseMinor(adjustmentController.text)
            : null,
        valueAdjustmentTaxRateBasisPoints: adjustmentTaxRateBasisPoints.value,
        remainder: leftoverMinor > 0
            ? remainder.value
            : DebitNoteRemainderAction.applyThenKeep,
        refundMethod: refundMethod.value,
      );
      AppNotification.success(
        'Debit note issued',
        '${note.debitNoteNumber} was saved.',
      );
      Get.offNamed<void>(AppRoutes.debitNoteDetails, arguments: note.id);
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot issue debit note',
        error.message?.toString() ?? error.toString(),
      );
    } on StateError catch (error) {
      AppNotification.warning('Cannot issue debit note', error.message);
    } finally {
      isWorking.value = false;
    }
  }

  static int _lineTotal({
    required int quantityScaled,
    required int rateMinor,
    required double taxRate,
    required String taxMode,
  }) {
    final base = ((quantityScaled / 1000) * rateMinor).round();
    final tax = taxMode == 'exempt' ? 0 : (base * taxRate / 100).round();
    return base + tax;
  }
}
