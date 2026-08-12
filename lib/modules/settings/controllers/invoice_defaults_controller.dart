import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/tax_type.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/services/invoice_defaults_service.dart';

class InvoiceDefaultsController extends GetxController {
  InvoiceDefaultsController(this._service);

  final InvoiceDefaultsService _service;
  static const standardDueDays = <int>[0, 7, 15, 30];
  static const paymentMethods = <String>[
    'UPI',
    'Cash',
    'Bank transfer',
    'Card',
    'Cheque',
    'Other',
  ];

  final dueDays = 0.obs;
  final customDueDays = TextEditingController();
  final taxType = TaxType.cgstSgst.obs;
  final gstRateBasisPoints = 1800.obs;
  final paymentMethod = 'UPI'.obs;
  final notes = TextEditingController();
  final terms = TextEditingController();
  final isSaving = false.obs;

  bool get usesCustomDueDays => !standardDueDays.contains(dueDays.value);

  @override
  void onInit() {
    super.onInit();
    dueDays.value = _service.dueDays;
    if (usesCustomDueDays) customDueDays.text = dueDays.value.toString();
    taxType.value = _service.taxType;
    gstRateBasisPoints.value = _service.gstRateBasisPoints;
    paymentMethod.value = _service.paymentMethod;
    notes.text = _service.notes;
    terms.text = _service.terms;
  }

  @override
  void onClose() {
    customDueDays.dispose();
    notes.dispose();
    terms.dispose();
    super.onClose();
  }

  void setDueChoice(int value) {
    if (value == -1) {
      dueDays.value = -1;
      customDueDays.clear();
    } else {
      dueDays.value = value;
    }
  }

  Future<void> save() async {
    var resolvedDueDays = dueDays.value;
    if (usesCustomDueDays) {
      resolvedDueDays = int.tryParse(customDueDays.text.trim()) ?? -1;
      if (resolvedDueDays < 1 || resolvedDueDays > 365) {
        AppNotification.warning(
          'Check due period',
          'Custom due days must be between 1 and 365.',
        );
        return;
      }
    }
    if (!TaxUtils.gstRateBasisPoints.contains(gstRateBasisPoints.value)) {
      AppNotification.warning('Check GST rate', 'Choose a supported GST rate.');
      return;
    }
    isSaving.value = true;
    try {
      await _service.save(
        dueDays: resolvedDueDays,
        taxType: taxType.value,
        gstRateBasisPoints: gstRateBasisPoints.value,
        notes: notes.text,
        terms: terms.text,
        paymentMethod: paymentMethod.value,
      );
      dueDays.value = resolvedDueDays;
      AppNotification.success(
        'Invoice defaults saved',
        'New documents will start with these choices.',
      );
    } finally {
      isSaving.value = false;
    }
  }
}
