import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
  late AppDatabase database;
  late ProductRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ProductRepository(database);
  });

  tearDown(() => database.close());

  test(
    'creates, filters, edits and soft deletes products and services',
    () async {
      final now = DateTime(2026, 8, 9);
      final product = await repository.save(
        ProductServiceModel(
          name: 'Premium Paper',
          type: ItemType.product,
          unit: 'box',
          salePriceMinor: 125050,
          hsnSac: '4802',
          taxRateBasisPoints: 1800,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.save(
        ProductServiceModel(
          name: 'Logo Design',
          type: ItemType.service,
          unit: 'service',
          salePriceMinor: 500000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        (await repository.watchItems(type: ItemType.product).first).single.name,
        'Premium Paper',
      );
      expect(
        (await repository.watchItems(query: 'Logo').first).single.type,
        ItemType.service,
      );

      final edited = await repository.save(
        ProductServiceModel(
          id: product.id,
          name: 'Premium Paper Box',
          type: product.type,
          unit: product.unit,
          salePriceMinor: 130000,
          createdAt: product.createdAt,
          updatedAt: now.add(const Duration(minutes: 1)),
        ),
      );
      expect(edited.salePriceMinor, 130000);

      await repository.softDelete(product.id!);
      expect(
        await repository.watchItems(type: ItemType.product).first,
        isEmpty,
      );
      expect((await repository.getById(product.id!))?.isDeleted, isTrue);
    },
  );
}
