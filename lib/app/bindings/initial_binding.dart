import 'package:get/get.dart';

import '../../data/services/app_database.dart';
import '../../data/services/app_storage.dart';
import '../../data/services/local_database_service.dart';
import '../../data/services/invoice_calculation_service.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../data/services/invoice_defaults_service.dart';
import '../../data/services/data_export_service.dart';
import '../../data/services/product_settings_service.dart';
import '../../data/services/payment_receipt_pdf_service.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/unit_service.dart';
import '../../data/services/app_lock_service.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../controllers/app_controller.dart';

class InitialBinding extends Bindings {
  InitialBinding(this.appStorage, this.databaseService);

  final AppStorage appStorage;
  final LocalDatabaseService databaseService;

  @override
  void dependencies() {
    Get.put<AppStorage>(appStorage, permanent: true);
    final appLockService = AppLockService(appStorage)..load();
    Get.put<AppLockService>(appLockService, permanent: true);
    Get.put<AppDatabase>(databaseService.database, permanent: true);
    Get.put<LocalDatabaseService>(databaseService, permanent: true);
    Get.put<BusinessRepository>(
      BusinessRepository(databaseService.database),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      CustomerRepository(databaseService.database),
      permanent: true,
    );
    Get.put<ProductRepository>(
      ProductRepository(databaseService.database),
      permanent: true,
    );
    Get.put<InvoiceRepository>(
      InvoiceRepository(databaseService.database),
      permanent: true,
    );
    Get.put<InvoiceCalculationService>(
      const InvoiceCalculationService(),
      permanent: true,
    );
    Get.put<ProductSettingsService>(
      ProductSettingsService(appStorage),
      permanent: true,
    );
    Get.put<InvoicePdfService>(
      InvoicePdfService(productSettings: Get.find<ProductSettingsService>()),
      permanent: true,
    );
    Get.put<PaymentReceiptPdfService>(
      const PaymentReceiptPdfService(),
      permanent: true,
    );
    Get.put<UnitService>(UnitService(appStorage), permanent: true);
    Get.put<InvoiceDefaultsService>(
      InvoiceDefaultsService(appStorage),
      permanent: true,
    );
    Get.put<DataExportService>(
      DataExportService(
        Get.find<CustomerRepository>(),
        Get.find<ProductRepository>(),
        Get.find<InvoiceRepository>(),
      ),
      permanent: true,
    );
    Get.put<BackupService>(
      BackupService(
        databaseService.database,
        Get.find<BusinessRepository>(),
        appStorage,
      ),
      permanent: true,
    );
    Get.put<AppController>(
      AppController(Get.find<AppStorage>()),
      permanent: true,
    );
  }
}
