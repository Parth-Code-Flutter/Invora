import 'dart:io';

import 'package:get/get.dart';

import '../../../app/bindings/initial_binding.dart';
import '../../../app/controllers/app_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/services/app_lock_service.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/backup_service.dart';

class BackupController extends GetxController {
  BackupController(this._service);
  final BackupService _service;
  final isWorking = false.obs;
  final lastBackup = Rxn<File>();
  final lastBackupAt = Rxn<DateTime>();
  final reminderDays = 7.obs;

  @override
  void onInit() {
    super.onInit();
    lastBackupAt.value = _service.lastBackupAt;
    reminderDays.value = _service.reminderDays;
  }

  bool get isBackupDue {
    final days = reminderDays.value;
    if (days <= 0) return false;
    final created = lastBackupAt.value;
    if (created == null) return true;
    return DateTime.now().difference(created).inDays >= days;
  }

  Future<void> createAndShare(String password) async {
    isWorking.value = true;
    try {
      final file = await _service.createBackup(password: password);
      lastBackup.value = file;
      lastBackupAt.value = _service.lastBackupAt;
      await _service.shareBackup(file);
      AppNotification.success(
        'Backup created',
        'Keep this file and the password in a safe place.',
      );
    } finally {
      isWorking.value = false;
    }
  }

  Future<File?> pickBackup() => _service.pickBackup();

  Future<bool> isEncrypted(File file) => _service.isEncryptedBackup(file);

  Future<BackupValidation> validateBackup(File file, {String? password}) {
    return _service.validate(file, password: password);
  }

  Future<void> setReminderDays(int days) async {
    reminderDays.value = days;
    try {
      await _service.setReminderDays(days);
    } catch (_) {
      reminderDays.value = _service.reminderDays;
      rethrow;
    }
  }

  Future<void> eraseAllData() async {
    isWorking.value = true;
    try {
      await _service.eraseAllLocalData();
      final storage = Get.find<AppStorage>();
      await InitialBinding.reloadDatabaseRuntime(storage);
      if (Get.isRegistered<AppLockService>()) {
        Get.find<AppLockService>().load();
      }
      if (Get.isRegistered<AppController>()) {
        await Get.find<AppController>().reloadFromStorage();
      }
      Get.offAllNamed<void>(AppRoutes.splash);
    } catch (error) {
      AppNotification.error(
        'Could not erase data',
        error.toString().replaceFirst('Bad state: ', ''),
      );
    } finally {
      isWorking.value = false;
    }
  }
}
