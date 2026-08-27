import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/models/credit_note_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/credit_note_repository.dart';
import '../../../data/services/credit_note_pdf_service.dart';

class CreditNoteDetailsController extends GetxController {
  CreditNoteDetailsController(this._creditNotes, this._business, this._pdf);

  final CreditNoteRepository _creditNotes;
  final BusinessRepository _business;
  final CreditNotePdfService _pdf;
  final note = Rxn<CreditNoteModel>();
  final currencySymbol = '₹'.obs;
  final isLoading = true.obs;
  final isWorking = false.obs;

  int get noteId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    currencySymbol.value =
        (await _business.getProfile())?.currencySymbol ?? '₹';
    note.value = await _creditNotes.getById(noteId);
    isLoading.value = false;
  }

  Future<void> share() => _export(
    (note, business) => _pdf.share(note: note, business: business),
    'Unable to share',
  );

  Future<void> printPdf() => _export(
    (note, business) => _pdf.print(note: note, business: business),
    'Unable to print',
  );

  Future<void> _export(
    Future<void> Function(CreditNoteModel note, BusinessProfileModel business)
    action,
    String failureTitle,
  ) async {
    final value = note.value;
    final business = await _business.getProfile();
    if (value == null || business == null) {
      AppNotification.error(
        failureTitle,
        'The credit note could not be loaded.',
      );
      return;
    }
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await action(value, business);
    } catch (_) {
      AppNotification.error(failureTitle, 'The PDF could not be created.');
    } finally {
      isWorking.value = false;
    }
  }
}
