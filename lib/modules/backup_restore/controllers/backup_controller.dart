import 'dart:io';

import 'package:get/get.dart';

import '../../../app/widgets/app_notification.dart';
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

  Future<void> createAndShare() async {
    isWorking.value = true;
    try {
      final file = await _service.createBackup();
      lastBackup.value = file;
      lastBackupAt.value = _service.lastBackupAt;
      await _service.shareBackup(file);
      AppNotification.success(
        'Backup created',
        'Keep this ZIP file in a safe location.',
      );
    } finally {
      isWorking.value = false;
    }
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

  Future<String?> selectAndValidate() async {
    final file = await _service.pickBackup();
    if (file == null) return null;
    final validation = await _service.validate(file);
    if (!validation.isValid) return validation.message;
    return file.path;
  }

  Future<bool> restore(String path) async {
    isWorking.value = true;
    try {
      await _service.restore(File(path));
      return true;
    } finally {
      isWorking.value = false;
    }
  }
}
