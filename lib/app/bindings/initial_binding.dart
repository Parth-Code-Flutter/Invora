import 'package:get/get.dart';

import '../../data/services/app_database.dart';
import '../../data/services/app_storage.dart';
import '../../data/services/local_database_service.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../controllers/app_controller.dart';

class InitialBinding extends Bindings {
  InitialBinding(this.appStorage, this.databaseService);

  final AppStorage appStorage;
  final LocalDatabaseService databaseService;

  @override
  void dependencies() {
    Get.put<AppStorage>(appStorage, permanent: true);
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
    Get.put<AppController>(
      AppController(Get.find<AppStorage>()),
      permanent: true,
    );
  }
}
