import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/utils/validation_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';

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
  final isLoading = false.obs;
  final isSaving = false.obs;
  CustomerModel? _existing;
  bool _returnToInvoice = false;
  bool _isEditing = false;

  bool get isEditing => _isEditing;
  bool get isInvoiceFlow => _returnToInvoice;

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
      ValidationUtils.requiredIndianMobile(value);

  String? validateGstin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return RegExp(r'^[0-9A-Z]{15}$').hasMatch(value.trim().toUpperCase())
        ? null
        : 'Enter a valid 15-character GSTIN.';
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
          mobile: _optional(mobile.text),
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
      // Only the invoice flow needs the saved model as a route result.
      await AppFocus.dismissKeyboard();
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
      mobile.text = customer.mobile ?? '';
      email.text = customer.email ?? '';
      address.text = customer.address ?? '';
      city.text = customer.city ?? '';
      state.text = customer.state ?? '';
      pinCode.text = customer.pinCode ?? '';
      gstin.text = customer.gstin ?? '';
      notes.text = customer.notes ?? '';
    }
    isLoading.value = false;
  }

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
