import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/cash_book_models.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/expense_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/cash_book_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/expense_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late CashBookRepository cashBook;
  late InvoiceRepository invoices;
  late ExpenseRepository expenses;
  late CustomerRepository customers;
  late PurchaseRepository purchases;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    cashBook = CashBookRepository(database);
    invoices = InvoiceRepository(database);
    expenses = ExpenseRepository(database);
    customers = CustomerRepository(database);
    purchases = PurchaseRepository(database);
  });

  tearDown(() => database.close());

  test('seeds Cash, Bank, UPI, Card and Other', () async {
    final accounts = await cashBook.activeAccounts();
    expect(accounts.map((account) => account.name), [
      'Cash',
      'Bank',
      'UPI',
      'Card',
      'Other',
    ]);
  });

  test('posts invoice receipts and nets reversals to zero', () async {
    final invoice = await invoices.save(
      _invoice(number: 'INV-CB-1', totalMinor: 10000),
    );
    await invoices.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 4000,
      paidAt: DateTime(2026, 8, 28),
      method: 'UPI',
    );
    final upi = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.accountType == MoneyAccountType.upi,
    );
    expect(upi.bookMinor, 4000);
    expect(upi.availableMinor, 4000);

    final payment = (await invoices.getPayments(invoice.id!)).single;
    await invoices.reversePayment(
      invoiceId: invoice.id!,
      paymentId: payment.id!,
      reason: 'Wrong entry',
      reversedAt: DateTime(2026, 8, 28, 12),
    );
    final after = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.accountType == MoneyAccountType.upi,
    );
    expect(after.bookMinor, 0);
  });

  test('keeps a cheque pending until it is cleared', () async {
    final invoice = await invoices.save(
      _invoice(number: 'INV-CB-CHQ', totalMinor: 25000),
    );
    await invoices.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 25000,
      paidAt: DateTime(2026, 8, 28),
      method: 'Cheque',
    );
    final bank = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.accountType == MoneyAccountType.bank,
    );
    expect(bank.bookMinor, 25000);
    expect(bank.pendingMinor, 25000);
    expect(bank.availableMinor, 0);

    final movement = (await cashBook.statement(bank.id!)).single;
    await cashBook.clearCheque(movement.id);
    final cleared = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.accountType == MoneyAccountType.bank,
    );
    expect(cleared.availableMinor, 25000);
    expect(cleared.pendingMinor, 0);
  });

  test('posts expenses as cash-book outflows', () async {
    await expenses.save(
      ExpenseModel(
        expenseNumber: '',
        expenseDate: DateTime(2026, 8, 28),
        category: 'Rent',
        payee: 'Landlord',
        amountMinor: 10000,
        grandTotalMinor: 10000,
        paymentMethod: 'Cash',
        createdAt: DateTime(2026, 8, 28),
        updatedAt: DateTime(2026, 8, 28),
      ),
    );
    final cash = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    expect(cash.bookMinor, -10000);
  });

  test(
    'transfers between accounts without changing the combined book',
    () async {
      final invoice = await invoices.save(
        _invoice(number: 'INV-CB-TR', totalMinor: 5000),
      );
      await invoices.recordPayment(
        invoiceId: invoice.id!,
        amountMinor: 5000,
        paidAt: DateTime(2026, 8, 28),
        method: 'Cash',
      );
      final accounts = await cashBook.activeAccounts();
      final cash = accounts.singleWhere((account) => account.isCash);
      final bank = accounts.singleWhere(
        (account) => account.accountType == MoneyAccountType.bank,
      );
      await cashBook.transfer(
        fromAccountId: cash.id!,
        toAccountId: bank.id!,
        amountMinor: 2000,
        occurredAt: DateTime(2026, 8, 28),
        note: 'Bank deposit',
      );
      final after = await cashBook.activeAccounts();
      expect(after.singleWhere((account) => account.isCash).bookMinor, 3000);
      expect(
        after
            .singleWhere(
              (account) => account.accountType == MoneyAccountType.bank,
            )
            .bookMinor,
        2000,
      );
      expect(
        after.fold<int>(0, (sum, account) => sum + account.bookMinor),
        5000,
      );
    },
  );

  test('applies a customer advance without posting cash twice', () async {
    final customer = await customers.save(
      CustomerModel(
        name: 'Advance Client',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    final invoice = await invoices.save(
      _invoice(number: 'INV-CB-ADV', totalMinor: 8000, customerId: customer.id),
    );
    final cash = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    final advance = await cashBook.recordAdvance(
      partyType: PartyKind.customer,
      partyId: customer.id!,
      partyName: customer.name,
      accountId: cash.id!,
      amountMinor: 5000,
      occurredAt: DateTime(2026, 8, 28),
      method: 'Cash',
    );
    expect(advance.remainingMinor, 5000);
    var afterAdvance = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    expect(afterAdvance.bookMinor, 5000);

    await cashBook.allocateAdvance(
      advanceId: advance.id,
      documentId: invoice.id!,
      amountMinor: 5000,
    );
    afterAdvance = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    expect(afterAdvance.bookMinor, 5000);
    final updated = await invoices.getById(invoice.id!);
    expect(updated!.calculation.paidAmountMinor, 5000);
    expect(updated.calculation.balanceDueMinor, 3000);
  });

  test('records a cash closing difference as an adjustment', () async {
    final invoice = await invoices.save(
      _invoice(number: 'INV-CB-CLOSE', totalMinor: 10000),
    );
    await invoices.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 10000,
      paidAt: DateTime(2026, 8, 28),
      method: 'Cash',
    );
    final cash = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    final closing = await cashBook.closeCash(
      accountId: cash.id!,
      date: DateTime(2026, 8, 28),
      countedMinor: 9800,
      note: 'Short by 2',
    );
    expect(closing.differenceMinor, -200);
    final after = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.isCash,
    );
    expect(after.availableMinor, 9800);
  });

  test('purchase payments reduce the paying account', () async {
    final supplier = await purchases.saveSupplier(
      SupplierModel(
        name: 'Paper Co',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    final billId = await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-CB-1',
        supplierId: supplier.id!,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 15),
        items: [
          PurchaseItemModel(
            name: 'Paper',
            quantity: 1,
            unit: 'ream',
            rateMinor: 4000,
          ),
        ],
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
      ),
    );
    await purchases.recordPayment(
      billId,
      4000,
      method: 'Bank transfer',
      paidAt: DateTime(2026, 8, 28),
    );
    final bank = (await cashBook.activeAccounts()).singleWhere(
      (account) => account.accountType == MoneyAccountType.bank,
    );
    expect(bank.bookMinor, -4000);
  });
}

InvoiceModel _invoice({
  required String number,
  required int totalMinor,
  int? customerId,
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
      paidAmountMinor: 0,
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
    invoiceNumber: number,
    customer: CustomerSnapshotModel(
      customerId: customerId,
      name: 'Client',
      companyName: 'Studio',
    ),
    invoiceDate: DateTime(2026, 8, 20),
    status: InvoiceStatus.unpaid,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [item],
    charges: const [],
    calculation: calculation,
    createdAt: DateTime(2026, 8, 20),
    updatedAt: DateTime(2026, 8, 20),
  );
}
