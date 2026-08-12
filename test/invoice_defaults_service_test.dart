import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/constants/app_storage_key_const.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/invoice_defaults_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('provides practical defaults for a first-time user', () async {
    SharedPreferences.setMockInitialValues({});
    final service = InvoiceDefaultsService(await AppStorage.create());

    expect(service.dueDays, 0);
    expect(service.taxType, TaxType.cgstSgst);
    expect(service.gstRateBasisPoints, 1800);
    expect(service.paymentMethod, 'UPI');
    expect(service.notes, isEmpty);
    expect(service.terms, isEmpty);
  });

  test('persists every invoice default', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final service = InvoiceDefaultsService(storage);

    await service.save(
      dueDays: 15,
      taxType: TaxType.igst,
      gstRateBasisPoints: 1200,
      notes: ' Thank you. ',
      terms: ' Pay within 15 days. ',
      paymentMethod: 'Bank transfer',
    );

    expect(service.dueDays, 15);
    expect(service.taxType, TaxType.igst);
    expect(service.gstRateBasisPoints, 1200);
    expect(service.notes, 'Thank you.');
    expect(service.terms, 'Pay within 15 days.');
    expect(service.paymentMethod, 'Bank transfer');
  });

  test('falls back safely from unsupported stored values', () async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeyConst.defaultTaxType: 'unknown',
      AppStorageKeyConst.defaultGstRateBasisPoints: 999,
    });
    final service = InvoiceDefaultsService(await AppStorage.create());

    expect(service.taxType, TaxType.cgstSgst);
    expect(service.gstRateBasisPoints, 1800);
  });
}
