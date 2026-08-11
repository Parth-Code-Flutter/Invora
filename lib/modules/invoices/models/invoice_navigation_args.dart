import '../../../data/models/invoice_model.dart';

class InvoiceDetailsArgs {
  const InvoiceDetailsArgs({required this.invoiceId, this.readOnly = false});

  final int invoiceId;
  final bool readOnly;
}

class InvoicePreviewArgs {
  const InvoicePreviewArgs({
    this.invoiceId,
    this.invoice,
    this.readOnly = false,
  }) : assert(invoiceId != null || invoice != null);

  final int? invoiceId;
  final InvoiceModel? invoice;
  final bool readOnly;
}
