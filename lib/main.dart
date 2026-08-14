import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/constants/app_constants.dart';
import 'app/constants/app_storage_key_const.dart';
import 'app/localization/app_localization.dart';
import 'app/routes/route_generator.dart';
import 'app/themes/app_theme.dart';
import 'data/services/app_database.dart';
import 'data/services/app_storage.dart';
import 'data/services/local_database_service.dart';
import 'data/services/app_lock_service.dart';
import 'modules/settings/screens/app_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStorage = await AppStorage.create();
  final databaseService = LocalDatabaseService(AppDatabase());
  await databaseService.initialize();
  runApp(
    CreovoInvoiceApp(appStorage: appStorage, databaseService: databaseService),
  );
}

class CreovoInvoiceApp extends StatelessWidget {
  const CreovoInvoiceApp({
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
      themeMode: _initialThemeMode,
      translations: AppTranslations(),
      locale: AppLanguage.fromCode(
        appStorage.getString(AppStorageKeyConst.languageCode),
      ).locale,
      fallbackLocale: AppLanguage.english.locale,
      supportedLocales: AppLanguage.values
          .map((language) => language.locale)
          .toList(growable: false),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => AppLockGate(
        service: Get.find<AppLockService>(),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  ThemeMode get _initialThemeMode {
    final stored = appStorage.getBool(AppStorageKeyConst.isDarkMode);
    if (stored == null) return ThemeMode.system;
    return stored ? ThemeMode.dark : ThemeMode.light;
  }
}
