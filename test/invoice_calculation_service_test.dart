import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/app/utils/quantity_utils.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  const service = InvoiceCalculationService();

  group('invoice calculation', () {
    test(
      'calculates decimal quantity, discounts, GST, charges and payment',
      () {
        final result = service.calculate(
          const InvoiceCalculationInput(
            items: [
              InvoiceCalculationItemInput(
                id: 'design',
                quantityScaled: 2500,
                rateMinor: 10000,
                discount: DiscountInput.percentage(1000),
                taxRateBasisPoints: 1800,
              ),
            ],
            invoiceDiscount: DiscountInput.fixed(500),
            additionalCharges: [
              AdditionalChargeInput(title: 'Delivery', amountMinor: 1000),
            ],
            taxType: TaxType.cgstSgst,
            paidAmountMinor: 10000,
          ),
        );

        expect(result.items.single.baseMinor, 25000);
        expect(result.itemDiscountTotalMinor, 2500);
        expect(result.items.single.taxableMinor, 22500);
        expect(result.taxTotalMinor, 4050);
        expect(result.invoiceDiscountMinor, 500);
        expect(result.taxableTotalMinor, 22000);
        expect(result.additionalChargeTotalMinor, 1000);
        expect(result.grandTotalMinor, 27050);
        expect(result.cgstMinor, 2025);
        expect(result.sgstMinor, 2025);
        expect(result.igstMinor, 0);
        expect(result.balanceDueMinor, 17050);
        expect(result.paymentStatus, InvoicePaymentStatus.partiallyPaid);
      },
    );

    test('uses deterministic half-up rounding for quantity and IGST', () {
      final result = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'fractional',
              quantityScaled: 333,
              rateMinor: 999,
              taxRateBasisPoints: 500,
            ),
          ],
          taxType: TaxType.igst,
        ),
      );

      expect(result.subtotalMinor, 333);
      expect(result.taxTotalMinor, 17);
      expect(result.igstMinor, 17);
      expect(result.grandTotalMinor, 350);
    });

    test('keeps odd CGST and SGST split equal to total tax', () {
      final result = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'odd-tax',
              quantityScaled: 1000,
              rateMinor: 333,
              taxRateBasisPoints: 500,
            ),
          ],
          taxType: TaxType.cgstSgst,
        ),
      );

      expect(result.taxTotalMinor, 17);
      expect(result.cgstMinor, 8);
      expect(result.sgstMinor, 9);
      expect(result.cgstMinor + result.sgstMinor, result.taxTotalMinor);
    });

    test('caps discounts so totals never become negative', () {
      final result = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'free-item',
              quantityScaled: 1000,
              rateMinor: 1000,
              discount: DiscountInput.fixed(5000),
              taxRateBasisPoints: 1800,
            ),
          ],
          invoiceDiscount: DiscountInput.fixed(5000),
          taxType: TaxType.none,
        ),
      );

      expect(result.itemDiscountTotalMinor, 1000);
      expect(result.invoiceDiscountMinor, 0);
      expect(result.taxTotalMinor, 0);
      expect(result.grandTotalMinor, 0);
      expect(result.paymentStatus, InvoicePaymentStatus.paid);
    });

    test('automatically rounds grand total to nearest whole currency unit', () {
      final roundsDown = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'down',
              quantityScaled: 1000,
              rateMinor: 1049,
            ),
          ],
          automaticRoundOff: true,
        ),
      );
      final roundsUp = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'up',
              quantityScaled: 1000,
              rateMinor: 1050,
            ),
          ],
          automaticRoundOff: true,
        ),
      );

      expect(roundsDown.roundOffMinor, -49);
      expect(roundsDown.grandTotalMinor, 1000);
      expect(roundsUp.roundOffMinor, 50);
      expect(roundsUp.grandTotalMinor, 1100);
    });

    test('derives unpaid, partially paid and paid statuses', () {
      InvoiceCalculationResult calculate(int paid) => service.calculate(
        InvoiceCalculationInput(
          items: const [
            InvoiceCalculationItemInput(
              id: 'status',
              quantityScaled: 1000,
              rateMinor: 10000,
            ),
          ],
          paidAmountMinor: paid,
        ),
      );

      expect(calculate(0).paymentStatus, InvoicePaymentStatus.unpaid);
      expect(calculate(5000).paymentStatus, InvoicePaymentStatus.partiallyPaid);
      expect(calculate(10000).paymentStatus, InvoicePaymentStatus.paid);
      expect(calculate(12000).paymentStatus, InvoicePaymentStatus.paid);
      expect(calculate(12000).balanceDueMinor, 0);
    });

    test('treats credited amounts as reducing the outstanding balance', () {
      final result = service.calculate(
        const InvoiceCalculationInput(
          items: [
            InvoiceCalculationItemInput(
              id: 'credit',
              quantityScaled: 1000,
              rateMinor: 10000,
            ),
          ],
          paidAmountMinor: 2000,
          creditedAmountMinor: 8000,
        ),
      );
      expect(result.balanceDueMinor, 0);
      expect(result.paymentStatus, InvoicePaymentStatus.paid);
      expect(result.creditedAmountMinor, 8000);
    });

    test('rejects invalid quantities, percentages, payments and round off', () {
      expect(
        () => service.calculate(
          const InvoiceCalculationInput(
            items: [
              InvoiceCalculationItemInput(
                id: 'invalid',
                quantityScaled: 0,
                rateMinor: 100,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => service.calculate(
          const InvoiceCalculationInput(
            items: [
              InvoiceCalculationItemInput(
                id: 'invalid-tax',
                quantityScaled: 1000,
                rateMinor: 100,
                taxRateBasisPoints: 10001,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => service.calculate(
          const InvoiceCalculationInput(items: [], paidAmountMinor: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => service.calculate(
          const InvoiceCalculationInput(items: [], roundOffMinor: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  test('quantity utility preserves up to three decimal places', () {
    expect(QuantityUtils.parseScaled('2.5'), 2500);
    expect(QuantityUtils.parseScaled('0.125'), 125);
    expect(QuantityUtils.parseScaled('1.2345'), isNull);
    expect(QuantityUtils.toInputValue(2500), '2.5');
    expect(QuantityUtils.toInputValue(125), '0.125');
  });
}
