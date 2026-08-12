import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/validation_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/image_storage_service.dart';
import '../../../data/services/product_settings_service.dart';

class BusinessSetupController extends GetxController {
  BusinessSetupController(
    this._repository,
    this._storage,
    this._imageStorage,
    this._productSettings,
  );

  final BusinessRepository _repository;
  final AppStorage _storage;
  final ImageStorageService _imageStorage;
  final ProductSettingsService _productSettings;
  final formKey = GlobalKey<FormState>();

  final businessName = TextEditingController();
  final ownerName = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pinCode = TextEditingController();
  final gstin = TextEditingController();
  final pan = TextEditingController();
  final invoicePrefix = TextEditingController();
  final startingInvoiceNumber = TextEditingController();
  final bankName = TextEditingController();
  final accountHolderName = TextEditingController();
  final accountNumber = TextEditingController();
  final ifsc = TextEditingController();
  final upiId = TextEditingController();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final setupStep = 0.obs;
  final gstRegistered = false.obs;
  final currencyCode = 'INR'.obs;
  final businessCategory = BusinessCategory.generalBusiness.obs;
  final logoPath = RxnString();
  final paymentQrPath = RxnString();
  final signaturePath = RxnString();
  BusinessProfileModel? _existing;
  late BusinessCategory _savedCategory;
  String _baseline = '';

  bool get hasUnsavedChanges => !isLoading.value && _snapshot() != _baseline;

  static const currencies = <String, String>{
    'INR': '₹',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
  };

