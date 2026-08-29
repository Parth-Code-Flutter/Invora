import '../models/data_import_models.dart';

abstract final class DataImportTemplates {
  static const customers = ImportTemplate(
    kind: DataImportKind.customers,
    title: 'Customers',
    subtitle: 'Parties you sell to — name, mobile, GSTIN and address',
    fileName: 'creovo_import_customers.csv',
    columns: [
      ImportColumnSpec(
        key: 'name',
        header: 'Name',
        aliases: ['customer name', 'party name', 'customer'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'company',
        header: 'Company',
        aliases: ['company name'],
      ),
      ImportColumnSpec(
        key: 'mobile',
        header: 'Mobile',
        aliases: ['phone', 'contact'],
      ),
      ImportColumnSpec(key: 'email', header: 'Email'),
      ImportColumnSpec(
        key: 'gstin',
        header: 'GSTIN',
        aliases: ['gst no', 'gstin no'],
      ),
      ImportColumnSpec(key: 'address', header: 'Address'),
      ImportColumnSpec(key: 'city', header: 'City'),
      ImportColumnSpec(key: 'state', header: 'State'),
      ImportColumnSpec(
        key: 'pin',
        header: 'PIN code',
        aliases: ['pincode', 'pin'],
      ),
      ImportColumnSpec(key: 'notes', header: 'Notes'),
    ],
    sample: [
      [
        'Sharma Traders',
        'Sharma Traders',
        '9876543210',
        'shop@example.com',
        '27AAPFU0939F1ZV',
        '12 MG Road',
        'Pune',
        'Maharashtra',
        '411001',
        'Preferred customer',
      ],
    ],
  );

  static const suppliers = ImportTemplate(
    kind: DataImportKind.suppliers,
    title: 'Suppliers',
    subtitle: 'Parties you buy from — name, mobile, GSTIN and address',
    fileName: 'creovo_import_suppliers.csv',
    columns: [
      ImportColumnSpec(
        key: 'name',
        header: 'Name',
        aliases: ['supplier name', 'party name', 'vendor'],
        required: true,
      ),
      ImportColumnSpec(key: 'company', header: 'Company'),
      ImportColumnSpec(key: 'mobile', header: 'Mobile', aliases: ['phone']),
      ImportColumnSpec(key: 'email', header: 'Email'),
      ImportColumnSpec(key: 'gstin', header: 'GSTIN'),
      ImportColumnSpec(key: 'address', header: 'Address'),
    ],
    sample: [
      [
        'National Distributors',
        'National Distributors',
        '9123456780',
        '',
        '24AAACC1206D1ZM',
        'Andheri East, Mumbai',
      ],
    ],
  );

  static const products = ImportTemplate(
    kind: DataImportKind.products,
    title: 'Products & services',
    subtitle:
        'Catalog name, type, unit, sale price, HSN/SAC, GST and opening stock',
    fileName: 'creovo_import_products.csv',
    columns: [
      ImportColumnSpec(
        key: 'name',
        header: 'Name',
        aliases: ['item name', 'product name'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'type',
        header: 'Type',
        aliases: ['item type', 'product/service'],
      ),
      ImportColumnSpec(key: 'description', header: 'Description'),
      ImportColumnSpec(key: 'unit', header: 'Unit'),
      ImportColumnSpec(
        key: 'price',
        header: 'Sale price',
        aliases: ['price', 'rate', 'selling price'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'hsn',
        header: 'HSN/SAC',
        aliases: ['hsn', 'sac', 'hsn sac'],
      ),
      ImportColumnSpec(
        key: 'gst',
        header: 'GST rate',
        aliases: ['gst', 'tax rate', 'gst %'],
      ),
      ImportColumnSpec(
        key: 'stock',
        header: 'Opening stock',
        aliases: ['stock', 'qty', 'quantity', 'opening qty'],
      ),
    ],
    sample: [
      ['Notebook A5', 'Product', '70 page', 'Pcs', '40.00', '4820', '18', '12'],
    ],
  );

  static const unpaidInvoices = ImportTemplate(
    kind: DataImportKind.unpaidInvoices,
    title: 'Unpaid sales invoices',
    subtitle: 'Outstanding invoices from another app — one row per invoice',
    fileName: 'creovo_import_unpaid_invoices.csv',
    columns: [
      ImportColumnSpec(
        key: 'customerName',
        header: 'Customer name',
        aliases: ['customer', 'party name', 'name'],
        required: true,
      ),
      ImportColumnSpec(key: 'mobile', header: 'Mobile'),
      ImportColumnSpec(key: 'gstin', header: 'GSTIN'),
      ImportColumnSpec(
        key: 'invoiceNumber',
        header: 'Invoice number',
        aliases: ['invoice no', 'bill no', 'number'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'date',
        header: 'Date',
        aliases: ['invoice date'],
        required: true,
      ),
      ImportColumnSpec(key: 'dueDate', header: 'Due date'),
      ImportColumnSpec(
        key: 'itemName',
        header: 'Item name',
        aliases: ['item', 'description'],
      ),
      ImportColumnSpec(key: 'quantity', header: 'Quantity', aliases: ['qty']),
      ImportColumnSpec(
        key: 'amount',
        header: 'Taxable value',
        aliases: ['amount', 'taxable', 'rate', 'grand total', 'total'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'gst',
        header: 'GST rate',
        aliases: ['gst', 'tax rate'],
      ),
      ImportColumnSpec(key: 'hsn', header: 'HSN/SAC'),
      ImportColumnSpec(
        key: 'taxMode',
        header: 'Tax mode',
        aliases: ['gst type', 'tax type'],
      ),
      ImportColumnSpec(key: 'notes', header: 'Notes'),
    ],
    sample: [
      [
        'Sharma Traders',
        '9876543210',
        '27AAPFU0939F1ZV',
        'INV-0042',
        '2026-04-01',
        '2026-04-15',
        'Opening balance',
        '1',
        '11800.00',
        '18',
        '9983',
        'CGST+SGST',
        'Migrated from previous software',
      ],
    ],
  );

  static const unpaidBills = ImportTemplate(
    kind: DataImportKind.unpaidBills,
    title: 'Unpaid purchase bills',
    subtitle: 'Outstanding supplier bills — one row per bill',
    fileName: 'creovo_import_unpaid_bills.csv',
    columns: [
      ImportColumnSpec(
        key: 'supplierName',
        header: 'Supplier name',
        aliases: ['supplier', 'vendor', 'party name', 'name'],
        required: true,
      ),
      ImportColumnSpec(key: 'mobile', header: 'Mobile'),
      ImportColumnSpec(key: 'gstin', header: 'GSTIN'),
      ImportColumnSpec(
        key: 'billNumber',
        header: 'Bill number',
        aliases: ['bill no', 'invoice number', 'number'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'date',
        header: 'Date',
        aliases: ['bill date'],
        required: true,
      ),
      ImportColumnSpec(key: 'dueDate', header: 'Due date'),
      ImportColumnSpec(key: 'itemName', header: 'Item name', aliases: ['item']),
      ImportColumnSpec(key: 'quantity', header: 'Quantity', aliases: ['qty']),
      ImportColumnSpec(
        key: 'amount',
        header: 'Taxable value',
        aliases: ['amount', 'taxable', 'total', 'grand total'],
        required: true,
      ),
      ImportColumnSpec(key: 'gst', header: 'GST rate'),
      ImportColumnSpec(key: 'hsn', header: 'HSN/SAC'),
      ImportColumnSpec(key: 'notes', header: 'Notes'),
    ],
    sample: [
      [
        'National Distributors',
        '9123456780',
        '24AAACC1206D1ZM',
        'ND-8891',
        '15/03/2026',
        '30/03/2026',
        'Opening balance',
        '1',
        '5000.00',
        '18',
        '4820',
        '',
      ],
    ],
  );

  static const openingBalances = ImportTemplate(
    kind: DataImportKind.openingBalances,
    title: 'Opening balances',
    subtitle:
        'Party receivable or payable as of a date. Opening stock keeps stock for that product.',
    fileName: 'creovo_import_opening_balances.csv',
    columns: [
      ImportColumnSpec(
        key: 'partyType',
        header: 'Party type',
        aliases: ['type', 'customer/supplier'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'name',
        header: 'Name',
        aliases: ['party name', 'customer', 'supplier'],
        required: true,
      ),
      ImportColumnSpec(key: 'mobile', header: 'Mobile'),
      ImportColumnSpec(key: 'gstin', header: 'GSTIN'),
      ImportColumnSpec(
        key: 'date',
        header: 'As of date',
        aliases: ['date'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'amount',
        header: 'Opening amount',
        aliases: ['amount', 'balance', 'receivable', 'payable'],
        required: true,
      ),
      ImportColumnSpec(
        key: 'reference',
        header: 'Reference',
        aliases: ['invoice number', 'bill number'],
      ),
      ImportColumnSpec(
        key: 'stock',
        header: 'Opening stock',
        aliases: ['stock', 'qty', 'quantity'],
      ),
      ImportColumnSpec(key: 'notes', header: 'Notes'),
    ],
    sample: [
      [
        'Customer',
        'Sharma Traders',
        '9876543210',
        '',
        '01/04/2026',
        '12,500.00',
        'OB-001',
        '',
        'Brought forward',
      ],
    ],
  );

  static const all = [
    customers,
    suppliers,
    products,
    unpaidInvoices,
    unpaidBills,
    openingBalances,
  ];

  static ImportTemplate of(DataImportKind kind) =>
      all.firstWhere((template) => template.kind == kind);
}
