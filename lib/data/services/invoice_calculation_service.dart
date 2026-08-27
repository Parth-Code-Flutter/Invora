import 'dart:math' as math;

import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import '../../app/utils/quantity_utils.dart';
import '../models/invoice_calculation_models.dart';

class InvoiceCalculationService {
  const InvoiceCalculationService();

  InvoiceCalculationResult calculate(InvoiceCalculationInput input) {
    _validateInput(input);

    final itemResults = input.items
        .map((item) {
          final baseMinor = _roundDivide(
            item.rateMinor * item.quantityScaled,
            QuantityUtils.scale,
          );
          final discountMinor = _calculateDiscount(item.discount, baseMinor);
          final taxableMinor = baseMinor - discountMinor;
          final taxMinor = input.taxType == TaxType.none
              ? 0
              : _roundDivide(taxableMinor * item.taxRateBasisPoints, 10000);
          return InvoiceCalculationItemResult(
            id: item.id,
            baseMinor: baseMinor,
            discountMinor: discountMinor,
            taxableMinor: taxableMinor,
            taxMinor: taxMinor,
            totalMinor: taxableMinor + taxMinor,
          );
        })
        .toList(growable: false);

    final subtotalMinor = itemResults.fold<int>(
      0,
      (total, item) => total + item.baseMinor,
    );
    final itemDiscountTotalMinor = itemResults.fold<int>(
      0,
      (total, item) => total + item.discountMinor,
    );
    final taxableTotalBeforeInvoiceDiscount =
        subtotalMinor - itemDiscountTotalMinor;
    final invoiceDiscountMinor = _calculateDiscount(
      input.invoiceDiscount,
      taxableTotalBeforeInvoiceDiscount,
    );
    final taxableTotalMinor =
        taxableTotalBeforeInvoiceDiscount - invoiceDiscountMinor;
    final taxTotalMinor = itemResults.fold<int>(
      0,
      (total, item) => total + item.taxMinor,
    );
    final additionalChargeTotalMinor = input.additionalCharges.fold<int>(
      0,
      (total, charge) => total + charge.amountMinor,
    );
    final beforeRoundOff =
        taxableTotalMinor + taxTotalMinor + additionalChargeTotalMinor;
    final roundOffMinor = input.automaticRoundOff
        ? roundOffToNearestWhole(beforeRoundOff)
        : input.roundOffMinor;
    final grandTotalMinor = beforeRoundOff + roundOffMinor;
    if (grandTotalMinor < 0) {
      throw ArgumentError.value(
        roundOffMinor,
        'roundOffMinor',
        'Round off cannot make the grand total negative.',
      );
    }

    final settledMinor = input.paidAmountMinor + input.creditedAmountMinor;
    final balanceDueMinor = math.max(0, grandTotalMinor - settledMinor);
    final paymentStatus = _paymentStatus(
      settledMinor: settledMinor,
      grandTotalMinor: grandTotalMinor,
    );

    final cgstMinor = input.taxType == TaxType.cgstSgst
        ? taxTotalMinor ~/ 2
        : 0;
    final sgstMinor = input.taxType == TaxType.cgstSgst
        ? taxTotalMinor - cgstMinor
        : 0;
    final igstMinor = input.taxType == TaxType.igst ? taxTotalMinor : 0;

    return InvoiceCalculationResult(
      items: itemResults,
      subtotalMinor: subtotalMinor,
      itemDiscountTotalMinor: itemDiscountTotalMinor,
      invoiceDiscountMinor: invoiceDiscountMinor,
      taxableTotalMinor: taxableTotalMinor,
      taxTotalMinor: taxTotalMinor,
      cgstMinor: cgstMinor,
      sgstMinor: sgstMinor,
      igstMinor: igstMinor,
      additionalChargeTotalMinor: additionalChargeTotalMinor,
      roundOffMinor: roundOffMinor,
      grandTotalMinor: grandTotalMinor,
      paidAmountMinor: input.paidAmountMinor,
      creditedAmountMinor: input.creditedAmountMinor,
      balanceDueMinor: balanceDueMinor,
      paymentStatus: paymentStatus,
    );
  }

  int roundOffToNearestWhole(int amountMinor) {
    if (amountMinor < 0) {
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'Cannot be negative.',
      );
    }
    final remainder = amountMinor % 100;
    if (remainder == 0) return 0;
    return remainder < 50 ? -remainder : 100 - remainder;
  }

  int _calculateDiscount(DiscountInput discount, int baseMinor) {
    final calculated = switch (discount.type) {
      DiscountType.none => 0,
      DiscountType.fixed => discount.fixedMinor,
      DiscountType.percentage => _roundDivide(
        baseMinor * discount.percentageBasisPoints,
        10000,
      ),
    };
    return math.min(baseMinor, calculated);
  }

  InvoicePaymentStatus _paymentStatus({
    required int settledMinor,
    required int grandTotalMinor,
  }) {
    if (settledMinor == 0 && grandTotalMinor > 0) {
      return InvoicePaymentStatus.unpaid;
    }
    if (settledMinor < grandTotalMinor) {
      return InvoicePaymentStatus.partiallyPaid;
    }
    return InvoicePaymentStatus.paid;
  }

  int _roundDivide(int numerator, int denominator) {
    return (numerator + (denominator ~/ 2)) ~/ denominator;
  }

  void _validateInput(InvoiceCalculationInput input) {
    if (input.paidAmountMinor < 0) {
      throw ArgumentError.value(
        input.paidAmountMinor,
        'paidAmountMinor',
        'Cannot be negative.',
      );
    }
    if (input.creditedAmountMinor < 0) {
      throw ArgumentError.value(
        input.creditedAmountMinor,
        'creditedAmountMinor',
        'Cannot be negative.',
      );
    }
    if (input.automaticRoundOff && input.roundOffMinor != 0) {
      throw ArgumentError(
        'Manual and automatic round off cannot be used together.',
      );
    }
    _validateDiscount(input.invoiceDiscount, 'invoiceDiscount');
    for (final item in input.items) {
      if (item.id.trim().isEmpty) {
        throw ArgumentError.value(item.id, 'item.id', 'Cannot be empty.');
      }
      if (item.quantityScaled <= 0) {
        throw ArgumentError.value(
          item.quantityScaled,
          'item.quantityScaled',
          'Must be greater than zero.',
        );
      }
      if (item.rateMinor < 0) {
        throw ArgumentError.value(item.rateMinor, 'item.rateMinor');
      }
      if (item.taxRateBasisPoints < 0 || item.taxRateBasisPoints > 10000) {
        throw ArgumentError.value(
          item.taxRateBasisPoints,
          'item.taxRateBasisPoints',
          'Must be between 0 and 10000.',
        );
      }
      _validateDiscount(item.discount, 'item.discount');
    }
    for (final charge in input.additionalCharges) {
      if (charge.title.trim().isEmpty) {
        throw ArgumentError.value(charge.title, 'charge.title');
      }
      if (charge.amountMinor < 0) {
        throw ArgumentError.value(charge.amountMinor, 'charge.amountMinor');
      }
    }
  }

  void _validateDiscount(DiscountInput discount, String name) {
    if (discount.fixedMinor < 0) {
      throw ArgumentError.value(discount.fixedMinor, '$name.fixedMinor');
    }
    if (discount.percentageBasisPoints < 0 ||
        discount.percentageBasisPoints > 10000) {
      throw ArgumentError.value(
        discount.percentageBasisPoints,
        '$name.percentageBasisPoints',
        'Must be between 0 and 10000.',
      );
    }
  }
}
