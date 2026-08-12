import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/models/invoice_payment_model.dart';
import '../../../data/models/payment_receipt_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/payment_receipt_pdf_service.dart';

class PaymentReceiptArgs {
  const PaymentReceiptArgs({required this.invoiceId, required this.paymentId});
  final int invoiceId;
  final int paymentId;
}

class PaymentReceiptController extends GetxController {
  PaymentReceiptController(this._invoices, this._business, this._pdf);

  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final PaymentReceiptPdfService _pdf;
  final receipt = Rxn<PaymentReceiptModel>();
  final error = RxnString();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final args = Get.arguments;
    if (args is! PaymentReceiptArgs) {
      error.value = 'Receipt information is unavailable.';
      isLoading.value = false;
      return;
    }
    final invoice = await _invoices.getById(args.invoiceId);
    final business = await _business.getProfile();
    final payments = await _invoices.getPayments(args.invoiceId);
    final payment = payments.firstWhereOrNull(
      (entry) => entry.id == args.paymentId,
    );
    if (invoice == null || business == null || payment == null) {
      error.value = 'Receipt information is unavailable.';
    } else if (!_canReceipt(payment)) {
      error.value = 'Reversed payments cannot produce active receipts.';
    } else {
      final chronological = [...payments]
        ..sort((a, b) => a.paidAt.compareTo(b.paidAt));
      var paidThroughEntry = 0;
      for (final entry in chronological) {
        paidThroughEntry += entry.amountMinor;
        if (entry.id == payment.id) break;
      }
      receipt.value = PaymentReceiptModel(
        invoice: invoice,
        payment: payment,
        business: business,
        balanceAfterMinor:
            invoice.calculation.grandTotalMinor - paidThroughEntry,
      );
    }
    isLoading.value = false;
  }

  bool _canReceipt(InvoicePaymentModel payment) =>
      payment.amountMinor > 0 && !payment.isReversed && !payment.isReversal;

  Future<Uint8List> build() => _pdf.build(receipt.value!);
  Future<void> share() => _pdf.shareReceipt(receipt.value!);
  Future<void> print() => _pdf.printReceipt(receipt.value!);
  Future<void> save() async {
    final path = await _pdf.saveReceipt(receipt.value!);
    if (path != null) AppNotification.success('Receipt saved', path);
  }
}
