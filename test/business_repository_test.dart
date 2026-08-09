import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invora/data/models/business_profile_model.dart';
import 'package:invora/data/repositories/business_repository.dart';
import 'package:invora/data/services/app_database.dart';

void main() {
  late AppDatabase database;
  late BusinessRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BusinessRepository(database);
  });

  tearDown(() => database.close());

  test('saves and restores the offline business profile', () async {
    final now = DateTime(2026, 8, 9);
    final saved = await repository.saveProfile(
      BusinessProfileModel(
        businessName: 'Invora Studio',
        gstRegistered: true,
        gstin: '24ABCDE1234F1Z5',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final restored = await repository.getProfile();

    expect(saved.id, isNotNull);
    expect(restored?.businessName, 'Invora Studio');
    expect(restored?.gstin, '24ABCDE1234F1Z5');
    expect(restored?.currencyCode, 'INR');
  });
}
