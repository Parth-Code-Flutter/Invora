import '../../app/enums/invoice_status.dart';
import '../models/business_profile_model.dart';
import '../models/customer_model.dart';
import '../models/customer_statement_model.dart';
import '../models/cash_book_models.dart';
import '../models/invoice_payment_model.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/cash_book_repository.dart';

class CustomerStatementService {
  const CustomerStatementService(
    this._invoices,
    this._creditNotes, [
    this._cashBook,
  ]);

  final InvoiceRepository _invoices;
  final CreditNoteRepository _creditNotes;
  final CashBookRepository? _cashBook;

  Future<CustomerStatementModel> build({
    required CustomerModel customer,
    required BusinessProfileModel business,
    required DateTime from,
    required DateTime to,
  }) async {
    if (customer.id == null) throw ArgumentError('Customer is not saved.');
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    if (end.isBefore(start)) throw ArgumentError('Invalid statement range.');
    final invoices = await _invoices.watchCustomerInvoices(customer.id!).first;
    final events = <_RawStatementEvent>[];
    for (final summary in invoices) {
      if (summary.status == InvoiceStatus.cancelled) continue;
      events.add(
        _RawStatementEvent(
          date: summary.invoiceDate,
          type: CustomerStatementEntryType.invoice,
          reference: summary.invoiceNumber,
          description: 'Invoice issued',
          debitMinor: summary.grandTotalMinor,
          creditMinor: 0,
          order: 0,
        ),
      );
      for (final payment in await _invoices.getPayments(summary.id)) {
        if (payment.entryType == InvoicePaymentEntryType.advance) continue;
        events.add(
          _RawStatementEvent(
            date: payment.paidAt,
            type: payment.isReversal
                ? CustomerStatementEntryType.reversal
                : CustomerStatementEntryType.payment,
            reference: payment.reference ?? summary.invoiceNumber,
            description: payment.isReversal
                ? 'Payment reversal · ${payment.note ?? summary.invoiceNumber}'
                : '${payment.method ?? 'Payment'} · ${summary.invoiceNumber}',
            debitMinor: payment.amountMinor < 0 ? -payment.amountMinor : 0,
            creditMinor: payment.amountMinor > 0 ? payment.amountMinor : 0,
            order: payment.isReversal ? 2 : 1,
          ),
        );
      }
    }
    final notes = await _creditNotes.listForCustomer(customer.id!);
    for (final note in notes) {
      events.add(
        _RawStatementEvent(
          date: note.creditNoteDate,
          type: CustomerStatementEntryType.creditNote,
          reference: note.creditNoteNumber,
          description: 'Credit note · ${note.reason}',
          debitMinor: 0,
          creditMinor: note.grandTotalMinor,
          order: 3,
        ),
      );
      if (note.refundedMinor > 0) {
        events.add(
          _RawStatementEvent(
            date: note.creditNoteDate,
            type: CustomerStatementEntryType.refund,
            reference: note.creditNoteNumber,
            description: 'Refund · ${note.creditNoteNumber}',
            debitMinor: note.refundedMinor,
            creditMinor: 0,
            order: 4,
          ),
        );
      }
    }
    final cashBook = _cashBook;
    if (cashBook != null && customer.id != null) {
      final allAdvances = await cashBook.listAdvancesForParty(
        partyType: PartyKind.customer,
        partyId: customer.id!,
      );
      for (final advance in allAdvances) {
        events.add(
          _RawStatementEvent(
            date: advance.occurredAt,
            type: CustomerStatementEntryType.advance,
            reference: 'ADV-${advance.id}',
            description: 'Advance received',
            debitMinor: 0,
            creditMinor: advance.amountMinor,
            order: 5,
          ),
        );
        if (advance.status == AdvanceStatus.refunded) {
          final allocated = advance.allocations.fold<int>(
            0,
            (sum, item) => sum + item.amountMinor,
          );
          final leftover = advance.amountMinor - allocated;
          if (leftover > 0) {
            events.add(
              _RawStatementEvent(
                date: advance.occurredAt,
                type: CustomerStatementEntryType.refund,
                reference: 'ADV-${advance.id}',
                description: 'Advance refunded',
                debitMinor: leftover,
                creditMinor: 0,
                order: 6,
              ),
            );
          }
        }
      }
    }
    events.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date == 0 ? a.order.compareTo(b.order) : date;
    });
    var opening = 0;
    for (final event in events.where((entry) => entry.date.isBefore(start))) {
      opening += event.debitMinor - event.creditMinor;
    }
    var balance = opening;
    var invoiced = 0;
    var received = 0;
    final entries = <CustomerStatementEntry>[];
    for (final event in events.where(
      (entry) => !entry.date.isBefore(start) && !entry.date.isAfter(end),
    )) {
      balance += event.debitMinor - event.creditMinor;
      invoiced += event.debitMinor;
      if (event.type == CustomerStatementEntryType.payment ||
          event.type == CustomerStatementEntryType.advance) {
        received += event.creditMinor;
      }
      entries.add(
        CustomerStatementEntry(
          date: event.date,
          type: event.type,
          reference: event.reference,
          description: event.description,
          debitMinor: event.debitMinor,
          creditMinor: event.creditMinor,
          balanceMinor: balance,
        ),
      );
    }
    return CustomerStatementModel(
      customer: customer,
      business: business,
      from: start,
      to: end,
      openingBalanceMinor: opening,
      totalInvoicedMinor: invoiced,
      totalReceivedMinor: received,
      closingBalanceMinor: balance,
      entries: entries,
    );
  }
}

class _RawStatementEvent {
  const _RawStatementEvent({
    required this.date,
    required this.type,
    required this.reference,
    required this.description,
    required this.debitMinor,
    required this.creditMinor,
    required this.order,
  });
  final DateTime date;
  final CustomerStatementEntryType type;
  final String reference;
  final String description;
  final int debitMinor;
  final int creditMinor;
  final int order;
}
