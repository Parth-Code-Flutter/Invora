import '../../../data/models/invoice_model.dart';
import '../../../data/services/invoice_pdf_service.dart';

enum InvoiceSaveSuccessAction { viewPdf, done }

class InvoiceSaveSuccessArgs {
  const InvoiceSaveSuccessArgs({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.documentType,
    required this.template,
    required this.wasUpdate,
  });

  final int invoiceId;
  final String invoiceNumber;
  final DocumentType documentType;
  final InvoiceTemplate template;
  final bool wasUpdate;
}
