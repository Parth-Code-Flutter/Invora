import 'package:get/get.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../data/models/credit_note_model.dart';
import '../../../data/models/delivery_challan_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/delivery_challan_repository.dart';
import '../../../data/models/invoice_payment_model.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/credit_note_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../../../data/services/invoice_validation_service.dart';
import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_notification.dart';

class InvoiceDetailsController extends GetxController {
  InvoiceDetailsController(
    this._repository,
    this._creditNotes,
    this._businessRepository,
    this._pdf,
    this._storage, {
    DeliveryChallanRepository? challans,
  }) : _challans = challans;
  final InvoiceRepository _repository;
  final CreditNoteRepository _creditNotes;
  final BusinessRepository _businessRepository;
  final InvoicePdfService _pdf;
  final AppStorage _storage;
  final DeliveryChallanRepository? _challans;
  static const _validator = InvoiceValidationService();
  final invoice = Rxn<InvoiceModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;
  final isWorking = false.obs;
  final payments = <InvoicePaymentModel>[].obs;
  final creditNotes = <CreditNoteSummaryModel>[].obs;
  final unappliedCredits = <CreditNoteSummaryModel>[].obs;
  final lastRecordedPayment = Rxn<InvoicePaymentModel>();
  int? _invoiceId;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    _invoiceId = argument is int ? argument : null;
    reload();
  }

  Future<void> reload() async {
    currencySymbol.value =
        (await _businessRepository.getProfile())?.currencySymbol ?? '₹';
    final id = _invoiceId ?? invoice.value?.id;
    if (id != null) {
      final refreshedInvoice = await _repository.getById(id);
      final refreshedPayments = await _repository.getPayments(id);
      invoice.value = refreshedInvoice;
      // Explicit notifications make the details screen deterministic after a
      // modal route closes, even when GetX considers the assigned value equal.
      invoice.refresh();
      payments.assignAll(refreshedPayments);
      payments.refresh();
      creditNotes.assignAll(await _creditNotes.listForInvoice(id));
      final customerId = refreshedInvoice?.customer.customerId;
      unappliedCredits.assignAll(
        customerId == null
            ? const []
            : await _creditNotes.unappliedForCustomer(customerId),
      );
    }
    isLoading.value = false;
  }

  Future<void> edit() async {
    final value = invoice.value;
    if (value?.id == null || value!.status.name == 'cancelled') return;
    if (creditNotes.isNotEmpty) {
      AppNotification.warning(
        'Invoice locked',
        'This invoice has a credit note and can no longer be edited.',
      );
      return;
    }
    await Get.toNamed<void>(
      value.documentType == DocumentType.quotation
          ? AppRoutes.quotationCreate
          : AppRoutes.invoiceCreate,
      arguments: value.id,
    );
    await reload();
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

  Future<void> share() => _exportPdf(
    (invoice, business, template) => _pdf.shareInvoice(
      invoice: invoice,
      business: business,
      template: template,
    ),
    failureTitle: 'Unable to share',
    failureMessage: 'The PDF could not be shared.',
  );

  Future<void> print() => _exportPdf(
    (invoice, business, template) => _pdf.printInvoice(
      invoice: invoice,
      business: business,
      template: template,
    ),
    failureTitle: 'Unable to print',
    failureMessage: 'The PDF could not be printed.',
  );

  Future<void> _exportPdf(
    Future<void> Function(
      InvoiceModel invoice,
      BusinessProfileModel business,
      InvoiceTemplate template,
    )
    action, {
    required String failureTitle,
    required String failureMessage,
  }) async {
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
    final business = await _businessRepository.getProfile();
    if (business == null || business.businessName.trim().isEmpty) {
      AppNotification.warning(
        'Complete required details',
        'Complete business setup before continuing.',
      );
      return;
    }
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await action(value, business, _selectedTemplate);
    } catch (_) {
      AppNotification.error(failureTitle, failureMessage);
    } finally {
      isWorking.value = false;
    }
  }

  InvoiceTemplate get _selectedTemplate {
    final saved = _storage.getString(
      AppStorageKeyConst.selectedInvoiceTemplate,
    );
    return InvoiceTemplate.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => InvoiceTemplate.professional,
    );
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
    int? accountId,
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
      accountId: accountId,
    );
    await reload();
    lastRecordedPayment.value = payments.firstWhereOrNull(
      (payment) =>
          payment.amountMinor == amount &&
          payment.entryType == InvoicePaymentEntryType.payment,
    );
    return null;
  }

  Future<String?> reversePayment(
    InvoicePaymentModel payment,
    String reason,
  ) async {
    final value = invoice.value;
    if (value?.id == null || payment.id == null) return 'Payment not found.';
    if (!payment.canReverse) return 'This payment cannot be reversed.';
    if (reason.trim().isEmpty) return 'Enter a reason for the reversal.';
    try {
      await _repository.reversePayment(
        invoiceId: value!.id!,
        paymentId: payment.id!,
        reason: reason,
        reversedAt: DateTime.now(),
      );
      await reload();
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not reverse payment.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<void> cancel() async {
    final id = invoice.value?.id;
    if (id == null) return;
    if (creditNotes.isNotEmpty) {
      AppNotification.warning(
        'Invoice locked',
        'This invoice has a credit note and cannot be cancelled.',
      );
      return;
    }
    await _repository.cancel(id);
    await reload();
  }

  Future<void> setQuotationStatus(InvoiceStatus status) async {
    final id = invoice.value?.id;
    if (id == null) return;
    await _repository.updateStatus(id, status);
    await reload();
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

  Future<void> createDeliveryChallan() async {
    final value = invoice.value;
    if (value?.id == null || value!.status == InvoiceStatus.cancelled) {
      AppNotification.warning(
        'Cannot create challan',
        'Delivery challans can be created from a quotation or an active invoice.',
      );
      return;
    }
    final isQuotation = value.documentType == DocumentType.quotation;
    final challans = _challans;
    if (challans != null) {
      final remaining = await challans.remainingLinesFromDocument(
        value,
        sourceType: isQuotation
            ? DeliveryChallanSourceType.quotation
            : DeliveryChallanSourceType.invoice,
      );
      if (remaining.isEmpty) {
        AppNotification.warning(
          'Cannot create challan',
          'No remaining quantity to dispatch.',
        );
        return;
      }
    }
    await Get.toNamed<void>(
      AppRoutes.deliveryChallanCreate,
      arguments: isQuotation
          ? DeliveryChallanEditorArgs(quotationId: value.id)
          : DeliveryChallanEditorArgs(invoiceId: value.id),
    );
  }

  bool get canIssueCreditNote {
    final value = invoice.value;
    if (value == null || value.id == null) return false;
    if (value.documentType != DocumentType.invoice) return false;
    if (value.status == InvoiceStatus.draft ||
        value.status == InvoiceStatus.cancelled) {
      return false;
    }
    final creditedValue = creditNotes.fold<int>(
      0,
      (total, note) => total + note.grandTotalMinor,
    );
    return creditedValue < value.calculation.grandTotalMinor;
  }

  Future<String?> applyCustomerCredit(
    CreditNoteSummaryModel note,
    int amountMinor,
  ) async {
    final value = invoice.value;
    if (value?.id == null) return 'Invoice not found.';
    try {
      await _creditNotes.applyUnapplied(
        creditNoteId: note.id,
        invoiceId: value!.id!,
        amountMinor: amountMinor,
      );
      await reload();
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not apply credit.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<void> delete() async {
    final id = invoice.value?.id;
    if (id == null) return;
    if (creditNotes.isNotEmpty) {
      AppNotification.warning(
        'Invoice locked',
        'This invoice has a credit note and cannot be deleted.',
      );
      return;
    }
    await _repository.delete(id);
    Get.back(result: true);
  }
}
