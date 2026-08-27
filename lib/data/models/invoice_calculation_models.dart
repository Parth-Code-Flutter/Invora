import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';

class DiscountInput {
  const DiscountInput.none()
    : type = DiscountType.none,
      fixedMinor = 0,
      percentageBasisPoints = 0;

  const DiscountInput.fixed(this.fixedMinor)
    : type = DiscountType.fixed,
      percentageBasisPoints = 0;

  const DiscountInput.percentage(this.percentageBasisPoints)
    : type = DiscountType.percentage,
      fixedMinor = 0;

  final DiscountType type;
  final int fixedMinor;
  final int percentageBasisPoints;
}

class InvoiceCalculationItemInput {
  const InvoiceCalculationItemInput({
    required this.id,
    required this.quantityScaled,
    required this.rateMinor,
    this.discount = const DiscountInput.none(),
    this.taxRateBasisPoints = 0,
  });

  final String id;
  final int quantityScaled;
  final int rateMinor;
  final DiscountInput discount;
  final int taxRateBasisPoints;
}

class AdditionalChargeInput {
  const AdditionalChargeInput({required this.title, required this.amountMinor});
  final String title;
  final int amountMinor;
}

class InvoiceCalculationInput {
  const InvoiceCalculationInput({
    required this.items,
    this.invoiceDiscount = const DiscountInput.none(),
    this.additionalCharges = const [],
    this.taxType = TaxType.none,
    this.roundOffMinor = 0,
    this.automaticRoundOff = false,
    this.paidAmountMinor = 0,
    this.creditedAmountMinor = 0,
  });

  final List<InvoiceCalculationItemInput> items;
  final DiscountInput invoiceDiscount;
  final List<AdditionalChargeInput> additionalCharges;
  final TaxType taxType;
  final int roundOffMinor;
  final bool automaticRoundOff;
  final int paidAmountMinor;
  final int creditedAmountMinor;
}

class InvoiceCalculationItemResult {
  const InvoiceCalculationItemResult({
    required this.id,
    required this.baseMinor,
    required this.discountMinor,
    required this.taxableMinor,
    required this.taxMinor,
    required this.totalMinor,
  });

  final String id;
  final int baseMinor;
  final int discountMinor;
  final int taxableMinor;
  final int taxMinor;
  final int totalMinor;
}

class InvoiceCalculationResult {
  const InvoiceCalculationResult({
    required this.items,
    required this.subtotalMinor,
    required this.itemDiscountTotalMinor,
    required this.invoiceDiscountMinor,
    required this.taxableTotalMinor,
    required this.taxTotalMinor,
    required this.cgstMinor,
    required this.sgstMinor,
    required this.igstMinor,
    required this.additionalChargeTotalMinor,
    required this.roundOffMinor,
    required this.grandTotalMinor,
    required this.paidAmountMinor,
    this.creditedAmountMinor = 0,
    required this.balanceDueMinor,
    required this.paymentStatus,
  });

  final List<InvoiceCalculationItemResult> items;
  final int subtotalMinor;
  final int itemDiscountTotalMinor;
  final int invoiceDiscountMinor;
  final int taxableTotalMinor;
  final int taxTotalMinor;
  final int cgstMinor;
  final int sgstMinor;
  final int igstMinor;
  final int additionalChargeTotalMinor;
  final int roundOffMinor;
  final int grandTotalMinor;
  final int paidAmountMinor;
  final int creditedAmountMinor;
  final int balanceDueMinor;
  final InvoicePaymentStatus paymentStatus;
}
