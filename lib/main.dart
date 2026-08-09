import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/constants/app_constants.dart';
import 'app/controllers/app_controller.dart';
import 'app/routes/route_generator.dart';
import 'app/themes/app_theme.dart';
import 'data/services/app_database.dart';
import 'data/services/app_storage.dart';
import 'data/services/local_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStorage = await AppStorage.create();
  final databaseService = LocalDatabaseService(AppDatabase());
  await databaseService.initialize();
  runApp(InvoraApp(appStorage: appStorage, databaseService: databaseService));
}

class InvoraApp extends StatelessWidget {
  const InvoraApp({
    required this.appStorage,
    required this.databaseService,
    super.key,
  });

  final AppStorage appStorage;
  final LocalDatabaseService databaseService;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(appStorage, databaseService),
      initialRoute: AppRouter.initialRoute,
      getPages: AppRouter.pages,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final appController = Get.find<AppController>();
        return Obx(
          () => Theme(
            data: appController.isDarkMode ? AppTheme.dark : AppTheme.light,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
