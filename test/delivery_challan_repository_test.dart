import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/delivery_challan_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/repositories/delivery_challan_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/delivery_challan_pdf_service.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late InvoiceRepository invoices;
  late DeliveryChallanRepository challans;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    invoices = InvoiceRepository(database);
    challans = DeliveryChallanRepository(database, invoices);
  });

  tearDown(() => database.close());

  test(
    'issues sequential DC numbers and copies a quotation snapshot',
    () async {
      final quotation = await invoices.save(
        _document(number: 'QTN-0001', type: DocumentType.quotation),
      );
      final first = await challans.save(
        _challan(
          sourceType: DeliveryChallanSourceType.quotation,
          sourceId: quotation.id,
          items: [
            DeliveryChallanItemModel(
              localId: 'line',
              sourceItemId: quotation.items.single.id,
              name: quotation.items.single.name,
              orderedQuantityScaled: 2000,
              dispatchedQuantityScaled: 2000,
              unit: 'pcs',
              rateMinor: 50000,
            ),
          ],
        ),
        asDraft: false,
      );
      final second = await challans.save(_challan(), asDraft: true);

      expect(first.challanNumber, 'DC-0001');
      expect(first.status, DeliveryChallanStatus.open);
      expect(first.sourceType, DeliveryChallanSourceType.quotation);
      expect(first.sourceNumber, 'QTN-0001');
      expect(first.items.single.orderedQuantityScaled, 2000);
      expect(second.challanNumber, 'DC-0002');
      expect(second.status, DeliveryChallanStatus.draft);
    },
  );

  test('converts remaining quantity and blocks an over-invoice', () async {
    final saved = await challans.save(
      _challan(
        items: [
          const DeliveryChallanItemModel(
            localId: 'line',
            name: 'MDF Circle',
            orderedQuantityScaled: 2000,
            dispatchedQuantityScaled: 2000,
            unit: 'pcs',
            rateMinor: 10000,
          ),
        ],
      ),
      asDraft: false,
    );
    final lineId = saved.items.single.id!;

    final firstInvoice = await challans.convertToInvoice(
      challanId: saved.id!,
      invoiceNumber: 'INV-DC-1',
      lines: [DeliveryChallanConvertLine(itemId: lineId, quantityScaled: 1000)],
    );
    expect(firstInvoice.invoiceNumber, 'INV-DC-1');
    expect(firstInvoice.notes, 'From delivery challan DC-0001');
    expect(firstInvoice.items.single.quantityScaled, 1000);

    final afterFirst = await challans.getById(saved.id!);
    expect(afterFirst!.status, DeliveryChallanStatus.partInvoiced);
    expect(afterFirst.items.single.invoicedQuantityScaled, 1000);
    expect(afterFirst.items.single.remainingToInvoiceScaled, 1000);
    expect(afterFirst.conversions, hasLength(1));

    await expectLater(
      challans.convertToInvoice(
        challanId: saved.id!,
        invoiceNumber: 'INV-DC-OVER',
        lines: [
          DeliveryChallanConvertLine(itemId: lineId, quantityScaled: 2000),
        ],
      ),
      throwsArgumentError,
    );

    final secondInvoice = await challans.convertToInvoice(
      challanId: saved.id!,
      invoiceNumber: 'INV-DC-2',
      lines: [DeliveryChallanConvertLine(itemId: lineId, quantityScaled: 1000)],
    );
    expect(secondInvoice.invoiceNumber, 'INV-DC-2');
    final complete = await challans.getById(saved.id!);
    expect(complete!.status, DeliveryChallanStatus.invoiced);
    expect(complete.conversions, hasLength(2));
  });

  test('rejects convert for non-sale movement', () async {
    final saved = await challans.save(
      _challan(reason: MovementReason.jobWork),
      asDraft: false,
    );
    await expectLater(
      challans.convertToInvoice(
        challanId: saved.id!,
        invoiceNumber: 'INV-DC-JOB',
        lines: [
          DeliveryChallanConvertLine(
            itemId: saved.items.single.id!,
            quantityScaled: 1000,
          ),
        ],
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Non-sale movement cannot be converted to an invoice.',
        ),
      ),
    );
  });

  test('records delivery and return, then cancels with a reason', () async {
    final saved = await challans.save(_challan(), asDraft: false);
    final updated = await challans.recordQuantities(
      challanId: saved.id!,
      updates: [
        DeliveryChallanQuantityUpdate(
          itemId: saved.items.single.id!,
          deliveredQuantityScaled: 1000,
          returnedQuantityScaled: 0,
        ),
      ],
    );
    expect(updated.status, DeliveryChallanStatus.delivered);
    expect(updated.items.single.deliveredQuantityScaled, 1000);

    final cancelled = await challans.cancel(
      challanId: saved.id!,
      reason: 'Wrong party',
    );
    expect(cancelled.status, DeliveryChallanStatus.cancelled);
    expect(cancelled.cancellationReason, 'Wrong party');

    await expectLater(
      challans.cancel(challanId: saved.id!, reason: 'Again'),
      throwsArgumentError,
    );
  });

  test(
    'blocks cancel after conversion and prepares e-way only after import',
    () async {
      final saved = await challans.save(
        _challan(transporterName: 'Gati', vehicleNumber: 'GJ01AB1234'),
        asDraft: false,
      );
      await challans.convertToInvoice(
        challanId: saved.id!,
        invoiceNumber: 'INV-DC-LOCK',
        lines: [
          DeliveryChallanConvertLine(
            itemId: saved.items.single.id!,
            quantityScaled: 1000,
          ),
        ],
      );
      await expectLater(
        challans.cancel(challanId: saved.id!, reason: 'Too late'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'This challan has invoices and cannot be cancelled.',
          ),
        ),
      );

      final prepared = await challans.prepareEway(saved.id!);
      expect(prepared.ewayStatus, EwayStatus.prepared);
      expect(prepared.ewayNumber, isNull);

      final imported = await challans.importEwayAcknowledgement(
        challanId: saved.id!,
        ewayNumber: '121000000001',
      );
      expect(imported.ewayStatus, EwayStatus.generated);
      expect(imported.ewayNumber, '121000000001');
    },
  );

  test(
    'invoice-sourced challans track remaining dispatch and cannot convert',
    () async {
      final invoice = await invoices.save(_document(number: 'INV-0001'));
      final sourceItemId = invoice.items.single.id!;
      final first = await challans.save(
        _challan(
          sourceType: DeliveryChallanSourceType.invoice,
          sourceId: invoice.id,
          items: [
            DeliveryChallanItemModel(
              localId: 'line',
              sourceItemId: sourceItemId,
              name: invoice.items.single.name,
              orderedQuantityScaled: 2000,
              dispatchedQuantityScaled: 1000,
              unit: 'pcs',
              rateMinor: 50000,
            ),
          ],
        ),
        asDraft: false,
      );
      expect(first.sourceCaption, 'Against invoice INV-0001');
      expect(first.canConvert, isFalse);

      final remaining = await challans.remainingLinesFromDocument(
        invoice,
        sourceType: DeliveryChallanSourceType.invoice,
      );
      expect(remaining, hasLength(1));
      expect(remaining.single.dispatchedQuantityScaled, 1000);

      await expectLater(
        challans.save(
          _challan(
            sourceType: DeliveryChallanSourceType.invoice,
            sourceId: invoice.id,
            items: [
              DeliveryChallanItemModel(
                localId: 'over',
                sourceItemId: sourceItemId,
                name: invoice.items.single.name,
                orderedQuantityScaled: 2000,
                dispatchedQuantityScaled: 2000,
                unit: 'pcs',
                rateMinor: 50000,
              ),
            ],
          ),
          asDraft: false,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Cannot dispatch more than remaining quantity on INV-0001.',
          ),
        ),
      );

      await expectLater(
        challans.convertToInvoice(
          challanId: first.id!,
          invoiceNumber: 'INV-DC-DUP',
          lines: [
            DeliveryChallanConvertLine(
              itemId: first.items.single.id!,
              quantityScaled: 1000,
            ),
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'This challan is against an invoice. Remaining quantity is for delivery, not another invoice.',
          ),
        ),
      );

      final second = await challans.save(
        _challan(
          sourceType: DeliveryChallanSourceType.invoice,
          sourceId: invoice.id,
          items: remaining,
        ),
        asDraft: false,
      );
      expect(second.items.single.dispatchedQuantityScaled, 1000);
      expect(
        await challans.remainingLinesFromDocument(
          invoice,
          sourceType: DeliveryChallanSourceType.invoice,
        ),
        isEmpty,
      );
    },
  );

  test(
    'renders a delivery challan PDF without calling generated e-way',
    () async {
      final saved = await challans.save(
        _challan(transporterName: 'Gati', vehicleNumber: 'GJ01AB1234'),
        asDraft: false,
      );
      await challans.prepareEway(saved.id!);
      final bytes = await const DeliveryChallanPdfService().build(
        challan: (await challans.getById(saved.id!))!,
        business: BusinessProfileModel(
          businessName: 'Creovo QA',
          currencySymbol: '₹',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      expect(bytes, isNotEmpty);
    },
  );
}

DeliveryChallanModel _challan({
  DeliveryChallanSourceType sourceType = DeliveryChallanSourceType.blank,
  int? sourceId,
  MovementReason reason = MovementReason.supply,
  String? transporterName,
  String? vehicleNumber,
  List<DeliveryChallanItemModel>? items,
}) {
  return DeliveryChallanModel(
    challanNumber: '',
    customer: const CustomerSnapshotModel(customerId: 1, name: 'Rinkal Ben'),
    sourceType: sourceType,
    sourceId: sourceId,
    challanDate: DateTime(2026, 8, 28),
    status: DeliveryChallanStatus.open,
    movementReason: reason,
    transporterName: transporterName,
    vehicleNumber: vehicleNumber,
    items:
        items ??
        const [
          DeliveryChallanItemModel(
            localId: 'line',
            name: 'MDF Circle',
            orderedQuantityScaled: 1000,
            dispatchedQuantityScaled: 1000,
            unit: 'pcs',
            rateMinor: 10000,
          ),
        ],
    createdAt: DateTime(2026, 8, 28),
    updatedAt: DateTime(2026, 8, 28),
  );
}

InvoiceModel _document({
  required String number,
  DocumentType type = DocumentType.invoice,
}) {
  final calculation = const InvoiceCalculationService().calculate(
    const InvoiceCalculationInput(
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 2000,
          rateMinor: 50000,
        ),
      ],
    ),
  );
  return InvoiceModel(
    documentType: type,
    invoiceNumber: number,
    customer: const CustomerSnapshotModel(customerId: 1, name: 'Rinkal Ben'),
    invoiceDate: DateTime(2026, 8, 20),
    status: type == DocumentType.quotation
        ? InvoiceStatus.accepted
        : InvoiceStatus.unpaid,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: 'item',
        name: 'MDF Circle',
        quantityScaled: 2000,
        unit: 'pcs',
        rateMinor: 50000,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: DateTime(2026, 8, 20),
    updatedAt: DateTime(2026, 8, 20),
  );
}
