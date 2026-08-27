import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/credit_note_model.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/customer_statement_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/repositories/credit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/customer_statement_pdf_service.dart';
import 'package:creovo_invoice/data/services/customer_statement_service.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'calculates opening, invoices, payments, reversals and closing',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final customers = CustomerRepository(database);
      final invoices = InvoiceRepository(database);
      final customer = await customers.save(
        CustomerModel(
          name: 'Rinkal Ben',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      );
      final before = await invoices.save(
        _invoice(customer, 'INV-OLD', DateTime(2025, 12, 20), 10000),
      );
      await invoices.recordPayment(
        invoiceId: before.id!,
        amountMinor: 3000,
        paidAt: DateTime(2025, 12, 25),
      );
      final current = await invoices.save(
        _invoice(customer, 'INV-JAN', DateTime(2026, 1, 10), 20000),
      );
      await invoices.recordPayment(
        invoiceId: current.id!,
        amountMinor: 5000,
        paidAt: DateTime(2026, 1, 12),
        method: 'UPI',
      );
      final payment = (await invoices.getPayments(current.id!)).single;
      await invoices.reversePayment(
        invoiceId: current.id!,
        paymentId: payment.id!,
        reason: 'Returned',
        reversedAt: DateTime(2026, 1, 13),
      );
      final cancelled = await invoices.save(
        _invoice(customer, 'INV-CANCEL', DateTime(2026, 1, 14), 90000),
      );
      await invoices.cancel(cancelled.id!);

      final creditNotes = CreditNoteRepository(database, invoices);
      final statement = await CustomerStatementService(invoices, creditNotes)
          .build(
            customer: customer,
            business: BusinessProfileModel(
              businessName: 'Creovo Creations',
              currencySymbol: '₹',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
            from: DateTime(2026, 1),
            to: DateTime(2026, 1, 31),
          );

      expect(statement.openingBalanceMinor, 7000);
      expect(statement.totalInvoicedMinor, 25000);
      expect(statement.totalReceivedMinor, 5000);
      expect(statement.closingBalanceMinor, 27000);
      expect(statement.entries.map((entry) => entry.type), [
        CustomerStatementEntryType.invoice,
        CustomerStatementEntryType.payment,
        CustomerStatementEntryType.reversal,
      ]);
      final pdf = await const CustomerStatementPdfService().build(statement);
      expect(pdf, isNotEmpty);
    },
  );

  test('includes credit notes and refunds in the customer statement', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final customers = CustomerRepository(database);
    final invoices = InvoiceRepository(database);
    final creditNotes = CreditNoteRepository(database, invoices);
    final customer = await customers.save(
      CustomerModel(
        name: 'Rinkal Ben',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final invoice = await invoices.save(
      _invoice(customer, 'INV-CN', DateTime(2026, 8, 20), 10000),
    );
    await invoices.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 10000,
      paidAt: DateTime(2026, 8, 21),
      method: 'UPI',
    );
    final paid = await invoices.getById(invoice.id!);
    await creditNotes.issue(
      invoice: paid!,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Returned after payment',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: paid.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenRefund,
      refundMethod: 'UPI',
    );

    final statement = await CustomerStatementService(invoices, creditNotes)
        .build(
          customer: customer,
          business: BusinessProfileModel(
            businessName: 'Creovo Creations',
            currencySymbol: '₹',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          from: DateTime(2026, 8),
          to: DateTime(2026, 8, 31),
        );

    expect(statement.entries.map((entry) => entry.type), [
      CustomerStatementEntryType.invoice,
      CustomerStatementEntryType.payment,
      CustomerStatementEntryType.creditNote,
      CustomerStatementEntryType.refund,
    ]);
    expect(statement.closingBalanceMinor, 0);
    expect(statement.totalReceivedMinor, 10000);
  });
}

InvoiceModel _invoice(
  CustomerModel customer,
  String number,
  DateTime date,
  int total,
) {
  const item = InvoiceItemModel(
    localId: 'item',
    name: 'Service',
    quantityScaled: 1000,
    unit: 'service',
    rateMinor: 10000,
  );
  final calculation = const InvoiceCalculationService().calculate(
    InvoiceCalculationInput(
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 1000,
          rateMinor: total,
        ),
      ],
      taxType: TaxType.none,
    ),
  );
  return InvoiceModel(
    invoiceNumber: number,
    customer: CustomerSnapshotModel.fromCustomer(customer),
    invoiceDate: date,
    status: InvoiceStatus.unpaid,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: item.localId,
        name: item.name,
        quantityScaled: item.quantityScaled,
        unit: item.unit,
        rateMinor: total,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: date,
    updatedAt: date,
  );
}
