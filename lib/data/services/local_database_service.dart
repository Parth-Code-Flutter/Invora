import 'package:get/get.dart';

import 'app_database.dart';

class LocalDatabaseService extends GetxService {
  LocalDatabaseService(this.database);

  final AppDatabase database;

  Future<void> initialize() async {
    await database.customSelect('SELECT 1').getSingle();
  }

  @override
  void onClose() {
    database.close();
    super.onClose();
  }
}
