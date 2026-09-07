import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/utils/validation_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/services/account_phone.dart';
import '../../../data/services/gst_indian_states.dart';

class CustomerFormController extends GetxController {
  CustomerFormController(this._repository);

  final CustomerRepository _repository;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final companyName = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pinCode = TextEditingController();
  final gstin = TextEditingController();
  final notes = TextEditingController();
  final country = AccountCountry.india.obs;
  final gstState = Rxn<GstIndianState>();
  final gstinLooksValid = false.obs;
  final createInvoiceAfterSave = false.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isImportingContact = false.obs;
  CustomerModel? _existing;
  bool _returnToInvoice = false;
  bool _isEditing = false;
  String _baseline = '';

  bool get isEditing => _isEditing;
  bool get isInvoiceFlow => _returnToInvoice;
  bool get hasUnsavedChanges => !isLoading.value && _snapshot() != _baseline;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    final id = arguments is int
        ? arguments
        : arguments is CustomerFormArgs
        ? arguments.customerId
        : null;
    _returnToInvoice =
        arguments is CustomerFormArgs && arguments.returnToInvoice;
    _isEditing = id != null;
    createInvoiceAfterSave.value = !_isEditing && !_returnToInvoice;
    _captureBaseline();
    if (id != null) {
      _load(id);
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customer name is required.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    return ValidationUtils.optionalEmail(value);
  }

  String? validateMobile(String? value) =>
      AccountPhone.validateNational(value, country: country.value);

  String? validateGstin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return RegExp(r'^[0-9A-Z]{15}$').hasMatch(value.trim().toUpperCase())
        ? null
        : 'Enter a valid 15-character GSTIN.';
  }

  void selectCountry(AccountCountry selected) {
    country.value = selected;
    if (mobile.text.trim().isNotEmpty) {
      formKey.currentState?.validate();
    }
  }

  void selectGstState(GstIndianState? selected) {
    gstState.value = selected;
    state.text = selected?.name ?? '';
  }

  void selectGstStateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      gstState.value = null;
      state.text = '';
      return;
    }
    gstState.value = GstIndianStates.match(trimmed);
    state.text = gstState.value?.name ?? trimmed;
  }

  void onGstinChanged(String value) {
    _syncGstinLooksValid();
    if (value.trim().length < 2) return;
    final matched = GstIndianStates.match(value.trim().substring(0, 2));
    if (matched != null) selectGstState(matched);
  }

  Future<void> importPhoneContact() async {
    if (isEditing || isImportingContact.value) return;
    isImportingContact.value = true;
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.limited) {
        AppNotification.warning(
          'Contacts permission needed',
          'Allow contact access to import a customer from your phone.',
        );
        return;
      }
      final contact = await FlutterContacts.native.showPicker(
        properties: const {ContactProperty.phone},
      );
      if (contact == null) return;
      if (contact.phones.isEmpty) {
        AppNotification.info(
          'No mobile number',
          'The selected contact does not have a phone number.',
        );
        return;
      }
      final importedName = contact.displayName?.trim() ?? '';
      final parsed = AccountPhone.parseImported(contact.phones.first.number);
      if (parsed == null) {
        AppNotification.warning(
          'Unsupported number',
          'Choose a contact with a valid mobile number.',
        );
        return;
      }
      if (importedName.isNotEmpty) name.text = importedName;
      country.value = parsed.country;
      mobile
        ..text = parsed.national
        ..selection = TextSelection.collapsed(offset: parsed.national.length);
      AppNotification.success(
        'Contact imported',
        importedName.isEmpty
            ? 'Mobile number added. Enter the customer name to continue.'
            : '$importedName is ready to save.',
      );
    } on PlatformException {
      AppNotification.error(
        'Could not open contacts',
        'Check contact permission in device settings and try again.',
      );
    } finally {
      isImportingContact.value = false;
    }
  }

  static String normalizeIndianMobile(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? digits : '';
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final saved = await _repository.save(
        CustomerModel(
          id: _existing?.id,
          name: name.text.trim(),
          companyName: _optional(companyName.text),
          mobile: _optional(
            AccountPhone.toE164(mobile.text, country: country.value),
          ),
          email: _optional(email.text),
          address: _optional(address.text),
          city: _optional(city.text),
          state: _optional(state.text),
          pinCode: _optional(pinCode.text),
          gstin: _optional(gstin.text.toUpperCase()),
          notes: _optional(notes.text),
          createdAt: _existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      _captureBaseline();
      await AppFocus.dismissKeyboard();
      final openInvoice =
          !isEditing &&
          !isInvoiceFlow &&
          createInvoiceAfterSave.value &&
          saved.id != null;
      if (openInvoice) {
        await Get.offNamed<void>(
          AppRoutes.invoiceCreate,
          arguments: InvoiceEditorArgs(customerId: saved.id),
        );
        return;
      }
      Get.back(result: isInvoiceFlow ? saved : null);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _load(int id) async {
    isLoading.value = true;
    _existing = await _repository.getById(id);
    final customer = _existing;
    if (customer != null) {
      name.text = customer.name;
      companyName.text = customer.companyName ?? '';
      _applyStoredMobile(customer.mobile);
      email.text = customer.email ?? '';
      address.text = customer.address ?? '';
      city.text = customer.city ?? '';
      selectGstStateName(customer.state ?? '');
      pinCode.text = customer.pinCode ?? '';
      gstin.text = customer.gstin ?? '';
      notes.text = customer.notes ?? '';
      _syncGstinLooksValid();
    }
    _captureBaseline();
    isLoading.value = false;
  }

  void _applyStoredMobile(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      country.value = AccountCountry.india;
      mobile.clear();
      return;
    }
    final parsed = AccountPhone.parseImported(value);
    if (parsed != null) {
      country.value = parsed.country;
      mobile.text = parsed.national;
      return;
    }
    country.value = AccountCountry.india;
    mobile.text = AccountPhone.nationalNumber(value);
  }

  void _syncGstinLooksValid() {
    final trimmed = gstin.text.trim().toUpperCase();
    gstinLooksValid.value =
        trimmed.length == 15 && validateGstin(trimmed) == null;
  }

  String _snapshot() => [
    name.text,
    companyName.text,
    country.value.iso,
    mobile.text,
    email.text,
    address.text,
    city.text,
    state.text,
    pinCode.text,
    gstin.text,
    notes.text,
  ].join('\u001f');

  void _captureBaseline() => _baseline = _snapshot();

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void onClose() {
    for (final controller in [
      name,
      companyName,
      mobile,
      email,
      address,
      city,
      state,
      pinCode,
      gstin,
      notes,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }
}

class CustomerFormArgs {
  const CustomerFormArgs({this.customerId, this.returnToInvoice = false});

  final int? customerId;
  final bool returnToInvoice;
}
