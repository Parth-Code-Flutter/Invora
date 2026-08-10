import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_payment_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_validation_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_notification.dart';

class InvoiceDetailsController extends GetxController {
  InvoiceDetailsController(this._repository, this._businessRepository);
  final InvoiceRepository _repository;
  final BusinessRepository _businessRepository;
  static const _validator = InvoiceValidationService();
  final invoice = Rxn<InvoiceModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;
  final isWorking = false.obs;
  final payments = <InvoicePaymentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
    final id = Get.arguments;
    if (id is int) {
      invoice.value = await _repository.getById(id);
      payments.assignAll(await _repository.getPayments(id));
    }
    isLoading.value = false;
  }

  Future<void> edit() async {
    final value = invoice.value;
    if (value?.id == null || value!.status.name == 'cancelled') return;
    await Get.toNamed<void>(
      value.documentType == DocumentType.quotation
          ? AppRoutes.quotationCreate
          : AppRoutes.invoiceCreate,
      arguments: value.id,
    );
    await _load();
  }

  Future<void> openPreview() async {
    final value = invoice.value;
    if (value?.id == null) {
      AppNotification.error(
        'Invoice unavailable',
        'The invoice could not be loaded.',
      );
      return;
    }
    final validation = _validator.validateRequired(value!);
    if (validation != null) {
      AppNotification.warning('Complete required details', validation);
      return;
    }
    await Get.toNamed<void>(AppRoutes.invoicePreview, arguments: value.id);
  }

  Future<void> duplicate() async {
    final value = invoice.value;
    if (value?.id == null) return;
    isWorking.value = true;
    try {
      final profile = await _businessRepository.getProfile();
      final number = await _repository.nextInvoiceNumber(
        prefix: profile?.invoicePrefix ?? 'INV',
        startingNumber: profile?.startingInvoiceNumber ?? 1,
      );
      final copy = await _repository.duplicate(
        id: value!.id!,
        newInvoiceNumber: number,
      );
      AppNotification.success(
        'Invoice duplicated',
        '${copy.invoiceNumber} saved as draft.',
      );
      Get.offNamed<void>(AppRoutes.invoiceCreate, arguments: copy.id);
    } finally {
      isWorking.value = false;
    }
  }

  Future<String?> recordPayment(
    String input, {
    String? method,
    String? reference,
    String? note,
  }) async {
    final value = invoice.value;
    if (value?.id == null) return 'Invoice not found.';
    final validation = _validator.validateRequired(value!);
    if (validation != null) return validation;
    final amount = CurrencyUtils.parseMinor(input);
    if (amount == null || amount <= 0) {
      return 'Enter a payment greater than zero.';
    }
    if (amount > value.calculation.balanceDueMinor) {
      return 'Payment cannot exceed the remaining balance.';
    }
    await _repository.recordPayment(
      invoiceId: value.id!,
      amountMinor: amount,
      paidAt: DateTime.now(),
      method: method,
      reference: reference,
      note: note,
    );
    await _load();
    return null;
  }

  Future<void> cancel() async {
    final id = invoice.value?.id;
    if (id == null) return;
    await _repository.cancel(id);
    await _load();
  }

  Future<void> setQuotationStatus(InvoiceStatus status) async {
    final id = invoice.value?.id;
    if (id == null) return;
    await _repository.updateStatus(id, status);
    await _load();
  }

  Future<void> convertToInvoice() async {
    final value = invoice.value;
    if (value?.id == null) return;
    final profile = await _businessRepository.getProfile();
    final number = await _repository.nextInvoiceNumber(
      prefix: profile?.invoicePrefix ?? 'INV',
      startingNumber: profile?.startingInvoiceNumber ?? 1,
    );
    final converted = await _repository.convertQuotationToInvoice(
      quotationId: value!.id!,
      invoiceNumber: number,
    );
    AppNotification.success('Invoice created', converted.invoiceNumber);
    Get.toNamed<void>(AppRoutes.invoiceDetails, arguments: converted.id);
  }

  Future<void> delete() async {
    final id = invoice.value?.id;
    if (id == null) return;
    await _repository.delete(id);
    Get.back(result: true);
  }
}
