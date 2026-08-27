import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/app/localization/app_localization.dart';
import 'package:creovo_invoice/data/models/ageing_model.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/ageing_service.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late InvoiceRepository invoices;
  late CustomerRepository customers;
  late PurchaseRepository purchases;
  late AgeingService service;
  late List<ShareParams> shared;
  late ShareResultStatus shareStatus;

  final asOf = DateTime(2026, 8, 27);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    invoices = InvoiceRepository(database);
    customers = CustomerRepository(database);
    purchases = PurchaseRepository(database);
    shared = [];
    shareStatus = ShareResultStatus.success;
    service = AgeingService(
      BusinessRepository(database),
      invoices,
      customers,
      purchases,
      await AppStorage.create(),
      shareImpl: (params) async {
        shared.add(params);
        return ShareResult('ok', shareStatus);
      },
    );
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo QA',
        upiId: 'creovo@upi',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  tearDown(() => database.close());

  test('buckets split not due, 1–30, 31–60, 61–90, and 90+', () {
    expect(AgeingMath.bucketFor(0), AgeingBucket.notDue);
    expect(AgeingMath.bucketFor(-3), AgeingBucket.notDue);
    expect(AgeingMath.bucketFor(1), AgeingBucket.d1to30);
    expect(AgeingMath.bucketFor(30), AgeingBucket.d1to30);
    expect(AgeingMath.bucketFor(31), AgeingBucket.d31to60);
    expect(AgeingMath.bucketFor(60), AgeingBucket.d31to60);
    expect(AgeingMath.bucketFor(61), AgeingBucket.d61to90);
    expect(AgeingMath.bucketFor(90), AgeingBucket.d61to90);
    expect(AgeingMath.bucketFor(91), AgeingBucket.d90plus);
  });

  test(
    'groups open invoices and bills and skips drafts, paid, cancelled',
    () async {
      final customer = await customers.save(
        CustomerModel(
          name: 'Rinkal Ben',
          mobile: '9876543210',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'INV-DUE',
          date: DateTime(2026, 8, 10),
          due: DateTime(2026, 8, 15),
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'INV-FUTURE',
          date: DateTime(2026, 8, 20),
          due: DateTime(2026, 9, 10),
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'INV-OLD',
          date: DateTime(2026, 4, 1),
          due: DateTime(2026, 5, 1),
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'INV-DRAFT',
          date: DateTime(2026, 8, 1),
          due: DateTime(2026, 8, 1),
          status: InvoiceStatus.draft,
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'INV-PAID',
          date: DateTime(2026, 8, 1),
          due: DateTime(2026, 8, 1),
          paid: true,
        ),
      );
      await invoices.save(
        _invoice(
          customer: customer,
          number: 'QT-1',
          date: DateTime(2026, 8, 1),
          due: DateTime(2026, 8, 1),
          documentType: DocumentType.quotation,
        ),
      );
      final supplier = await purchases.saveSupplier(
        SupplierModel(
          name: 'Plywood House',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      await purchases.saveBill(
        _bill(
          supplier: supplier,
          number: 'PB-OPEN',
          date: DateTime(2026, 8, 1),
          due: DateTime(2026, 8, 10),
        ),
      );
      final cancelledId = await purchases.saveBill(
        _bill(
          supplier: supplier,
          number: 'PB-CANCEL',
          date: DateTime(2026, 8, 1),
          due: DateTime(2026, 8, 10),
        ),
      );
      await purchases.cancelBill(cancelledId, reason: 'Duplicate');

      final pack = await service.build(asOf: asOf);
      expect(
        pack.receivables.map((row) => row.documentNumber),
        unorderedEquals(['INV-DUE', 'INV-FUTURE', 'INV-OLD']),
      );
      expect(pack.payables.map((row) => row.documentNumber), ['PB-OPEN']);
      expect(
        pack.receivables
            .firstWhere((row) => row.documentNumber == 'INV-DUE')
            .bucket,
        AgeingBucket.d1to30,
      );
      expect(
        pack.receivables
            .firstWhere((row) => row.documentNumber == 'INV-FUTURE')
            .bucket,
        AgeingBucket.notDue,
      );
      expect(
        pack.receivables
            .firstWhere((row) => row.documentNumber == 'INV-OLD')
            .bucket,
        AgeingBucket.d90plus,
      );
      expect(pack.payables.single.bucket, AgeingBucket.d1to30);
      expect(
        pack.receivables
            .singleWhere((row) => row.documentNumber == 'INV-DUE')
            .partyMobile,
        '9876543210',
      );
    },
  );

  test('reminder text is Prepared and never claims Delivered', () async {
    final customer = await customers.save(
      CustomerModel(
        name: 'Rinkal Ben',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await invoices.save(
      _invoice(
        customer: customer,
        number: 'INV-DUE',
        date: DateTime(2026, 8, 10),
        due: DateTime(2026, 8, 15),
      ),
    );
    final pack = await service.build(asOf: asOf);
    final row = pack.receivables.single;
    final english = service.composeDocument(row, pack);
    expect(english, contains('Payment reminder'));
    expect(english, contains('INV-DUE'));
    expect(english, contains('Prepared'));
    expect(english, isNot(contains(AgeingPack.deliveryClaim)));
    expect(english, contains('creovo@upi'));

    final hindi = service.composeDocument(
      row,
      pack,
      language: AppLanguage.hindi,
    );
    expect(hindi, contains('अनुस्मारक'));
    expect(hindi, isNot(contains(AgeingPack.deliveryClaim)));
    expect(AgeingPack.deliveryClaim, 'Delivered');

    final bucket = service.composeBucket(pack.receivables, pack);
    expect(bucket, contains('INV-DUE'));
    expect(bucket, isNot(contains(AgeingPack.deliveryClaim)));
  });

  test('share success is Shared and dismiss is Skipped', () async {
    final customer = await customers.save(
      CustomerModel(
        name: 'Rinkal Ben',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await invoices.save(
      _invoice(
        customer: customer,
        number: 'INV-DUE',
        date: DateTime(2026, 8, 10),
        due: DateTime(2026, 8, 15),
      ),
    );
    var pack = await service.build(asOf: asOf);
    expect(
      await service.shareDocument(pack.receivables.single, pack),
      AgeingReminderStatus.shared,
    );
    pack = await service.build(asOf: asOf);
    expect(pack.receivables.single.reminderStatus, AgeingReminderStatus.shared);
    expect(shared, isNotEmpty);
    expect(shared.last.text, contains('INV-DUE'));

    shareStatus = ShareResultStatus.dismissed;
    expect(
      await service.shareDocument(pack.receivables.single, pack),
      AgeingReminderStatus.skipped,
    );
    pack = await service.build(asOf: asOf);
    expect(
      pack.receivables.single.reminderStatus,
      AgeingReminderStatus.skipped,
    );
    expect(
      AgeingService.statusFromShare(ShareResultStatus.unavailable),
      AgeingReminderStatus.prepared,
    );
  });
}

InvoiceModel _invoice({
  required CustomerModel customer,
  required String number,
  required DateTime date,
  required DateTime due,
  InvoiceStatus status = InvoiceStatus.unpaid,
  DocumentType documentType = DocumentType.invoice,
  bool paid = false,
}) {
  const calculator = InvoiceCalculationService();
  final calculation = calculator.calculate(
    InvoiceCalculationInput(
      taxType: TaxType.none,
      paidAmountMinor: paid ? 10000 : 0,
      items: const [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 1000,
          rateMinor: 10000,
        ),
      ],
    ),
  );
  return InvoiceModel(
    documentType: documentType,
    invoiceNumber: number,
    customer: CustomerSnapshotModel(
      customerId: customer.id,
      name: customer.name,
    ),
    invoiceDate: date,
    dueDate: due,
    status: paid ? InvoiceStatus.paid : status,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: const [
      InvoiceItemModel(
        localId: 'item',
        name: 'MDF Circle',
        quantityScaled: 1000,
        unit: 'pcs',
        rateMinor: 10000,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: date,
    updatedAt: date,
  );
}

PurchaseBillModel _bill({
  required SupplierModel supplier,
  required String number,
  required DateTime date,
  required DateTime due,
}) {
  return PurchaseBillModel(
    billNumber: number,
    supplierId: supplier.id!,
    supplierName: supplier.name,
    billDate: date,
    dueDate: due,
    items: const [
      PurchaseItemModel(
        name: 'Plywood',
        quantity: 1,
        unit: 'sheet',
        rateMinor: 50000,
      ),
    ],
    createdAt: date,
    updatedAt: date,
  );
}
