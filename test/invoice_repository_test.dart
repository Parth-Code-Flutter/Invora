import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invora/app/enums/invoice_status.dart';
import 'package:invora/app/enums/tax_type.dart';
import 'package:invora/data/models/invoice_calculation_models.dart';
import 'package:invora/data/models/invoice_model.dart';
import 'package:invora/data/repositories/invoice_repository.dart';
import 'package:invora/data/services/app_database.dart';
import 'package:invora/data/services/invoice_calculation_service.dart';

void main() {
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
}

InvoiceModel _invoice({
  required String number,
  required String customer,
  required String company,
  required int totalMinor,
  required InvoiceStatus status,
  required DateTime date,
  DateTime? dueDate,
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
    customer: CustomerSnapshotModel(name: customer, companyName: company),
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
