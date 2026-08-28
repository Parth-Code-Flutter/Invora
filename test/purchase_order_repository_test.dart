import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/models/purchase_order_model.dart';
import 'package:creovo_invoice/data/repositories/purchase_order_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/purchase_order_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PurchaseRepository purchases;
  late PurchaseOrderRepository orders;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    purchases = PurchaseRepository(database);
    orders = PurchaseOrderRepository(database, purchases);
  });

  tearDown(() => database.close());

  test('issues sequential PO numbers and keeps a draft until issued', () async {
    final supplier = await _supplier(purchases);
    final first = await orders.save(_order(supplier: supplier), asDraft: false);
    final second = await orders.save(_order(supplier: supplier), asDraft: true);

    expect(first.orderNumber, 'PO-0001');
    expect(first.status, PurchaseOrderStatus.open);
    expect(first.items.single.orderedQuantityScaled, 2000);
    expect(second.orderNumber, 'PO-0002');
    expect(second.status, PurchaseOrderStatus.draft);
    expect(first.canConvert, isFalse);
  });

  test(
    'blocks over-receipt and over-billing, then converts remaining qty',
    () async {
      final supplier = await _supplier(purchases);
      final saved = await orders.save(
        _order(supplier: supplier),
        asDraft: false,
      );
      final lineId = saved.items.single.id!;

      await expectLater(
        orders.recordQuantities(
          orderId: saved.id!,
          updates: [
            PurchaseOrderQuantityUpdate(
              itemId: lineId,
              receivedQuantityScaled: 3000,
              returnedQuantityScaled: 0,
            ),
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Received quantity cannot exceed ordered.',
          ),
        ),
      );

      final received = await orders.recordQuantities(
        orderId: saved.id!,
        updates: [
          PurchaseOrderQuantityUpdate(
            itemId: lineId,
            receivedQuantityScaled: 2000,
            returnedQuantityScaled: 0,
          ),
        ],
      );
      expect(received.status, PurchaseOrderStatus.received);
      expect(received.items.single.remainingToBillScaled, 2000);

      final firstBill = await orders.convertToBill(
        orderId: saved.id!,
        billNumber: 'SUP-1',
        lines: [PurchaseOrderConvertLine(itemId: lineId, quantityScaled: 1000)],
      );
      expect(firstBill.billNumber, 'SUP-1');
      expect(firstBill.notes, 'From purchase order PO-0001');
      expect(firstBill.items.single.quantity, 1);
      expect(firstBill.paidMinor, 0);

      final afterFirst = await orders.getById(saved.id!);
      expect(afterFirst!.status, PurchaseOrderStatus.partBilled);
      expect(afterFirst.items.single.billedQuantityScaled, 1000);
      expect(afterFirst.conversions, hasLength(1));
      expect(afterFirst.canConvert, isTrue);

      await expectLater(
        orders.convertToBill(
          orderId: saved.id!,
          billNumber: 'SUP-OVER',
          lines: [
            PurchaseOrderConvertLine(itemId: lineId, quantityScaled: 2000),
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Cannot bill more than remaining received quantity.',
          ),
        ),
      );

      final secondBill = await orders.convertToBill(
        orderId: saved.id!,
        billNumber: 'SUP-2',
        lines: [PurchaseOrderConvertLine(itemId: lineId, quantityScaled: 1000)],
      );
      expect(secondBill.billNumber, 'SUP-2');
      final complete = await orders.getById(saved.id!);
      expect(complete!.status, PurchaseOrderStatus.billed);
      expect(complete.canConvert, isFalse);
      expect(complete.canCancel, isFalse);
      expect(complete.conversions, hasLength(2));
    },
  );

  test('partial receive then convert uses only received quantity', () async {
    final supplier = await _supplier(purchases);
    final saved = await orders.save(_order(supplier: supplier), asDraft: false);
    final lineId = saved.items.single.id!;
    final partial = await orders.recordQuantities(
      orderId: saved.id!,
      updates: [
        PurchaseOrderQuantityUpdate(
          itemId: lineId,
          receivedQuantityScaled: 1000,
          returnedQuantityScaled: 0,
        ),
      ],
    );
    expect(partial.status, PurchaseOrderStatus.partReceived);
    expect(partial.items.single.remainingToBillScaled, 1000);
    expect(partial.items.single.remainingToReceiveScaled, 1000);

    await expectLater(
      orders.convertToBill(
        orderId: saved.id!,
        billNumber: 'SUP-TOO-MUCH',
        lines: [PurchaseOrderConvertLine(itemId: lineId, quantityScaled: 2000)],
      ),
      throwsArgumentError,
    );

    await orders.convertToBill(
      orderId: saved.id!,
      billNumber: 'SUP-PART',
      lines: [PurchaseOrderConvertLine(itemId: lineId, quantityScaled: 1000)],
    );
    final billed = await orders.getById(saved.id!);
    expect(billed!.status, PurchaseOrderStatus.partBilled);
    expect(billed.canCancel, isFalse);
  });

  test('cancels with a reason until a bill exists', () async {
    final supplier = await _supplier(purchases);
    final saved = await orders.save(_order(supplier: supplier), asDraft: false);
    final cancelled = await orders.cancel(
      orderId: saved.id!,
      reason: 'Supplier delayed',
    );
    expect(cancelled.status, PurchaseOrderStatus.cancelled);
    expect(cancelled.cancellationReason, 'Supplier delayed');
    expect(cancelled.canConvert, isFalse);

    final billed = await orders.save(
      _order(supplier: supplier),
      asDraft: false,
    );
    await orders.recordQuantities(
      orderId: billed.id!,
      updates: [
        PurchaseOrderQuantityUpdate(
          itemId: billed.items.single.id!,
          receivedQuantityScaled: 2000,
          returnedQuantityScaled: 0,
        ),
      ],
    );
    await orders.convertToBill(
      orderId: billed.id!,
      billNumber: 'SUP-LOCK',
      lines: [
        PurchaseOrderConvertLine(
          itemId: billed.items.single.id!,
          quantityScaled: 2000,
        ),
      ],
    );
    await expectLater(
      orders.cancel(orderId: billed.id!, reason: 'Too late'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'This purchase order has bills and cannot be cancelled.',
        ),
      ),
    );
  });

  test('renders a purchase order PDF', () async {
    final supplier = await _supplier(purchases);
    final saved = await orders.save(
      _order(supplier: supplier, terms: 'Net 15'),
      asDraft: false,
    );
    final bytes = await const PurchaseOrderPdfService().build(
      order: saved,
      business: BusinessProfileModel(
        businessName: 'Creovo QA',
        currencySymbol: '₹',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect(bytes, isNotEmpty);
  });
}

Future<SupplierModel> _supplier(PurchaseRepository purchases) {
  return purchases.saveSupplier(
    SupplierModel(
      name: 'Gujarat Boards',
      createdAt: DateTime(2026, 8, 28),
      updatedAt: DateTime(2026, 8, 28),
    ),
  );
}

PurchaseOrderModel _order({required SupplierModel supplier, String? terms}) {
  return PurchaseOrderModel(
    orderNumber: '',
    supplier: supplier,
    orderDate: DateTime(2026, 8, 28),
    status: PurchaseOrderStatus.open,
    terms: terms,
    items: const [
      PurchaseOrderItemModel(
        localId: 'line',
        name: 'MDF Circle',
        orderedQuantityScaled: 2000,
        unit: 'pcs',
        rateMinor: 10000,
        taxRateBasisPoints: 1800,
      ),
    ],
    createdAt: DateTime(2026, 8, 28),
    updatedAt: DateTime(2026, 8, 28),
  );
}
