import 'package:get/get.dart';

import '../../modules/splash/screens/splash_screen.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/onboarding/bindings/onboarding_binding.dart';
import '../../modules/onboarding/screens/onboarding_screen.dart';
import '../../modules/business_setup/bindings/business_setup_binding.dart';
import '../../modules/business_setup/screens/business_setup_screen.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/screens/dashboard_screen.dart';
import '../../modules/customers/bindings/customer_bindings.dart';
import '../../modules/customers/screens/customer_details_screen.dart';
import '../../modules/customers/screens/customer_form_screen.dart';
import '../../modules/customers/screens/customer_list_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static const initialRoute = AppRoutes.splash;

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: OnboardingScreen.new,
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.businessSetup,
      page: BusinessSetupScreen.new,
      binding: BusinessSetupBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: DashboardScreen.new,
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.customers,
      page: CustomerListScreen.new,
      binding: CustomerListBinding(),
    ),
    GetPage(
      name: AppRoutes.customerAdd,
      page: CustomerFormScreen.new,
      binding: CustomerFormBinding(),
    ),
    GetPage(
      name: AppRoutes.customerEdit,
      page: CustomerFormScreen.new,
      binding: CustomerFormBinding(),
    ),
    GetPage(
      name: AppRoutes.customerDetails,
      page: CustomerDetailsScreen.new,
      binding: CustomerDetailsBinding(),
    ),
  ];
}
