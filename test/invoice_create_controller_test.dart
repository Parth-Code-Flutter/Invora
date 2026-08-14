import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/modules/invoices/controllers/invoice_create_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selecting the same saved item increases its quantity', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = InvoiceCreateController(
      InvoiceRepository(database),
      BusinessRepository(database),
      CustomerRepository(database),
      ProductRepository(database),
      const InvoiceCalculationService(),
    );
    final product = ProductServiceModel(
      id: 7,
      name: 'MDF Circle',
      type: ItemType.product,
      unit: 'pcs',
      salePriceMinor: 18200,
      createdAt: DateTime(2026, 8, 11),
      updatedAt: DateTime(2026, 8, 11),
    );

    controller.addProduct(product);
    controller.addProduct(product);

    expect(controller.items, hasLength(1));
    expect(controller.items.single.quantityScaled, 2000);
    expect(controller.calculation.value?.grandTotalMinor, 36400);

    controller.decrementQuantity(0);
    expect(controller.items.single.quantityScaled, 1000);
    controller.onClose();
    await database.close();
  });

  test('changing issued date preserves the due-date payment term', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = InvoiceCreateController(
      InvoiceRepository(database),
      BusinessRepository(database),
      CustomerRepository(database),
      ProductRepository(database),
      const InvoiceCalculationService(),
    );
    controller.invoiceDate.value = DateTime(2026, 8, 14);
    controller.setDueDate(DateTime(2026, 8, 29));

    controller.setInvoiceDate(DateTime(2026, 9, 10));

    expect(controller.invoiceDate.value, DateTime(2026, 9, 10));
    expect(controller.dueDate.value, DateTime(2026, 9, 25));
    controller.onClose();
    await database.close();
  });

  test('adds a multi-selected catalog batch in one invoice update', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = InvoiceCreateController(
      InvoiceRepository(database),
      BusinessRepository(database),
      CustomerRepository(database),
      ProductRepository(database),
      const InvoiceCalculationService(),
    );
    final now = DateTime(2026, 8, 11);

    controller.addProducts([
      ProductServiceModel(
        id: 1,
        name: 'MDF Circle',
        type: ItemType.product,
        unit: 'pcs',
        salePriceMinor: 18200,
        createdAt: now,
        updatedAt: now,
      ),
      ProductServiceModel(
        id: 2,
        name: 'Design service',
        type: ItemType.service,
        unit: 'hour',
        salePriceMinor: 50000,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(controller.items, hasLength(2));
    expect(controller.calculation.value?.grandTotalMinor, 68200);

    controller.incrementQuantity(1);
    controller.applyCatalogSelection(
      removedProductIds: {1},
      added: [
        ProductServiceModel(
          id: 3,
          name: 'Delivery',
          type: ItemType.service,
          unit: 'service',
          salePriceMinor: 10000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    expect(controller.items.map((item) => item.productId), [2, 3]);
    expect(controller.items.first.quantityScaled, 2000);
    expect(controller.calculation.value?.grandTotalMinor, 110000);
    controller.onClose();
    await database.close();
  });

  test('invoice price override does not mutate the catalog product', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = InvoiceCreateController(
      InvoiceRepository(database),
      BusinessRepository(database),
      CustomerRepository(database),
      ProductRepository(database),
      const InvoiceCalculationService(),
    );
    final product = ProductServiceModel(
      id: 11,
      name: 'Priority design',
      type: ItemType.service,
      unit: 'hour',
      salePriceMinor: 50000,
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
    );

    controller.addProduct(product);
    controller.updateItemRate(0, 42500);

    expect(controller.items.single.rateMinor, 42500);
    expect(controller.calculation.value?.grandTotalMinor, 42500);
    expect(product.salePriceMinor, 50000);
    controller.onClose();
    await database.close();
  });

  test(
    'direct quantity entry updates item total without repeated taps',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final controller = InvoiceCreateController(
        InvoiceRepository(database),
        BusinessRepository(database),
        CustomerRepository(database),
        ProductRepository(database),
        const InvoiceCalculationService(),
      );
      controller.addProduct(
        ProductServiceModel(
          id: 12,
          name: 'MDF Sheet',
          type: ItemType.product,
          unit: 'pcs',
          salePriceMinor: 1000,
          createdAt: DateTime(2026, 8, 13),
          updatedAt: DateTime(2026, 8, 13),
        ),
      );

      controller.updateItemQuantity(0, 50000);

      expect(controller.items.single.quantityScaled, 50000);
      expect(controller.calculation.value?.grandTotalMinor, 50000);
      controller.onClose();
      await database.close();
    },
  );
}
