enum InvoicePaymentEntryType { payment, opening, imported, reversal }

class InvoicePaymentModel {
  const InvoicePaymentModel({
    this.id,
    required this.invoiceId,
    required this.amountMinor,
    required this.paidAt,
    this.method,
    this.reference,
    this.note,
    this.entryType = InvoicePaymentEntryType.payment,
    this.reversesPaymentId,
    this.isReversed = false,
  });

  final int? id;
  final int invoiceId;
  final int amountMinor;
  final DateTime paidAt;
  final String? method;
  final String? reference;
  final String? note;
  final InvoicePaymentEntryType entryType;
  final int? reversesPaymentId;
  final bool isReversed;

  bool get isReversal => entryType == InvoicePaymentEntryType.reversal;
  bool get canReverse => amountMinor > 0 && !isReversed;
}
