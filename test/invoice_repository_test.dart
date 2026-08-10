import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/services/invoice_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late InvoiceRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = InvoiceRepository(database);
  });

  tearDown(() => database.close());

  test('searches, filters and sorts offline invoice summaries', () async {
    await repository.save(
      _invoice(
        number: 'INV-0001',
        customer: 'Aarav Shah',
        company: 'Northwind',
        totalMinor: 10000,
        status: InvoiceStatus.unpaid,
        date: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 1, 10),
      ),
    );
    await repository.save(
      _invoice(
        number: 'INV-0002',
        customer: 'Meera Patel',
        company: 'Contoso',
        totalMinor: 50000,
        status: InvoiceStatus.paid,
        date: DateTime(2026, 2, 1),
      ),
    );

    expect(
      (await repository.watchSummaries(query: 'northwind').first)
          .single
          .invoiceNumber,
      'INV-0001',
    );
    expect(
      (await repository.watchSummaries(filter: InvoiceListFilter.overdue).first)
          .single
          .customerName,
      'Aarav Shah',
    );
    expect(
      (await repository.watchSummaries(sort: InvoiceSort.highestAmount).first)
          .first
          .invoiceNumber,
      'INV-0002',
    );
    expect(
      await repository.nextInvoiceNumber(prefix: 'INV', startingNumber: 1),
      'INV-0003',
    );
  });

  test('manages payments and converts an accepted quotation', () async {
    final now = DateTime.now();
    final invoice = await repository.save(
      _invoice(
        number: 'INV-0100',
        customer: 'Dev Shah',
        company: 'Dev & Sons',
        totalMinor: 25000,
        status: InvoiceStatus.unpaid,
        date: now,
      ),
    );
    await repository.updatePayment(invoice.id!, 10000);
    final updated = await repository.getById(invoice.id!);
    expect(updated?.status, InvoiceStatus.partiallyPaid);
    expect(updated?.calculation.balanceDueMinor, 15000);
    var payments = await repository.getPayments(invoice.id!);
    expect(payments.single.amountMinor, 10000);
    expect(payments.single.method, 'Adjustment');

    await repository.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 5000,
      paidAt: now,
      method: 'UPI',
      reference: 'UPI-123',
      note: 'Second instalment',
    );
    payments = await repository.getPayments(invoice.id!);
    expect(payments, hasLength(2));
    final upiPayment = payments.singleWhere(
      (payment) => payment.method == 'UPI',
    );
    expect(upiPayment.reference, 'UPI-123');
    expect(
      (await repository.getById(invoice.id!))?.calculation.balanceDueMinor,
      10000,
    );

    final quotation = await repository.save(
      _invoice(
        number: 'QTN-0001',
        customer: 'Mira',
        company: 'Mira Studio',
        totalMinor: 50000,
        status: InvoiceStatus.sent,
        date: now,
        documentType: DocumentType.quotation,
      ),
    );
    final converted = await repository.convertQuotationToInvoice(
      quotationId: quotation.id!,
      invoiceNumber: 'INV-0101',
    );
    expect(converted.documentType, DocumentType.invoice);
    expect(converted.status, InvoiceStatus.unpaid);
    expect(
      (await repository.getById(quotation.id!))?.status,
      InvoiceStatus.accepted,
    );
    expect(
      (await repository
              .watchSummaries(documentType: DocumentType.quotation)
              .first)
          .single
          .invoiceNumber,
      'QTN-0001',
    );
    final report = await repository.watchCurrentMonthReport().first;
    expect(report.invoiceCount, 2);
    expect(report.totalSalesMinor, 75000);
    expect(
      const InvoicePdfService().fileName(converted),
      'Invoice_INV-0101_Mira-Studio.pdf',
    );
  });

  test(
    'creates an opening ledger entry for an initially paid amount',
    () async {
      final invoice = await repository.save(
        _invoice(
          number: 'INV-OPENING',
          customer: 'Opening Client',
          company: 'Opening Studio',
          totalMinor: 20000,
          paidMinor: 7500,
          status: InvoiceStatus.partiallyPaid,
          date: DateTime(2026, 8, 11),
        ),
      );

      final payments = await repository.getPayments(invoice.id!);
      expect(payments, hasLength(1));
      expect(payments.single.amountMinor, 7500);
      expect(payments.single.method, 'Opening payment');
      expect(invoice.calculation.balanceDueMinor, 12500);
    },
  );

  test('builds reports for a selected historical month', () async {
    await repository.save(
      _invoice(
        number: 'INV-JAN',
        customer: 'January Client',
        company: 'January Studio',
        totalMinor: 12000,
        status: InvoiceStatus.unpaid,
        date: DateTime(2025, 1, 12),
      ),
    );
    await repository.save(
      _invoice(
        number: 'INV-FEB',
        customer: 'February Client',
        company: 'February Studio',
        totalMinor: 34000,
        status: InvoiceStatus.paid,
        date: DateTime(2025, 2, 8),
      ),
    );

    final january = await repository
        .watchMonthlyReport(DateTime(2025, 1))
        .first;

    expect(january.invoiceCount, 1);
    expect(january.totalSalesMinor, 12000);
    expect(january.pendingCount, 1);
    expect(january.monthlySales.last.month, DateTime(2025, 1));
    expect(january.monthlySales.last.amountMinor, 12000);
  });

  test('renders every PDF template with the INR Unicode font', () async {
    final now = DateTime(2026, 8, 11);
    final invoice = _invoice(
      number: 'INV-PDF-1',
      customer: 'Rinkal Ben',
      company: 'MDF Collections',
      totalMinor: 73600,
      status: InvoiceStatus.unpaid,
      date: now,
    );
    final business = BusinessProfileModel(
      businessName: 'MDF Collections',
      ownerName: 'Mira Patel',
      mobile: '9876543210',
      email: 'billing@mdf.example',
      address: '14 Workshop Road',
      city: 'Surat',
      state: 'Gujarat',
      pinCode: '395003',
      gstRegistered: true,
      gstin: '24ABCDE1234F1Z5',
      pan: 'ABCDE1234F',
      currencySymbol: '₹',
      createdAt: now,
      updatedAt: now,
    );
    const service = InvoicePdfService();

    for (final template in InvoiceTemplate.values) {
      final bytes = await service.build(
        invoice: invoice,
        business: business,
        template: template,
      );
      expect(bytes, isNotEmpty, reason: '${template.label} must render');
    }
  });
}

InvoiceModel _invoice({
  required String number,
  required String customer,
  required String company,
  required int totalMinor,
  int paidMinor = 0,
  required InvoiceStatus status,
  required DateTime date,
  DateTime? dueDate,
  DocumentType documentType = DocumentType.invoice,
}) {
  final item = InvoiceItemModel(
    localId: number,
    name: 'Consulting',
    quantityScaled: 1000,
    unit: 'service',
    rateMinor: totalMinor,
  );
  final calculation = const InvoiceCalculationService().calculate(
    InvoiceCalculationInput(
      paidAmountMinor: paidMinor,
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 1000,
          rateMinor: totalMinor,
        ),
      ],
    ),
  );
  return InvoiceModel(
    documentType: documentType,
    invoiceNumber: number,
    customer: CustomerSnapshotModel(
      name: customer,
      companyName: company,
      mobile: '9123456789',
      email: 'accounts@customer.example',
      address: '22 Market Street',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pinCode: '380001',
      gstin: '24AAACC1206D1ZM',
    ),
    invoiceDate: date,
    dueDate: dueDate,
    status: status,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [item],
    charges: const [],
    calculation: calculation,
    createdAt: date,
    updatedAt: date,
  );
}
