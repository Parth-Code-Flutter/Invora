import '../../app/enums/invoice_status.dart';
import '../models/business_profile_model.dart';
import '../models/customer_model.dart';
import '../models/customer_statement_model.dart';
import '../repositories/invoice_repository.dart';

class CustomerStatementService {
  const CustomerStatementService(this._invoices);

  final InvoiceRepository _invoices;

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
      received += event.creditMinor;
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
