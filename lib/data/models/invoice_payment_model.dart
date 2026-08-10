class InvoicePaymentModel {
  const InvoicePaymentModel({
    this.id,
    required this.invoiceId,
    required this.amountMinor,
    required this.paidAt,
    this.method,
    this.reference,
    this.note,
  });

  final int? id;
  final int invoiceId;
  final int amountMinor;
  final DateTime paidAt;
  final String? method;
  final String? reference;
  final String? note;
}
