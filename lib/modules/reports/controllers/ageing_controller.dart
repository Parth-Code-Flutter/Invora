import 'package:get/get.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../app/localization/app_localization.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/ageing_model.dart';
import '../../../data/services/ageing_service.dart';

class AgeingController extends GetxController {
  AgeingController(this._service);

  final AgeingService _service;
  final pack = Rxn<AgeingPack>();
  final side = AgeingSide.receivables.obs;
  final bucket = AgeingBucket.d1to30.obs;
  final isLoading = false.obs;
  final busyKey = RxnString();
  int _loadId = 0;

  AppLanguage get _language => Get.find<AppController>().language.value;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  List<AgeingRow> get visibleRows {
    final current = pack.value;
    if (current == null) return const [];
    return current.inBucket(side.value, bucket.value);
  }

  void selectSide(AgeingSide value) {
    side.value = value;
    _preferPopulatedBucket();
  }

  void selectBucket(AgeingBucket value) => bucket.value = value;

  Future<void> reload() async {
    final id = ++_loadId;
    isLoading.value = true;
    try {
      final next = await _service.build();
      if (id != _loadId) return;
      pack.value = next;
      _preferPopulatedBucket();
    } catch (_) {
      if (id != _loadId) return;
      AppNotification.error(
        'Ageing failed',
        'Outstanding documents could not be grouped. Please try again.',
      );
    } finally {
      if (id == _loadId) isLoading.value = false;
    }
  }

  Future<void> openRow(AgeingRow row) async {
    final route = row.side == AgeingSide.receivables
        ? AppRoutes.invoiceDetails
        : AppRoutes.purchaseBillDetails;
    await Get.toNamed<void>(route, arguments: row.documentId);
    await reload();
  }

  Future<void> shareRow(AgeingRow row) async {
    final current = pack.value;
    if (current == null || busyKey.value != null) return;
    busyKey.value = row.storageKey;
    try {
      await _service.shareDocument(row, current, language: _language);
      await reload();
    } catch (_) {
      AppNotification.error(
        'Reminder failed',
        'The message could not be shared. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }

  Future<void> shareVisible() async {
    final current = pack.value;
    final rows = visibleRows;
    if (current == null || rows.isEmpty || busyKey.value != null) return;
    busyKey.value = 'bucket';
    try {
      await _service.shareBucket(rows, current, language: _language);
      await reload();
    } catch (_) {
      AppNotification.error(
        'Reminder failed',
        'The message could not be shared. Please try again.',
      );
    } finally {
      busyKey.value = null;
    }
  }

  void _preferPopulatedBucket() {
    final current = pack.value;
    if (current == null) return;
    if (current.inBucket(side.value, bucket.value).isNotEmpty) return;
    for (final next in AgeingBucket.values) {
      if (current.inBucket(side.value, next).isNotEmpty) {
        bucket.value = next;
        return;
      }
    }
  }
}
