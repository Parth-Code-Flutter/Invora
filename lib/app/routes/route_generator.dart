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
import '../../modules/products/bindings/product_bindings.dart';
import '../../modules/products/screens/product_details_screen.dart';
import '../../modules/products/screens/product_form_screen.dart';
import '../../modules/products/screens/product_list_screen.dart';
import '../../modules/invoices/bindings/invoice_binding.dart';
import '../../modules/invoices/screens/invoice_create_screen.dart';
import '../../modules/invoices/screens/invoice_details_screen.dart';
import '../../modules/invoices/screens/invoice_list_screen.dart';
import '../../modules/invoices/screens/invoice_preview_screen.dart';
import '../../modules/reports/bindings/report_binding.dart';
import '../../modules/reports/screens/report_screen.dart';
import '../../modules/backup_restore/bindings/backup_binding.dart';
import '../../modules/backup_restore/screens/backup_screen.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/screens/settings_screen.dart';
import '../../modules/settings/screens/more_screen.dart';
import '../../modules/settings/screens/unit_settings_screen.dart';
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
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.customers,
      page: CustomerListScreen.new,
      binding: CustomerListBinding(),
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
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
    GetPage(
      name: AppRoutes.products,
      page: ProductListScreen.new,
      binding: ProductListBinding(),
    ),
    GetPage(
      name: AppRoutes.productAdd,
      page: ProductFormScreen.new,
      binding: ProductFormBinding(),
    ),
    GetPage(
      name: AppRoutes.productEdit,
      page: ProductFormScreen.new,
      binding: ProductFormBinding(),
    ),
    GetPage(
      name: AppRoutes.productDetails,
      page: ProductDetailsScreen.new,
      binding: ProductDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.invoices,
      page: InvoiceListScreen.new,
      binding: InvoiceListBinding(),
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.quotations,
      page: () => const InvoiceListScreen(quotation: true),
      binding: QuotationListBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceCreate,
      page: InvoiceCreateScreen.new,
      binding: InvoiceCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.quotationCreate,
      page: InvoiceCreateScreen.new,
      binding: QuotationCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceDetails,
      page: InvoiceDetailsScreen.new,
      binding: InvoiceDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.more,
      page: MoreScreen.new,
      binding: MoreBinding(),
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: SettingsScreen.new,
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.unitSettings,
      page: UnitSettingsScreen.new,
      binding: UnitSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.backup,
      page: BackupScreen.new,
      binding: BackupBinding(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: ReportScreen.new,
      binding: ReportBinding(),
    ),
    GetPage(
      name: AppRoutes.invoicePreview,
      page: InvoicePreviewScreen.new,
      binding: InvoicePreviewBinding(),
    ),
  ];
}
