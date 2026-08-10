import '../../app/enums/invoice_status.dart';
import '../models/invoice_model.dart';

class InvoiceValidationService {
  const InvoiceValidationService();

  String? validateRequired(InvoiceModel document) {
    final documentLabel = document.documentType == DocumentType.quotation
        ? 'quotation'
        : 'invoice';
    if (document.invoiceNumber.trim().isEmpty) {
      return 'A $documentLabel number is required.';
    }
    if (document.customer.name.trim().isEmpty) {
      return 'Select a customer before continuing.';
    }
    if (document.items.isEmpty) {
      return 'Add at least one product or service.';
    }
    for (final item in document.items) {
      if (item.name.trim().isEmpty || item.unit.trim().isEmpty) {
        return 'Every item needs a name and unit.';
      }
      if (item.quantityScaled <= 0) {
        return 'Every item quantity must be greater than zero.';
      }
      if (item.rateMinor <= 0) {
        return 'Every item rate must be greater than zero.';
      }
      if (item.taxRateBasisPoints < 0 || item.taxRateBasisPoints > 10000) {
        return 'Every item must have a valid tax rate.';
      }
    }
    if (document.dueDate != null &&
        _dateOnly(
          document.dueDate!,
        ).isBefore(_dateOnly(document.invoiceDate))) {
      return 'Payment due date cannot be before the invoice date.';
    }
    if (document.calculation.grandTotalMinor <= 0) {
      return 'Invoice total must be greater than zero.';
    }
    if (document.calculation.paidAmountMinor < 0 ||
        document.calculation.paidAmountMinor >
            document.calculation.grandTotalMinor) {
      return 'Paid amount must be between zero and the invoice total.';
    }
    return null;
  }

  bool requiresCompleteDocument(InvoiceModel document) =>
      document.status != InvoiceStatus.draft;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
