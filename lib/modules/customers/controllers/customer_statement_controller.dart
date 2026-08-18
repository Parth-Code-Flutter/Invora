import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/models/customer_statement_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/services/customer_statement_pdf_service.dart';
import '../../../data/services/customer_statement_service.dart';

class CustomerStatementController extends GetxController {
  CustomerStatementController(
    this._customers,
    this._business,
    this._statements,
    this._pdf,
  );

  final CustomerRepository _customers;
  final BusinessRepository _business;
  final CustomerStatementService _statements;
  final CustomerStatementPdfService _pdf;
  final statement = Rxn<CustomerStatementModel>();
  final isLoading = true.obs;
  final from = DateTime(DateTime.now().year, 1, 1).obs;
  final to = DateTime.now().obs;

  int get customerId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    final customer = await _customers.getById(customerId);
    final business = await _business.getProfile();
    if (customer != null && business != null) {
      statement.value = await _statements.build(
        customer: customer,
        business: business,
        from: from.value,
        to: to.value,
      );
    }
    isLoading.value = false;
  }

  Future<void> setFrom(DateTime value) async {
    from.value = value;
    if (to.value.isBefore(value)) to.value = value;
    await reload();
  }

  Future<void> setTo(DateTime value) async {
    to.value = value;
    if (from.value.isAfter(value)) from.value = value;
    await reload();
  }

  Future<void> setRange(DateTime start, DateTime end) async {
    final fromDay = DateTime(start.year, start.month, start.day);
    final toDay = DateTime(end.year, end.month, end.day);
    from.value = fromDay.isAfter(toDay) ? toDay : fromDay;
    to.value = toDay.isBefore(from.value) ? from.value : toDay;
    await reload();
  }

  Future<Uint8List> buildPdf() => _pdf.build(statement.value!);
  Future<void> share() => _pdf.shareStatement(statement.value!);
  Future<void> print() => _pdf.printStatement(statement.value!);
  Future<void> save() async {
    final path = await _pdf.saveStatement(statement.value!);
    if (path != null) AppNotification.success('Statement saved', path);
  }
}
