import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/credit_note_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/credit_note_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_calculation_service.dart';

class CreditNoteCreateController extends GetxController {
  CreditNoteCreateController(this._invoices, this._creditNotes);

  final InvoiceRepository _invoices;
  final CreditNoteRepository _creditNotes;
  static const _calculator = InvoiceCalculationService();

  final invoice = Rxn<InvoiceModel>();
  final lines = <CreditNoteItemDraft>[].obs;
  final isValueAdjustment = false.obs;
  static const otherReason = 'Other';
  static const reasonPresets = [
    'Damaged goods',
    'Wrong item delivered',
    'Short quantity',
    'Customer returned',
    'Quality issue',
    'Price correction',
    otherReason,
  ];

  final remainder = CreditNoteRemainderAction.applyThenKeep.obs;
  final creditNoteDate = DateTime.now().obs;
  final reasonChoice = reasonPresets.first.obs;
  final reasonController = TextEditingController();
  final adjustmentController = TextEditingController();
  final adjustmentTaxRateBasisPoints = 0.obs;
  final refundMethod = 'UPI'.obs;
  final isWorking = false.obs;
  final previewTotalMinor = 0.obs;

  int get invoiceId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final loaded = await _invoices.getById(invoiceId);
    invoice.value = loaded;
    if (loaded == null) return;
    final returned = await _creditNotes.returnedQuantityByItem(loaded.id!);
    lines.assignAll(
      loaded.items.map((item) {
        final prior = item.id == null ? 0 : (returned[item.id!] ?? 0);
        return CreditNoteItemDraft(
          invoiceItem: item,
          originalQuantityScaled: item.quantityScaled,
          returnedQuantityScaled: 0,
          alreadyReturnedScaled: prior,
        );
      }),
    );
    final rates = loaded.items.map((item) => item.taxRateBasisPoints).toSet();
    if (rates.isNotEmpty) {
      adjustmentTaxRateBasisPoints.value = rates.first;
    }
    creditNoteDate.value = CreditNoteDate.clamp(
      invoiceDate: loaded.invoiceDate,
      proposed: creditNoteDate.value,
    );
    recalculate();
  }

  bool get isOtherReason => reasonChoice.value == otherReason;

  String get resolvedReason =>
      isOtherReason ? reasonController.text.trim() : reasonChoice.value;

  (DateTime first, DateTime last) get pickerBounds {
    final loaded = invoice.value;
    if (loaded == null) {
      final today = CreditNoteDate.dateOnly(DateTime.now());
      return (today, today.add(const Duration(days: 365)));
    }
    return CreditNoteDate.bounds(invoiceDate: loaded.invoiceDate);
  }

  DateTime get pickerInitialDate {
    final range = pickerBounds;
    return CreditNoteDate.clampToBounds(
      proposed: creditNoteDate.value,
      first: range.$1,
      last: range.$2,
    );
  }

  void setReturnDate(DateTime value) {
    final loaded = invoice.value;
    creditNoteDate.value = loaded == null
        ? CreditNoteDate.dateOnly(value)
        : CreditNoteDate.clamp(
            invoiceDate: loaded.invoiceDate,
            proposed: value,
          );
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
    lines[index] = CreditNoteItemDraft(
      invoiceItem: current.invoiceItem,
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

  int linePreviewMinor(CreditNoteItemDraft line) {
    final loaded = invoice.value;
    if (loaded == null || line.returnedQuantityScaled <= 0) return 0;
    return _calculator
        .calculate(
          InvoiceCalculationInput(
            items: [
              InvoiceCalculationItemInput(
                id: line.invoiceItem.localId,
                quantityScaled: line.returnedQuantityScaled,
                rateMinor: line.invoiceItem.rateMinor,
                discount: line.invoiceItem.discount,
                taxRateBasisPoints: line.invoiceItem.taxRateBasisPoints,
              ),
            ],
            taxType: loaded.taxType,
          ),
        )
        .grandTotalMinor;
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
    final loaded = invoice.value;
    if (loaded == null) {
      previewTotalMinor.value = 0;
      return;
    }
    final items = <InvoiceCalculationItemInput>[];
    if (isValueAdjustment.value) {
      final amount = CurrencyUtils.parseMinor(adjustmentController.text) ?? 0;
      if (amount > 0) {
        items.add(
          InvoiceCalculationItemInput(
            id: 'adjustment',
            quantityScaled: 1000,
            rateMinor: amount,
            taxRateBasisPoints: adjustmentTaxRateBasisPoints.value,
          ),
        );
      }
    } else {
      for (final line in lines) {
        if (line.returnedQuantityScaled <= 0) continue;
        items.add(
          InvoiceCalculationItemInput(
            id: line.invoiceItem.localId,
            quantityScaled: line.returnedQuantityScaled,
            rateMinor: line.invoiceItem.rateMinor,
            discount: line.invoiceItem.discount,
            taxRateBasisPoints: line.invoiceItem.taxRateBasisPoints,
          ),
        );
      }
    }
    if (items.isEmpty) {
      previewTotalMinor.value = 0;
      return;
    }
    previewTotalMinor.value = _calculator
        .calculate(
          InvoiceCalculationInput(items: items, taxType: loaded.taxType),
        )
        .grandTotalMinor;
  }

  int get leftoverMinor {
    final loaded = invoice.value;
    if (loaded == null) return 0;
    final leftover =
        previewTotalMinor.value - loaded.calculation.balanceDueMinor;
    return leftover > 0 ? leftover : 0;
  }

  Future<void> submit() async {
    final loaded = invoice.value;
    if (loaded == null) return;
    if (loaded.status == InvoiceStatus.draft ||
        loaded.status == InvoiceStatus.cancelled) {
      AppNotification.warning(
        'Cannot issue credit note',
        'Credit notes can only be issued for posted invoices.',
      );
      return;
    }
    if (resolvedReason.isEmpty) {
      AppNotification.warning(
        'Cannot issue credit note',
        isOtherReason
            ? 'Enter a reason for this credit note.'
            : 'Choose a reason for this credit note.',
      );
      return;
    }
    isWorking.value = true;
    try {
      final note = await _creditNotes.issue(
        invoice: loaded,
        creditNoteDate: creditNoteDate.value,
        reason: resolvedReason,
        returnedItems: isValueAdjustment.value ? const [] : lines.toList(),
        valueAdjustmentMinor: isValueAdjustment.value
            ? CurrencyUtils.parseMinor(adjustmentController.text)
            : null,
        valueAdjustmentTaxRateBasisPoints: adjustmentTaxRateBasisPoints.value,
        remainder: leftoverMinor > 0
            ? remainder.value
            : CreditNoteRemainderAction.applyThenKeep,
        refundMethod: refundMethod.value,
      );
      AppNotification.success(
        'Credit note issued',
        '${note.creditNoteNumber} was saved.',
      );
      Get.offNamed<void>(AppRoutes.creditNoteDetails, arguments: note.id);
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot issue credit note',
        error.message?.toString() ?? error.toString(),
      );
    } on StateError catch (error) {
      AppNotification.warning('Cannot issue credit note', error.message);
    } finally {
      isWorking.value = false;
    }
  }
}
