import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/credit_note_model.dart';
import 'package:creovo_invoice/data/models/debit_note_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/models/stock_models.dart';
import 'package:creovo_invoice/data/repositories/credit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/debit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/services/stock_ledger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late StockLedger ledger;
  late ProductRepository products;
  late InvoiceRepository invoices;
  late PurchaseRepository purchases;
  late CreditNoteRepository creditNotes;
  late DebitNoteRepository debitNotes;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = StockLedger(database);
    products = ProductRepository(database);
    invoices = InvoiceRepository(database);
    purchases = PurchaseRepository(database);
    creditNotes = CreditNoteRepository(database, invoices);
    debitNotes = DebitNoteRepository(database, purchases);
  });

  tearDown(() => database.close());

  test('stays off by default and does not post movements', () async {
    final product = await _product(products, name: 'Sheet');
    expect(await ledger.isEnabled(), isFalse);
    await invoices.save(
      _invoice(
        productId: product.id,
        quantityScaled: 2000,
        number: 'INV-OFF-1',
      ),
    );
    expect(await ledger.onHand(product.id!), 0);
    expect(await _movementCount(database), 0);
  });

  test(
    'records opening quantities and allows disable without deleting rows',
    () async {
      final product = await _product(products, name: 'Board');
      await ledger.enable(
        openingAsOf: DateTime(2026, 4, 1),
        openingQtyByProduct: {product.id!: 5000},
      );
      expect(await ledger.isEnabled(), isTrue);
      expect(await ledger.onHand(product.id!), 5000);

      await ledger.disable();
      expect(await ledger.isEnabled(), isFalse);
      expect(await ledger.onHand(product.id!), 5000);
      expect(await _movementCount(database), 1);
    },
  );

  test('posts a sale and reverses it on cancel without editing rows', () async {
    final product = await _product(products);
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 10000},
    );
    final invoice = await invoices.save(
      _invoice(productId: product.id, quantityScaled: 3000),
    );
    expect(await ledger.onHand(product.id!), 7000);

    await invoices.save(
      _invoice(
        id: invoice.id,
        productId: product.id,
        quantityScaled: 4000,
        number: invoice.invoiceNumber,
      ),
    );
    expect(await ledger.onHand(product.id!), 6000);

    await invoices.cancel(invoice.id!);
    expect(await ledger.onHand(product.id!), 10000);
    final types = (await database.select(database.stockMovements).get())
        .map((row) => row.type)
        .toList();
    expect(types, contains(StockMovementType.sale.storage));
    expect(types, contains(StockMovementType.saleReversal.storage));
    expect(
      types.where((type) => type == StockMovementType.sale.storage).length,
      2,
    );
  });

  test('skips quotations, custom lines, and services', () async {
    final product = await _product(products);
    final service = await _product(
      products,
      name: 'Install',
      type: ItemType.service,
    );
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 8000, service.id!: 2000},
    );
    expect(await ledger.onHand(product.id!), 8000);
    expect(await ledger.onHand(service.id!), 0);

    await invoices.save(
      _invoice(
        productId: product.id,
        quantityScaled: 1000,
        documentType: DocumentType.quotation,
        number: 'QT-1',
      ),
    );
    await invoices.save(
      _invoice(productId: null, quantityScaled: 5000, number: 'INV-CUSTOM'),
    );
    await invoices.save(
      _invoice(
        productId: service.id,
        quantityScaled: 2000,
        number: 'INV-SERVICE',
        name: 'Install',
      ),
    );
    expect(await ledger.onHand(product.id!), 8000);
    expect(await _movementCount(database), 1);
  });

  test('posts purchase bills and debit-note stock-out', () async {
    final product = await _product(products);
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 1000},
    );
    final supplier = await purchases.saveSupplier(
      SupplierModel(
        name: 'Paper Co',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    final billId = await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-1',
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 15),
        taxMode: 'exempt',
        items: [
          PurchaseItemModel(
            productId: product.id,
            name: product.name,
            quantity: 5,
            unit: 'pcs',
            rateMinor: 1000,
          ),
        ],
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
      ),
    );
    expect(await ledger.onHand(product.id!), 6000);

    final bill = (await purchases.getBill(billId))!;
    await debitNotes.issue(
      bill: bill,
      debitNoteDate: DateTime(2026, 8, 16),
      reason: 'Short quantity',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: bill.items.single,
          originalQuantityScaled: 5000,
          returnedQuantityScaled: 2000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenKeep,
    );
    expect(await ledger.onHand(product.id!), 4000);
  });

  test('reverses a purchase bill when cancelled', () async {
    final product = await _product(products, name: 'Ply');
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 2000},
    );
    final supplier = await purchases.saveSupplier(
      SupplierModel(
        name: 'Ply Co',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    final billId = await purchases.saveBill(
      PurchaseBillModel(
        billNumber: 'PB-CANCEL',
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: DateTime(2026, 8, 15),
        taxMode: 'exempt',
        items: [
          PurchaseItemModel(
            productId: product.id,
            name: product.name,
            quantity: 3,
            unit: 'pcs',
            rateMinor: 1000,
          ),
        ],
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
      ),
    );
    expect(await ledger.onHand(product.id!), 5000);
    await purchases.cancelBill(billId, reason: 'Wrong supplier');
    expect(await ledger.onHand(product.id!), 2000);
  });

  test('restocks returned catalog lines from a credit note', () async {
    final product = await _product(products);
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 4000},
    );
    final invoice = await invoices.save(
      _invoice(productId: product.id, quantityScaled: 3000),
    );
    expect(await ledger.onHand(product.id!), 1000);

    await creditNotes.issue(
      invoice: invoice,
      creditNoteDate: DateTime(2026, 8, 21),
      reason: 'Customer return',
      returnedItems: [
        CreditNoteItemDraft(
          invoiceItem: invoice.items.single,
          originalQuantityScaled: 3000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: CreditNoteRemainderAction.applyThenKeep,
    );
    expect(await ledger.onHand(product.id!), 2000);
  });

  test('manual adjustment requires a reason and updates on-hand', () async {
    final product = await _product(products);
    await ledger.enable(
      openingAsOf: DateTime(2026, 4, 1),
      openingQtyByProduct: {product.id!: 2000},
    );
    await ledger.adjust(
      productId: product.id!,
      quantityScaled: -500,
      reason: 'Damaged in store',
    );
    expect(await ledger.onHand(product.id!), 1500);
    await expectLater(
      ledger.adjust(productId: product.id!, quantityScaled: 1000, reason: '  '),
      throwsArgumentError,
    );
  });

  test('as-of on-hand and range reports ignore later postings', () async {
    final product = await _product(products);
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: product.id!,
            quantityScaled: 5000,
            type: StockMovementType.opening.storage,
            sourceType: StockSourceType.opening.storage,
            sourceId: Value(product.id),
            createdAt: Value(DateTime(2026, 8, 1, 9)),
          ),
        );
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: product.id!,
            quantityScaled: -2000,
            type: StockMovementType.sale.storage,
            sourceType: StockSourceType.invoice.storage,
            sourceId: const Value(1),
            createdAt: Value(DateTime(2026, 8, 20, 10)),
          ),
        );

    expect(await ledger.onHandAsOf(DateTime(2026, 8, 10)), {product.id!: 5000});
    expect(await ledger.onHandAsOf(DateTime(2026, 8, 20)), {product.id!: 3000});

    final inRange = await ledger.movementsInRange(
      from: DateTime(2026, 8, 15),
      to: DateTime(2026, 8, 31),
    );
    expect(inRange, hasLength(1));
    expect(inRange.single.quantityScaled, -2000);
  });

  test('posts only for products with Keep stock on', () async {
    final tracked = await _product(products, name: 'Tracked board');
    final skipped = await _product(products, name: 'Untracked sheet');
    await ledger.setProductTracked(
      productId: tracked.id!,
      tracked: true,
      openingQtyScaled: 10000,
    );
    expect(await ledger.isEnabled(), isTrue);
    expect((await products.getById(skipped.id!))!.trackStock, isFalse);

    await invoices.save(
      _invoice(
        productId: tracked.id,
        quantityScaled: 2000,
        number: 'INV-TRACKED',
      ),
    );
    await invoices.save(
      _invoice(
        productId: skipped.id,
        quantityScaled: 3000,
        number: 'INV-SKIP',
        name: 'Untracked sheet',
      ),
    );
    expect(await ledger.onHand(tracked.id!), 8000);
    expect(await ledger.onHand(skipped.id!), 0);
  });

  test('opening posts once and turning Keep stock off keeps rows', () async {
    final product = await _product(products, name: 'First count');
    await ledger.setProductTracked(
      productId: product.id!,
      tracked: true,
      openingQtyScaled: 4000,
    );
    await ledger.setProductTracked(
      productId: product.id!,
      tracked: true,
      openingQtyScaled: 9000,
    );
    expect(await ledger.onHand(product.id!), 4000);
    expect(await _movementCount(database), 1);

    await ledger.setProductTracked(productId: product.id!, tracked: false);
    expect(await ledger.isEnabled(), isFalse);
    expect(await ledger.onHand(product.id!), 4000);
    expect((await products.getById(product.id!))!.trackStock, isFalse);
  });

  test('adjust requires Keep stock on that product', () async {
    final product = await _product(products);
    await expectLater(
      ledger.adjust(
        productId: product.id!,
        quantityScaled: 1000,
        reason: 'Count correction',
      ),
      throwsStateError,
    );
  });

  test('catalog quantity posts opening then later adjusts on-hand', () async {
    final product = await _product(products, name: 'Qty field');
    await ledger.applyCatalogQuantity(
      productId: product.id!,
      tracked: true,
      quantityScaled: 5000,
    );
    expect(await ledger.onHand(product.id!), 5000);

    await ledger.applyCatalogQuantity(
      productId: product.id!,
      tracked: true,
      quantityScaled: 8000,
    );
    expect(await ledger.onHand(product.id!), 8000);
    expect(await _movementCount(database), 2);
  });
}

