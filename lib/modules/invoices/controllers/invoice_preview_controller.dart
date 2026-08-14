import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/invoice_validation_service.dart';
import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_notification.dart';
import '../models/invoice_success_args.dart';
import '../screens/invoice_save_success_screen.dart';

class InvoicePreviewController extends GetxController {
  InvoicePreviewController(
    this._invoices,
    this._business,
    this._pdf,
    this._storage,
  );
  final InvoiceRepository _invoices;
  final BusinessRepository _business;
  final InvoicePdfService _pdf;
  final AppStorage _storage;
  static const _validator = InvoiceValidationService();
  final invoice = Rxn<InvoiceModel>();
  final business = Rxn<BusinessProfileModel>();
  final template = InvoiceTemplate.professional.obs;
  final isLoading = true.obs;
  final isSavingDocument = false.obs;
  final isReadOnly = false.obs;
  final validationError = RxnString();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final savedTemplate = _storage.getString(
      AppStorageKeyConst.selectedInvoiceTemplate,
    );
    if (savedTemplate != null) {
      template.value = InvoiceTemplate.values.firstWhere(
        (value) => value.name == savedTemplate,
        orElse: () => InvoiceTemplate.professional,
      );
    }
    final argument = Get.arguments;
    if (argument is InvoiceModel) {
      invoice.value = argument;
    } else if (argument is int) {
      invoice.value = await _invoices.getById(argument);
    }
    business.value = await _business.getProfile();
    validationError.value = _requiredValidation();
    isLoading.value = false;
  }

  Future<void> selectTemplate(InvoiceTemplate value) async {
    template.value = value;
    await _storage.setString(
      AppStorageKeyConst.selectedInvoiceTemplate,
      value.name,
    );
  }

  Future<Uint8List> build() async {
    final validation = _requiredValidation();
    if (validation != null) throw StateError(validation);
    return _pdf.build(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
  }

  Future<void> share() async {
    if (!_canContinue()) return;
    await _pdf.shareInvoice(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
  }

  Future<void> savePdf() async {
    if (!_canContinue()) return;
    final path = await _pdf.saveInvoice(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
    if (path != null) AppNotification.success('PDF saved', path);
  }

  Future<void> saveDocument() async {
    final document = invoice.value;
    if (document == null || isSavingDocument.value) return;
    if (!_canContinue()) return;
    isSavingDocument.value = true;
    try {
      final wasUpdate = document.id != null;
      final saved = await _invoices.save(document);
      invoice.value = saved;
      final action = await Get.dialog<InvoiceSaveSuccessAction>(
        InvoiceSaveSuccessDialog(
          arguments: InvoiceSaveSuccessArgs(
            invoiceId: saved.id!,
            invoiceNumber: saved.invoiceNumber,
            documentType: saved.documentType,
            template: template.value,
            wasUpdate: wasUpdate,
          ),
        ),
        barrierDismissible: false,
      );
      if (action == InvoiceSaveSuccessAction.viewPdf) {
        isReadOnly.value = true;
      } else if (action == InvoiceSaveSuccessAction.done) {
        Get.offAllNamed<void>(
          saved.documentType == DocumentType.quotation
              ? AppRoutes.quotations
              : AppRoutes.invoices,
        );
      }
    } finally {
      isSavingDocument.value = false;
    }
  }

  Future<void> print() async {
    if (!_canContinue()) return;
    await _pdf.printInvoice(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
  }

  String? _requiredValidation() {
    final document = invoice.value;
    if (document == null) return 'Invoice is unavailable.';
    final validation = _validator.validateRequired(document);
    if (validation != null) return validation;
    final profile = business.value;
    if (profile == null || profile.businessName.trim().isEmpty) {
      return 'Complete business setup before continuing.';
    }
    return null;
  }

  bool _canContinue() {
    final validation = _requiredValidation();
    validationError.value = validation;
    if (validation != null) {
      AppNotification.warning('Complete required details', validation);
      return false;
    }
    return true;
  }
}