  void continueToDetails() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (requiredBusinessName(businessName.text) != null) {
      formKey.currentState?.validate();
      return;
    }
    setupStep.value = 1;
  }

  void returnToIdentity() => setupStep.value = 0;

  @override
  void onInit() {
    super.onInit();
    _loadExistingProfile();
  }

  Future<void> pickLogo() => _pickImage('logo', logoPath);
  Future<void> pickPaymentQr() => _pickImage('payment_qr', paymentQrPath);
  Future<void> pickSignature() => _pickImage('signature', signaturePath);

  Future<void> _pickImage(String name, RxnString target) async {
    final path = await _imageStorage.pickAndStore(name);
    if (path != null) {
      target.value = path;
    }
  }

  String? requiredBusinessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    return ValidationUtils.optionalEmail(value);
  }

  String? validateMobile(String? value) {
    return ValidationUtils.optionalIndianMobile(value);
  }

  String? validatePinCode(String? value) {
    final pin = value?.trim() ?? '';
    if (pin.isEmpty) return null;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return 'Enter a valid 6 digit PIN code.';
    }
    return null;
  }

  String? validateGstin(String? value) {
    if (!gstRegistered.value) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'GSTIN is required.';
    }
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid GSTIN (for example, 24ABCDE1234F1Z5).';
    }
    return null;
  }

  String? validatePan(String? value) {
    final panNumber = value?.trim().toUpperCase() ?? '';
    if (panNumber.isEmpty) return null;
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(panNumber)) {
      return 'Enter a valid PAN (for example, ABCDE1234F).';
    }
    return null;
  }

  String? validateInvoicePrefix(String? value) {
    final prefix = value?.trim() ?? '';
    if (prefix.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9-]{1,10}$').hasMatch(prefix)) {
      return 'Use 1–10 letters, numbers, or hyphens.';
    }
    return null;
  }

  String? validateStartingInvoiceNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    if (number == null || number < 1) {
      return 'Enter an invoice number greater than 0.';
    }
    return null;
  }

  String? validateAccountNumber(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return null;
    if (!RegExp(r'^\d{6,18}$').hasMatch(number)) {
      return 'Enter a valid 6 to 18 digit account number.';
    }
    return null;
  }

  String? validateIfsc(String? value) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return null;
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(code)) {
      return 'Enter a valid 11-character IFSC.';
    }
    return null;
  }

  String? validateUpiId(String? value) {
    final upi = value?.trim() ?? '';
    if (upi.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9._-]{2,256}@[A-Za-z]{2,64}$').hasMatch(upi)) {
      return 'Enter a valid UPI ID (for example, name@bank).';
    }
    return null;
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final profile = BusinessProfileModel(
        id: _existing?.id,
        businessName: businessName.text.trim(),
        ownerName: _optional(ownerName.text),
        logoPath: logoPath.value,
        mobile: _optional(mobile.text),
        email: _optional(email.text),
        address: _optional(address.text),
        city: _optional(city.text),
        state: _optional(state.text),
        pinCode: _optional(pinCode.text),
        gstRegistered: gstRegistered.value,
        gstin: gstRegistered.value ? _optional(gstin.text.toUpperCase()) : null,
        pan: _optional(pan.text.toUpperCase()),
        invoicePrefix: invoicePrefix.text.trim().isEmpty
            ? 'INV'
            : invoicePrefix.text.trim().toUpperCase(),
        startingInvoiceNumber: int.tryParse(startingInvoiceNumber.text) ?? 1,
        currencyCode: currencyCode.value,
        currencySymbol: currencies[currencyCode.value] ?? '₹',
        bankName: _optional(bankName.text),
        accountHolderName: _optional(accountHolderName.text),
        accountNumber: _optional(accountNumber.text),
        ifsc: _optional(ifsc.text.toUpperCase()),
        upiId: _optional(upiId.text),
        paymentQrPath: paymentQrPath.value,
        signaturePath: signaturePath.value,
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );
      _existing = await _repository.saveProfile(profile);
      if (businessCategory.value != _savedCategory) {
        await _productSettings.changeCategory(businessCategory.value);
        _savedCategory = businessCategory.value;
      }
      _captureBaseline();
      await _storage.setBool(AppStorageKeyConst.businessSetupCompleted, true);
      await AppFocus.dismissKeyboard();
      Get.offAllNamed<void>(AppRoutes.dashboard);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _loadExistingProfile() async {
    businessCategory.value = _productSettings.category;
    _savedCategory = businessCategory.value;
    _existing = await _repository.getProfile();
    final profile = _existing;
    if (profile != null) {
      businessName.text = profile.businessName;
      ownerName.text = profile.ownerName ?? '';
      mobile.text = profile.mobile ?? '';
      email.text = profile.email ?? '';
      address.text = profile.address ?? '';
      city.text = profile.city ?? '';
      state.text = profile.state ?? '';
      pinCode.text = profile.pinCode ?? '';
      gstRegistered.value = profile.gstRegistered;
      gstin.text = profile.gstin ?? '';
      pan.text = profile.pan ?? '';
      invoicePrefix.text = profile.invoicePrefix;
      startingInvoiceNumber.text = '${profile.startingInvoiceNumber}';
      currencyCode.value = profile.currencyCode;
      bankName.text = profile.bankName ?? '';
      accountHolderName.text = profile.accountHolderName ?? '';
      accountNumber.text = profile.accountNumber ?? '';
      ifsc.text = profile.ifsc ?? '';
      upiId.text = profile.upiId ?? '';
      logoPath.value = profile.logoPath;
      paymentQrPath.value = profile.paymentQrPath;
      signaturePath.value = profile.signaturePath;
    }
    _captureBaseline();
    isLoading.value = false;
  }

  String _snapshot() =>
      [
            businessName,
            ownerName,
            mobile,
            email,
            address,
            city,
            state,
            pinCode,
            gstin,
            pan,
            invoicePrefix,
            startingInvoiceNumber,
            bankName,
            accountHolderName,
            accountNumber,
            ifsc,
            upiId,
          ]
          .map((controller) => controller.text)
          .followedBy([
            gstRegistered.value.toString(),
            currencyCode.value,
            businessCategory.value.name,
            logoPath.value ?? '',
            paymentQrPath.value ?? '',
            signaturePath.value ?? '',
          ])
          .join('\u001f');

  void _captureBaseline() => _baseline = _snapshot();

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void onClose() {
    for (final controller in [
      businessName,
      ownerName,
      mobile,
      email,
      address,
      city,
      state,
      pinCode,
      gstin,
      pan,
      invoicePrefix,
      startingInvoiceNumber,
      bankName,
      accountHolderName,
      accountNumber,
      ifsc,
      upiId,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }
}
