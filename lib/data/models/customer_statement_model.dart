import 'business_profile_model.dart';
import 'customer_model.dart';

enum CustomerStatementEntryType {
  invoice,
  payment,
  reversal,
  creditNote,
  refund,
}

class CustomerStatementEntry {
  const CustomerStatementEntry({
    required this.date,
    required this.type,
    required this.reference,
    required this.description,
    required this.debitMinor,
    required this.creditMinor,
    required this.balanceMinor,
  });

  final DateTime date;
  final CustomerStatementEntryType type;
  final String reference;
  final String description;
  final int debitMinor;
  final int creditMinor;
  final int balanceMinor;
}

class CustomerStatementModel {
  const CustomerStatementModel({
    required this.customer,
    required this.business,
    required this.from,
    required this.to,
    required this.openingBalanceMinor,
    required this.totalInvoicedMinor,
    required this.totalReceivedMinor,
    required this.closingBalanceMinor,
    required this.entries,
  });

  final CustomerModel customer;
  final BusinessProfileModel business;
  final DateTime from;
  final DateTime to;
  final int openingBalanceMinor;
  final int totalInvoicedMinor;
  final int totalReceivedMinor;
  final int closingBalanceMinor;
  final List<CustomerStatementEntry> entries;
}
