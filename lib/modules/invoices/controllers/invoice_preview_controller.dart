import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../../../data/services/app_storage.dart';
import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';

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
  final invoice = Rxn<InvoiceModel>();
  final business = Rxn<BusinessProfileModel>();
  final template = InvoiceTemplate.professional.obs;
  final isLoading = true.obs;
  final isSavingDocument = false.obs;

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
    isLoading.value = false;
  }

  Future<void> selectTemplate(InvoiceTemplate value) async {
    template.value = value;
    await _storage.setString(
      AppStorageKeyConst.selectedInvoiceTemplate,
      value.name,
    );
  }

  Future<Uint8List> build() => _pdf.build(
    invoice: invoice.value!,
    business: business.value!,
    template: template.value,
  );

  Future<void> share() => _pdf.shareInvoice(
    invoice: invoice.value!,
    business: business.value!,
    template: template.value,
  );

  Future<void> savePdf() async {
    final path = await _pdf.saveInvoice(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
    if (path != null) Get.snackbar('PDF saved', path);
  }

  Future<void> saveDocument() async {
    final document = invoice.value;
    if (document == null || isSavingDocument.value) return;
    isSavingDocument.value = true;
    try {
      final saved = await _invoices.save(document);
      invoice.value = saved;
      Get.snackbar('Invoice saved', saved.invoiceNumber);
      Get.offAllNamed<void>(AppRoutes.invoices);
    } finally {
      isSavingDocument.value = false;
    }
  }

  Future<void> print() => _pdf.printInvoice(
    invoice: invoice.value!,
    business: business.value!,
    template: template.value,
  );
}
