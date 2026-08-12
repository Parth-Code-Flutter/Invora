import 'business_profile_model.dart';
import 'invoice_model.dart';
import 'invoice_payment_model.dart';

class PaymentReceiptModel {
  const PaymentReceiptModel({
    required this.invoice,
    required this.payment,
    required this.business,
    required this.balanceAfterMinor,
  });

  final InvoiceModel invoice;
  final InvoicePaymentModel payment;
  final BusinessProfileModel business;
  final int balanceAfterMinor;

  String get receiptNumber => 'RCT-${invoice.id ?? 0}-${payment.id ?? 0}';
}
