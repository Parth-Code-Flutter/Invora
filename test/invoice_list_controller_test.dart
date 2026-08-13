import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/modules/invoices/controllers/invoice_list_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test(
    'repeated route refresh settles instead of leaving skeleton active',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = Get.put(
        InvoiceListController(
          InvoiceRepository(database),
          BusinessRepository(database),
        ),
      );

      await _waitForLoading(controller);
      expect(controller.invoices, isEmpty);

      controller.refreshInvoices();
      await _waitForLoading(controller);

      expect(controller.isLoading.value, isFalse);
      expect(controller.invoices, isEmpty);
    },
  );
}

Future<void> _waitForLoading(InvoiceListController controller) async {
  for (var attempt = 0; attempt < 20 && controller.isLoading.value; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(controller.isLoading.value, isFalse);
}
