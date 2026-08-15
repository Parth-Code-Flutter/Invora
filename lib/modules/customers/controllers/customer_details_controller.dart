import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

class CustomerDetailsController extends GetxController {
  CustomerDetailsController(this._repository, this._invoices, this._business);

  final CustomerRepository _repository;
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final customer = Rxn<CustomerModel>();
  final invoices = <InvoiceSummaryModel>[].obs;
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;

  int get customerId => Get.arguments as int;
  int get outstandingMinor =>
      invoices.fold(0, (sum, item) => sum + item.balanceMinor);
  int get billedMinor =>
      invoices.fold(0, (sum, item) => sum + item.grandTotalMinor);
  int get paidMinor => billedMinor - outstandingMinor;
  bool get hasOverdue => invoices.any(
    (item) => item.effectiveStatus(DateTime.now()) == InvoiceStatus.overdue,
  );

  @override
  void onInit() {
    super.onInit();
    refreshCustomer();
  }

  Future<void> refreshCustomer() async {
    isLoading.value = true;
    customer.value = await _repository.getById(customerId);
    currencySymbol.value =
        (await _business.getProfile())?.currencySymbol ?? '₹';
    invoices.bindStream(_invoices.watchCustomerInvoices(customerId));
    isLoading.value = false;
  }
}
