import '../../data/models/invoice_model.dart';

/// Opens Documents on Sales or Purchases without mixing records.
class DocumentsOpenArgs {
  const DocumentsOpenArgs({
    this.purchases = false,
    this.invoiceFilter,
    this.billFilter,
  });

  final bool purchases;
  final InvoiceListFilter? invoiceFilter;
  final String? billFilter;
}

/// Opens Parties on Customers or Suppliers.
class PartiesOpenArgs {
  const PartiesOpenArgs({this.suppliers = false});

  final bool suppliers;
}
