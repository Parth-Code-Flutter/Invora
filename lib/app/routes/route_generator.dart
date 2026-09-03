import 'package:get/get.dart';

import '../../modules/account/bindings/account_otp_binding.dart';
import '../../modules/account/screens/account_otp_screen.dart';
import '../../modules/splash/screens/splash_screen.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/onboarding/bindings/onboarding_binding.dart';
import '../../modules/onboarding/screens/onboarding_screen.dart';
import '../../modules/onboarding/screens/workspace_setup_screen.dart';
import '../../modules/purchases/screens/purchase_workspace_screen.dart';
import '../../modules/purchases/screens/purchase_screens.dart';
import '../../modules/purchases/screens/purchase_bill_pdf_screen.dart';
import '../../modules/purchases/screens/debit_note_create_screen.dart';
import '../../modules/purchases/screens/debit_note_details_screen.dart';
import '../../modules/purchases/bindings/purchase_binding.dart';
import '../../modules/business_setup/bindings/business_setup_binding.dart';
import '../../modules/business_setup/screens/business_setup_screen.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/screens/dashboard_screen.dart';
import '../../modules/customers/bindings/customer_bindings.dart';
import '../../modules/customers/screens/customer_details_screen.dart';
import '../../modules/customers/screens/customer_form_screen.dart';
import '../../modules/customers/screens/customer_list_screen.dart';
import '../../modules/customers/screens/customer_statement_screen.dart';
import '../../modules/products/bindings/product_bindings.dart';
import '../../modules/products/screens/product_details_screen.dart';
import '../../modules/products/screens/product_form_screen.dart';
import '../../modules/products/screens/product_list_screen.dart';
import '../../modules/invoices/bindings/invoice_binding.dart';
import '../../modules/invoices/screens/invoice_create_screen.dart';
import '../../modules/invoices/screens/invoice_item_picker_screen.dart';
import '../../modules/invoices/scan/product_scan_screen.dart';
import '../../modules/products/screens/catalog_barcode_scan_screen.dart';
import '../../modules/scan/barcode_capture_screen.dart';
import '../../modules/invoices/screens/invoice_details_screen.dart';
import '../../modules/invoices/screens/credit_note_create_screen.dart';
import '../../modules/invoices/screens/credit_note_details_screen.dart';
import '../../modules/invoices/screens/invoice_list_screen.dart';
import '../../modules/invoices/screens/invoice_preview_screen.dart';
import '../../modules/invoices/screens/payment_receipt_screen.dart';
import '../../modules/reports/bindings/report_binding.dart';
import '../../modules/reports/screens/report_screen.dart';
import '../../modules/reports/screens/gst_export_screen.dart';
import '../../modules/reports/screens/ageing_screen.dart';
import '../../modules/reports/screens/stock_report_screen.dart';
import '../../modules/expenses/bindings/expense_binding.dart';
import '../../modules/expenses/screens/expense_list_screen.dart';
import '../../modules/expenses/screens/expense_details_screen.dart';
import '../../modules/delivery_challans/bindings/delivery_challan_binding.dart';
import '../../modules/delivery_challans/screens/delivery_challan_list_screen.dart';
import '../../modules/delivery_challans/screens/delivery_challan_form_screen.dart';
import '../../modules/delivery_challans/screens/delivery_challan_details_screen.dart';
import '../../modules/purchase_orders/bindings/purchase_order_binding.dart';
import '../../modules/purchase_orders/screens/purchase_order_list_screen.dart';
import '../../modules/purchase_orders/screens/purchase_order_form_screen.dart';
import '../../modules/purchase_orders/screens/purchase_order_details_screen.dart';
import '../../modules/cash_book/bindings/cash_book_binding.dart';
import '../../modules/cash_book/screens/cash_book_screen.dart';
import '../../modules/cash_book/screens/account_statement_screen.dart';
import '../../modules/cash_book/screens/advance_form_screen.dart';
import '../../data/services/backup_service.dart';
import '../../modules/backup_restore/bindings/backup_binding.dart';
import '../../modules/backup_restore/screens/backup_screen.dart';
import '../../modules/backup_restore/screens/restore_status_screen.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/screens/settings_screen.dart';
import '../../modules/settings/screens/about_screen.dart';
import '../../modules/settings/screens/invoice_defaults_screen.dart';
import '../../modules/settings/screens/data_export_screen.dart';
import '../../modules/settings/screens/data_import_screen.dart';
import '../../modules/settings/screens/product_settings_screen.dart';
import '../../modules/settings/screens/stock_opening_screen.dart';
import '../../modules/settings/screens/stock_list_screen.dart';
import '../../modules/settings/screens/more_screen.dart';
import '../../modules/settings/screens/unit_settings_screen.dart';
import '../../modules/settings/screens/app_lock_screen.dart';
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
      name: AppRoutes.accountOtp,
      page: AccountOtpScreen.new,
      binding: AccountOtpBinding(),
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
      name: AppRoutes.workspaceSetup,
      page: WorkspaceSetupScreen.new,
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.purchases,
      page: PurchaseWorkspaceScreen.new,
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.purchaseBills,
      page: PurchaseBillListScreen.new,
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.purchaseBillCreate,
      page: PurchaseBillFormScreen.new,
    ),
    GetPage(
      name: AppRoutes.purchaseBillDetails,
      page: PurchaseBillDetailsScreen.new,
    ),
    GetPage(name: AppRoutes.purchaseBillPdf, page: PurchaseBillPdfScreen.new),
    GetPage(
      name: AppRoutes.debitNoteCreate,
      page: DebitNoteCreateScreen.new,
      binding: DebitNoteCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.debitNoteDetails,
      page: DebitNoteDetailsScreen.new,
      binding: DebitNoteDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.suppliers,
      page: SupplierListScreen.new,
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(name: AppRoutes.supplierAdd, page: SupplierFormScreen.new),
    GetPage(
      name: AppRoutes.supplierStatement,
      page: SupplierStatementScreen.new,
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
      name: AppRoutes.customerStatement,
      page: CustomerStatementScreen.new,
      binding: CustomerStatementBinding(),
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
      name: AppRoutes.invoiceItemPicker,
      page: InvoiceItemPickerScreen.new,
    ),
    GetPage(
      name: AppRoutes.productScan,
      page: ProductScanScreen.new,
      binding: ProductScanBinding(),
    ),
    GetPage(name: AppRoutes.catalogScan, page: CatalogBarcodeScanScreen.new),
    GetPage(name: AppRoutes.barcodeCapture, page: BarcodeCaptureScreen.new),
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
      name: AppRoutes.creditNoteCreate,
      page: CreditNoteCreateScreen.new,
      binding: CreditNoteCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.creditNoteDetails,
      page: CreditNoteDetailsScreen.new,
      binding: CreditNoteDetailsBinding(),
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
      name: AppRoutes.about,
      page: AboutScreen.new,
      binding: AboutBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceDefaults,
      page: InvoiceDefaultsScreen.new,
      binding: InvoiceDefaultsBinding(),
    ),
    GetPage(
      name: AppRoutes.dataExport,
      page: DataExportScreen.new,
      binding: DataExportBinding(),
    ),
    GetPage(
      name: AppRoutes.dataImport,
      page: DataImportScreen.new,
      binding: DataImportBinding(),
    ),
    GetPage(
      name: AppRoutes.productSettings,
      page: ProductSettingsScreen.new,
      binding: ProductSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.stockOpening,
      page: StockOpeningScreen.new,
      binding: StockOpeningBinding(),
    ),
    GetPage(
      name: AppRoutes.stock,
      page: StockListScreen.new,
      binding: StockBinding(),
    ),
    GetPage(
      name: AppRoutes.unitSettings,
      page: UnitSettingsScreen.new,
      binding: UnitSettingsBinding(),
    ),
    GetPage(name: AppRoutes.appLock, page: AppLockSettingsScreen.new),
    GetPage(
      name: AppRoutes.backup,
      page: BackupScreen.new,
      binding: BackupBinding(),
    ),
    GetPage(
      name: AppRoutes.restoreStatus,
      page: () {
        final args = Get.arguments;
        if (args is RestoreBackupRequest) {
          return RestoreStatusScreen(path: args.path, password: args.password);
        }
        return RestoreStatusScreen(path: args as String);
      },
    ),
    GetPage(
      name: AppRoutes.reports,
      page: ReportScreen.new,
      binding: ReportBinding(),
    ),
    GetPage(
      name: AppRoutes.gstExport,
      page: GstExportScreen.new,
      binding: GstExportBinding(),
    ),
    GetPage(
      name: AppRoutes.ageing,
      page: AgeingScreen.new,
      binding: AgeingBinding(),
    ),
    GetPage(
      name: AppRoutes.stockReports,
      page: StockReportScreen.new,
      binding: StockReportBinding(),
    ),
    GetPage(
      name: AppRoutes.expenses,
      page: ExpenseListScreen.new,
      binding: ExpenseListBinding(),
    ),
    GetPage(
      name: AppRoutes.expenseCreate,
      page: ExpenseFormScreen.new,
      binding: ExpenseFormBinding(),
    ),
    GetPage(
      name: AppRoutes.expenseEdit,
      page: ExpenseFormScreen.new,
      binding: ExpenseFormBinding(),
    ),
    GetPage(
      name: AppRoutes.expenseDetails,
      page: ExpenseDetailsScreen.new,
      binding: ExpenseDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.deliveryChallans,
      page: DeliveryChallanListScreen.new,
      binding: DeliveryChallanListBinding(),
    ),
    GetPage(
      name: AppRoutes.deliveryChallanCreate,
      page: DeliveryChallanFormScreen.new,
      binding: DeliveryChallanFormBinding(),
    ),
    GetPage(
      name: AppRoutes.deliveryChallanEdit,
      page: DeliveryChallanFormScreen.new,
      binding: DeliveryChallanFormBinding(),
    ),
    GetPage(
      name: AppRoutes.deliveryChallanDetails,
      page: DeliveryChallanDetailsScreen.new,
      binding: DeliveryChallanDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.deliveryChallanConvert,
      page: DeliveryChallanConvertScreen.new,
      binding: DeliveryChallanConvertBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseOrders,
      page: PurchaseOrderListScreen.new,
      binding: PurchaseOrderListBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseOrderCreate,
      page: PurchaseOrderFormScreen.new,
      binding: PurchaseOrderFormBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseOrderEdit,
      page: PurchaseOrderFormScreen.new,
      binding: PurchaseOrderFormBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseOrderDetails,
      page: PurchaseOrderDetailsScreen.new,
      binding: PurchaseOrderDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseOrderConvert,
      page: PurchaseOrderConvertScreen.new,
      binding: PurchaseOrderConvertBinding(),
    ),
    GetPage(
      name: AppRoutes.cashBook,
      page: CashBookScreen.new,
      binding: CashBookBinding(),
    ),
    GetPage(
      name: AppRoutes.cashBookStatement,
      page: AccountStatementScreen.new,
      binding: AccountStatementBinding(),
    ),
    GetPage(
      name: AppRoutes.cashBookAdvance,
      page: AdvanceFormScreen.new,
      binding: AdvanceFormBinding(),
    ),
    GetPage(
      name: AppRoutes.invoicePreview,
      page: InvoicePreviewScreen.new,
      binding: InvoicePreviewBinding(),
    ),
    GetPage(
      name: AppRoutes.paymentReceipt,
      page: PaymentReceiptScreen.new,
      binding: PaymentReceiptBinding(),
    ),
  ];
}
