import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/constants/app_constants.dart';
import 'app/constants/dock_icons.dart';
import 'app/constants/app_storage_key_const.dart';
import 'app/localization/app_localization.dart';
import 'app/routes/route_generator.dart';
import 'app/themes/app_theme.dart';
import 'data/services/account_auth_service.dart';
import 'data/services/app_database.dart';
import 'data/services/app_storage.dart';
import 'data/services/firebase_account_auth_service.dart';
import 'data/services/local_database_service.dart';
import 'data/services/app_lock_service.dart';
import 'firebase_options.dart';
import 'modules/settings/screens/app_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DockIcons.preload();
  final appStorage = await AppStorage.create();
  final databaseService = LocalDatabaseService(AppDatabase());
  await databaseService.initialize();
  runApp(
    CreovoInvoiceApp(
      appStorage: appStorage,
      databaseService: databaseService,
      accountAuth: await _createAccountAuth(),
    ),
  );
}

Future<AccountAuthService> _createAccountAuth() async {
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on UnsupportedError {
        await Firebase.initializeApp();
      }
    }
    return FirebaseAccountAuthService();
  } catch (error, stackTrace) {
    debugPrint('Firebase init failed: $error');
    debugPrint('$stackTrace');
    return UnconfiguredAccountAuthService();
  }
}

class CreovoInvoiceApp extends StatelessWidget {
  const CreovoInvoiceApp({
    required this.appStorage,
    required this.databaseService,
    this.accountAuth,
    super.key,
  });

  final AppStorage appStorage;
  final LocalDatabaseService databaseService;
  final AccountAuthService? accountAuth;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(
        appStorage,
        databaseService,
        accountAuth: accountAuth,
      ),
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
