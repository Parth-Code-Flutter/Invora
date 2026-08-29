import 'dart:io';

import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/widgets/app_notification.dart';
import '../../../data/services/app_lock_service.dart';
import '../../../data/services/diagnostics_service.dart';

class AboutController extends GetxController {
  AboutController(this._diagnostics, this._lock, {DiagnosticsReport? seed}) {
    if (seed != null) {
      report.value = seed;
      isLoading.value = false;
    }
  }

  final DiagnosticsService _diagnostics;
  final AppLockService _lock;

  final report = Rxn<DiagnosticsReport>();
  final isLoading = true.obs;
  final isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (report.value == null) reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    try {
      final info = await PackageInfo.fromPlatform();
      report.value = await _diagnostics.collect(
        appVersion: info.version,
        buildNumber: info.buildNumber,
        platform: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
        appLockEnabled: _lock.isEnabled,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> share() async {
    final current = report.value;
    if (current == null || isBusy.value) return;
    isBusy.value = true;
    try {
      await _diagnostics.share(current);
      AppNotification.success(
        'Diagnostics shared',
        'The file has counts and versions only — not a backup.',
      );
    } catch (_) {
      AppNotification.warning(
        'Cannot share diagnostics',
        'The diagnostics file could not be shared. Please try again.',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> save() async {
    final current = report.value;
    if (current == null || isBusy.value) return;
    isBusy.value = true;
    try {
      final path = await _diagnostics.save(current);
      if (path != null) {
        AppNotification.success(
          'Diagnostics saved',
          'The file has counts and versions only — not a backup.',
        );
      }
    } catch (_) {
      AppNotification.warning(
        'Cannot save diagnostics',
        'The diagnostics file could not be saved. Please try again.',
      );
    } finally {
      isBusy.value = false;
    }
  }
}