Future<int> _movementCount(AppDatabase database) async {
  return (await database.select(database.stockMovements).get()).length;
}

Future<ProductServiceModel> _product(
  ProductRepository products, {
  String name = 'MDF Circle',
  ItemType type = ItemType.product,
}) {
  final now = DateTime(2026, 8, 1);
  return products.save(
    ProductServiceModel(
      name: name,
      type: type,
      unit: 'pcs',
      salePriceMinor: 10000,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

InvoiceModel _invoice({
  int? id,
  int? productId,
  required int quantityScaled,
  String number = 'INV-ST-1',
  DocumentType documentType = DocumentType.invoice,
  String name = 'MDF Circle',
}) {
  final calculation = const InvoiceCalculationService().calculate(
    InvoiceCalculationInput(
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: quantityScaled,
          rateMinor: 10000,
        ),
      ],
    ),
  );
  return InvoiceModel(
    id: id,
    documentType: documentType,
    invoiceNumber: number,
    customer: const CustomerSnapshotModel(name: 'Rinkal Ben'),
    invoiceDate: DateTime(2026, 8, 20),
    status: InvoiceStatus.unpaid,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: 'item',
        productId: productId,
        name: name,
        quantityScaled: quantityScaled,
        unit: 'pcs',
        rateMinor: 10000,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: DateTime(2026, 8, 20),
    updatedAt: DateTime(2026, 8, 20),
  );
}
