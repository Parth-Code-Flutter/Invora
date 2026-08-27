import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/credit_note_model.dart';
import 'package:creovo_invoice/data/models/gst_export_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/credit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/gst_export_service.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late GstExportService service;
  late InvoiceRepository invoices;
  late CreditNoteRepository creditNotes;
  late PurchaseRepository purchases;

  final period = GstExportPeriod(
    from: DateTime(2026, 8, 1),
    to: DateTime(2026, 8, 31),
    preset: GstExportPeriodPreset.custom,
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    invoices = InvoiceRepository(database);
    creditNotes = CreditNoteRepository(database, invoices);
    purchases = PurchaseRepository(database);
    service = GstExportService(
      BusinessRepository(database),
      invoices,
      creditNotes,
      purchases,
    );
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo QA',
        gstin: '24AAAAA0000A1Z5',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  tearDown(() => database.close());

  test('Indian FY starts on 1 April', () {
    expect(
      GstExportPeriod.financialYearStart(DateTime(2026, 8, 27)),
      DateTime(2026, 4, 1),
    );
    expect(
      GstExportPeriod.financialYearStart(DateTime(2026, 3, 31)),
      DateTime(2025, 4, 1),
    );
    final last = GstExportPeriod.fromPreset(
      GstExportPeriodPreset.lastFy,
      now: DateTime(2026, 8, 27),
    );
    expect(last.from, DateTime(2025, 4, 1));
    expect(last.to, DateTime(2026, 3, 31));
  });

  test('classifies B2B vs B2C and never labels the pack Submitted', () async {
    await invoices.save(
      _invoice(number: 'INV-B2B', gstin: '24ABCDE1234F1Z5', hsnSac: '9403'),
    );
    await invoices.save(
      _invoice(number: 'INV-B2C', gstin: null, hsnSac: '9403'),
    );
    await invoices.save(
      _invoice(number: 'INV-SHORT', gstin: '24ABCDE', hsnSac: '9403'),
    );
    await invoices.save(
      _invoice(
        number: 'INV-DRAFT',
        gstin: '24ABCDE1234F1Z5',
        status: InvoiceStatus.draft,
      ),
    );
    await invoices.save(
      _invoice(
        number: 'INV-QUOTE',
        gstin: '24ABCDE1234F1Z5',
        documentType: DocumentType.quotation,
        status: InvoiceStatus.sent,
      ),
    );

    final pack = await service.build(period);
    expect(GstExportPack.filingStatus, 'Prepared');
    expect(GstExportPack.portalStatus, 'Not submitted');
    expect(pack.summary.invoiceCount, 3);
    expect(pack.summary.b2bCount, 1);
    expect(pack.summary.b2cCount, 2);
    expect(
      pack.sales
          .singleWhere((row) => row.invoiceNumber == 'INV-B2B')
          .supplyType,
      GstSupplyType.b2b,
    );
    expect(
      pack.exceptions.any((item) => item.documentNumber == 'INV-SHORT'),
      isTrue,
    );

    final csv = await service.buildCsv(GstExportKind.sales, pack);
    final text = utf8.decode(csv.bytes);
    expect(csv.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(text, contains('Invoice number'));
    expect(text, contains('Prepared'));
    expect(text, isNot(contains('Submitted')));
  });

  test('includes credit notes and looks up GSTIN outside the period', () async {
    final source = await invoices.save(
      _invoice(
        number: 'INV-JUL',
        gstin: '24ABCDE1234F1Z5',
        hsnSac: '9403',
        date: DateTime(2026, 7, 15),
      ),
    );
    await creditNotes.issue(
      invoice: source,
      creditNoteDate: DateTime(2026, 8, 27),
      reason: 'Damaged goods',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: source.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 500,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );

    final pack = await service.build(period);
    expect(pack.summary.invoiceCount, 0);
    expect(pack.summary.creditNoteCount, 1);
    expect(pack.creditNotes.single.gstin, '24ABCDE1234F1Z5');
    expect(pack.creditNotes.single.creditNoteNumber, 'CN-0001');
    final csv = await service.buildCsv(GstExportKind.creditNotes, pack);
    expect(utf8.decode(csv.bytes), contains('Credit note number'));
    expect(utf8.decode(csv.bytes), contains('CN-0001'));
  });

  test('flags a GST invoice missing HSN/SAC', () async {
    await invoices.save(
      _invoice(number: 'INV-NO-HSN', gstin: '24ABCDE1234F1Z5'),
    );
    final pack = await service.build(period);
    expect(
      pack.exceptions.any(
        (item) => item.documentNumber == 'INV-NO-HSN' && item.kind == 'HSN/SAC',
      ),
      isTrue,
    );
  });

  test('counts ITC only from eligible purchases', () async {
    final supplier = await purchases.saveSupplier(
      SupplierModel(
        name: 'Paper Vendor',
        gstin: '24ABCDE1234F1Z5',
        createdAt: DateTime(2026, 8, 10),
        updatedAt: DateTime(2026, 8, 10),
      ),
    );
    await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-ITC',
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 12),
        items: const [
          PurchaseItemModel(
            name: 'Paper',
            quantity: 1,
            unit: 'box',
            hsnSac: '4802',
            rateMinor: 10000,
            taxRate: 18,
          ),
        ],
        itcEligible: true,
        createdAt: DateTime(2026, 8, 12),
        updatedAt: DateTime(2026, 8, 12),
      ),
    );
    await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-NO-ITC',
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 13),
        items: const [
          PurchaseItemModel(
            name: 'Office tea',
            quantity: 1,
            unit: 'box',
            hsnSac: '0902',
            rateMinor: 2000,
            taxRate: 18,
          ),
        ],
        itcEligible: false,
        createdAt: DateTime(2026, 8, 13),
        updatedAt: DateTime(2026, 8, 13),
      ),
    );
    final cancelledId = await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-CANCEL',
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 14),
        items: const [
          PurchaseItemModel(
            name: 'Wrong bill',
            quantity: 1,
            unit: 'pcs',
            rateMinor: 5000,
            taxRate: 18,
          ),
        ],
        createdAt: DateTime(2026, 8, 14),
        updatedAt: DateTime(2026, 8, 14),
      ),
    );
    await purchases.cancelBill(cancelledId, reason: 'Duplicate');

    final pack = await service.build(period);
    expect(pack.summary.purchaseCount, 2);
    expect(pack.summary.itcMinor, 1800);
    expect(
      pack.exceptions.any((item) => item.documentNumber == 'PB-CANCEL'),
      isFalse,
    );
  });

  test('empty range still has CSV headers and a non-empty ZIP', () async {
    final empty = GstExportPeriod(
      from: DateTime(2025, 1, 1),
      to: DateTime(2025, 1, 31),
      preset: GstExportPeriodPreset.custom,
    );
    final pack = await service.build(empty);
    expect(pack.summary.invoiceCount, 0);
    expect(GstExportPack.filingStatus, 'Prepared');

    final sales = await service.buildCsv(GstExportKind.sales, pack);
    expect(utf8.decode(sales.bytes), contains('Invoice number'));
    expect(utf8.decode(sales.bytes), contains('Filing status'));

    final zip = await service.buildZip(pack);
    expect(zip.bytes, isNotEmpty);
    final archive = ZipDecoder().decodeBytes(zip.bytes);
    expect(
      archive.files.map((file) => file.name),
      contains('README_PREPARED.txt'),
    );
    expect(archive.files.any((file) => file.name.endsWith('.csv')), isTrue);
    expect(archive.files.any((file) => file.name.endsWith('.pdf')), isTrue);
    final readme = utf8.decode(
      archive.files
              .firstWhere((file) => file.name == 'README_PREPARED.txt')
              .content
          as List<int>,
    );
    expect(readme, contains('Prepared'));
    expect(readme.toLowerCase(), contains('not been submitted'));
  });
}

InvoiceModel _invoice({
  required String number,
  String? gstin,
  String? hsnSac,
  DateTime? date,
  InvoiceStatus status = InvoiceStatus.unpaid,
  DocumentType documentType = DocumentType.invoice,
}) {
  const calculator = InvoiceCalculationService();
  final issued = date ?? DateTime(2026, 8, 10);
  final calculation = calculator.calculate(
    InvoiceCalculationInput(
      taxType: TaxType.cgstSgst,
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 1000,
          rateMinor: 10000,
          taxRateBasisPoints: 1800,
        ),
      ],
    ),
  );
  return InvoiceModel(
    documentType: documentType,
    invoiceNumber: number,
    customer: CustomerSnapshotModel(
      customerId: 1,
      name: 'Rinkal Ben',
      gstin: gstin,
    ),
    invoiceDate: issued,
    status: status,
    taxType: TaxType.cgstSgst,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: 'item',
        name: 'MDF Circle',
        quantityScaled: 1000,
        unit: 'pcs',
        rateMinor: 10000,
        hsnSac: hsnSac,
        taxRateBasisPoints: 1800,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: issued,
    updatedAt: issued,
  );
}
