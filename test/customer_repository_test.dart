import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';

void main() {
  late AppDatabase database;
  late CustomerRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CustomerRepository(database);
  });

  tearDown(() => database.close());

  test('creates, searches, edits and soft deletes customers', () async {
    final now = DateTime(2026, 8, 9);
    final saved = await repository.save(
      CustomerModel(
        name: 'Aarav Shah',
        companyName: 'Shah Traders',
        mobile: '9876543210',
        gstin: '24ABCDE1234F1Z5',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect((await repository.watchCustomers(query: 'Traders').first).length, 1);
    expect((await repository.watchCustomers(query: '9876').first).length, 1);

    final edited = await repository.save(
      CustomerModel(
        id: saved.id,
        name: 'Aarav Shah',
        companyName: 'Shah Enterprise',
        createdAt: saved.createdAt,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    expect(edited.companyName, 'Shah Enterprise');

    await repository.softDelete(saved.id!);
    expect(await repository.watchCustomers().first, isEmpty);
    expect((await repository.getById(saved.id!))?.isDeleted, isTrue);
  });
}
