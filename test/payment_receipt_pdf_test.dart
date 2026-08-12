import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/invoice_payment_model.dart';
import 'package:creovo_invoice/data/models/payment_receipt_model.dart';
import 'package:creovo_invoice/data/services/payment_receipt_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = PaymentReceiptPdfService();

  test('builds a Unicode payment receipt with a stable number', () async {
    final receipt = _receipt();
    final bytes = await service.build(receipt);

    expect(bytes, isNotEmpty);
    expect(receipt.receiptNumber, 'RCT-8-21');
    expect(service.fileName(receipt), contains('INV-0008'));
  });

  test('does not generate a receipt for a reversed payment', () async {
    final receipt = _receipt(isReversed: true);
    await expectLater(service.build(receipt), throwsA(isA<StateError>()));
  });
}

PaymentReceiptModel _receipt({bool isReversed = false}) {
  final now = DateTime(2026, 8, 12, 16, 35);
  const calculation = InvoiceCalculationResult(
    items: [],
    subtotalMinor: 100000,
    itemDiscountTotalMinor: 0,
    invoiceDiscountMinor: 0,
    taxableTotalMinor: 100000,
    taxTotalMinor: 18000,
    cgstMinor: 9000,
    sgstMinor: 9000,
    igstMinor: 0,
    additionalChargeTotalMinor: 0,
    roundOffMinor: 0,
    grandTotalMinor: 118000,
    paidAmountMinor: 50000,
    balanceDueMinor: 68000,
    paymentStatus: InvoicePaymentStatus.partiallyPaid,
  );
  return PaymentReceiptModel(
    business: BusinessProfileModel(
      businessName: 'Creovo Creations',
      currencySymbol: '₹',
      createdAt: now,
      updatedAt: now,
    ),
    invoice: InvoiceModel(
      id: 8,
      invoiceNumber: 'INV-0008',
      customer: const CustomerSnapshotModel(name: 'Rinkal Ben'),
      invoiceDate: now,
      status: InvoiceStatus.partiallyPaid,
      taxType: TaxType.cgstSgst,
      invoiceDiscount: const DiscountInput.none(),
      items: const [],
      charges: const [],
      calculation: calculation,
      createdAt: now,
      updatedAt: now,
    ),
    payment: InvoicePaymentModel(
      id: 21,
      invoiceId: 8,
      amountMinor: 50000,
      paidAt: now,
      method: 'UPI',
      reference: 'PAY-₹-21',
      isReversed: isReversed,
    ),
    balanceAfterMinor: 68000,
  );
}
