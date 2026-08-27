import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/credit_note_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/repositories/credit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/credit_note_pdf_service.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late InvoiceRepository invoices;
  late CreditNoteRepository creditNotes;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    invoices = InvoiceRepository(database);
    creditNotes = CreditNoteRepository(database, invoices);
  });

  tearDown(() => database.close());

  test('issues a line return without rewriting the original invoice', () async {
    final invoice = await invoices.save(_invoice(totalMinor: 10000));
    final note = await creditNotes.issue(
      invoice: invoice,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Damaged goods',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: invoice.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 500,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );

    expect(note.creditNoteNumber, 'CN-0001');
    expect(note.grandTotalMinor, 5000);
    expect(note.appliedMinor, 5000);
    expect(note.items.single.invoiceItemId, invoice.items.single.id);

    final refreshed = await invoices.getById(invoice.id!);
    expect(refreshed!.calculation.grandTotalMinor, 10000);
    expect(refreshed.calculation.creditedAmountMinor, 5000);
    expect(refreshed.calculation.balanceDueMinor, 5000);
    expect(refreshed.status, InvoiceStatus.partiallyPaid);
  });

  test('rejects an over-return and a wrong password is not involved', () async {
    final invoice = await invoices.save(_invoice(totalMinor: 10000));
    await expectLater(
      creditNotes.issue(
        invoice: invoice,
        creditNoteDate: DateTime(2026, 8, 27),
        reason: 'Too much',
        returnedItems: [
          CreditNoteItemDraft(
            invoiceItem: invoice.items.single,
            originalQuantityScaled: 1000,
            returnedQuantityScaled: 2000,
            alreadyReturnedScaled: 0,
          ),
        ],
        remainder: CreditNoteRemainderAction.applyThenKeep,
      ),
      throwsArgumentError,
    );
    final refreshed = await invoices.getById(invoice.id!);
    expect(refreshed!.calculation.creditedAmountMinor, 0);
    expect(refreshed.calculation.grandTotalMinor, 10000);
  });

  test('refunds leftover credit on a paid invoice', () async {
    final invoice = await invoices.save(
      _invoice(totalMinor: 10000, paidMinor: 10000, status: InvoiceStatus.paid),
    );
    final note = await creditNotes.issue(
      invoice: invoice,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Customer returned after payment',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: invoice.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenRefund,
      refundMethod: 'UPI',
    );

    expect(note.appliedMinor, 0);
    expect(note.refundedMinor, 10000);
    expect(note.unappliedMinor, 0);
    final refreshed = await invoices.getById(invoice.id!);
    expect(refreshed!.calculation.balanceDueMinor, 0);
    expect(refreshed.calculation.creditedAmountMinor, 0);
  });

  test('keeps leftover credit and applies it to another invoice', () async {
    final source = await invoices.save(
      _invoice(
        totalMinor: 10000,
        paidMinor: 10000,
        status: InvoiceStatus.paid,
        number: 'INV-CN-SRC',
      ),
    );
    final target = await invoices.save(
      _invoice(totalMinor: 5000, number: 'INV-CN-DST'),
    );
    final note = await creditNotes.issue(
      invoice: source,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Paid in full then returned',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: source.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );

    expect(note.appliedMinor, 0);
    expect(note.unappliedMinor, 10000);

    await creditNotes.applyUnapplied(
      creditNoteId: note.id!,
      invoiceId: target.id!,
      amountMinor: 5000,
    );

    final applied = await creditNotes.getById(note.id!);
    expect(applied!.appliedMinor, 5000);
    expect(applied.unappliedMinor, 5000);

    final refreshedTarget = await invoices.getById(target.id!);
    expect(refreshedTarget!.calculation.creditedAmountMinor, 5000);
    expect(refreshedTarget.calculation.balanceDueMinor, 0);
    expect(refreshedTarget.status, InvoiceStatus.paid);

    final refreshedSource = await invoices.getById(source.id!);
    expect(refreshedSource!.calculation.grandTotalMinor, 10000);
    expect(refreshedSource.calculation.creditedAmountMinor, 0);
  });

  test(
    'subtracts credit notes from monthly sales without changing received',
    () async {
      final invoice = await invoices.save(
        _invoice(totalMinor: 12000, number: 'INV-CN-RPT'),
      );
      await creditNotes.issue(
        invoice: invoice,
        creditNoteDate: DateTime(2026, 8, 27),
        reason: 'Partial return',
        returnedItems: [
          CreditNoteItemDraft(
            invoiceItem: invoice.items.single,
            originalQuantityScaled: 1000,
            returnedQuantityScaled: 500,
            alreadyReturnedScaled: 0,
          ),
        ],
        remainder: CreditNoteRemainderAction.applyThenKeep,
      );

      final report = await invoices.watchMonthlyReport(DateTime(2026, 8)).first;
      expect(report.totalSalesMinor, 6000);
      expect(report.totalReceivedMinor, 0);
      expect(report.outstandingMinor, 6000);
    },
  );

  test('blocks delete and cancel after a credit note is issued', () async {
    final invoice = await invoices.save(
      _invoice(totalMinor: 8000, number: 'INV-CN-LOCK'),
    );
    await creditNotes.issue(
      invoice: invoice,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Keep the original invoice',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: invoice.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );

    await expectLater(invoices.cancel(invoice.id!), throwsStateError);
    await expectLater(invoices.delete(invoice.id!), throwsStateError);
    expect(await invoices.getById(invoice.id!), isNotNull);
  });

  test('renders a credit note PDF', () async {
    final invoice = await invoices.save(_invoice(totalMinor: 73600));
    final note = await creditNotes.issue(
      invoice: invoice,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Short quantity',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: invoice.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );
    final bytes = await const CreditNotePdfService().build(
      note: note,
      business: BusinessProfileModel(
        businessName: 'Creovo QA',
        currencySymbol: '₹',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect(bytes, isNotEmpty);
  });

  test('clamps a return date that is earlier than the invoice date', () {
    expect(
      CreditNoteDate.clamp(
        invoiceDate: DateTime(2026, 9, 14, 10),
        proposed: DateTime(2026, 8, 27),
        now: DateTime(2026, 8, 27),
      ),
      DateTime(2026, 9, 14),
    );
    final range = CreditNoteDate.bounds(
      invoiceDate: DateTime(2026, 9, 14),
      now: DateTime(2026, 8, 27),
    );
    expect(range.$1, DateTime(2026, 9, 14));
    expect(range.$2.isBefore(range.$1), isFalse);
  });
}

InvoiceModel _invoice({
  required int totalMinor,
  int paidMinor = 0,
  InvoiceStatus status = InvoiceStatus.unpaid,
  String? number,
}) {
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
    invoiceNumber: number ?? 'INV-CN-$totalMinor',
    customer: const CustomerSnapshotModel(customerId: 1, name: 'Rinkal Ben'),
    invoiceDate: DateTime(2026, 8, 20),
    status: status,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: 'item',
        name: 'MDF Circle',
        quantityScaled: 1000,
        unit: 'pcs',
        rateMinor: totalMinor,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: DateTime(2026, 8, 20),
    updatedAt: DateTime(2026, 8, 20),
  );
}
