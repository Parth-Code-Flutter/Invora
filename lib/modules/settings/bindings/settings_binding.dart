import 'package:get/get.dart';

import '../controllers/about_controller.dart';
import '../controllers/settings_controller.dart';
import '../../../data/services/app_database.dart';
import '../../../data/services/app_lock_service.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/diagnostics_service.dart';
import '../controllers/invoice_defaults_controller.dart';
import '../controllers/data_export_controller.dart';
import '../controllers/data_import_controller.dart';
import '../controllers/product_settings_controller.dart';
import '../controllers/stock_controller.dart';
import '../controllers/stock_opening_controller.dart';
import '../controllers/more_controller.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/data_export_service.dart';
import '../../../data/services/data_import_service.dart';
import '../../../data/services/stock_ledger.dart';
import '../../../data/services/unit_service.dart';
import '../controllers/unit_settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController(Get.find()));
  }
}

class AboutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AboutController(
        DiagnosticsService(Get.find<AppDatabase>(), Get.find<AppStorage>()),
        Get.find<AppLockService>(),
      ),
    );
  }
}

class InvoiceDefaultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InvoiceDefaultsController(Get.find()));
  }
}

class DataExportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DataExportController(Get.find()));
  }
}

class DataImportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DataImportController(
        Get.find<DataImportService>(),
        Get.find<DataExportService>(),
      ),
    );
  }
}

class ProductSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProductSettingsController(
        Get.find(),
        Get.isRegistered<StockLedger>() ? Get.find<StockLedger>() : null,
      ),
    );
  }
}

class StockOpeningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => StockOpeningController(
        Get.find<StockLedger>(),
        Get.find<ProductRepository>(),
      ),
    );
  }
}

class StockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => StockController(
        Get.find<StockLedger>(),
        Get.find<ProductRepository>(),
      ),
    );
  }
}

class MoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => MoreController(
        Get.find<BusinessRepository>(),
        Get.isRegistered<StockLedger>() ? Get.find<StockLedger>() : null,
      ),
    );
  }
}

class UnitSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UnitSettingsController(Get.find<UnitService>()));
  }
}
