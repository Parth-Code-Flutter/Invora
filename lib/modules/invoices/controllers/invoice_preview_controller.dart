import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../data/models/business_profile_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../../../data/services/app_storage.dart';
import '../../../app/constants/app_storage_key_const.dart';

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
    final id = Get.arguments;
    if (id is int) invoice.value = await _invoices.getById(id);
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

  Future<void> save() async {
    final path = await _pdf.saveInvoice(
      invoice: invoice.value!,
      business: business.value!,
      template: template.value,
    );
    if (path != null) Get.snackbar('PDF saved', path);
  }

  Future<void> print() => _pdf.printInvoice(
    invoice: invoice.value!,
    business: business.value!,
    template: template.value,
  );
}
