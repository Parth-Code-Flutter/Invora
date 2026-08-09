import 'dart:io';

import 'package:get/get.dart';

import '../../../data/services/backup_service.dart';

class BackupController extends GetxController {
  BackupController(this._service);
  final BackupService _service;
  final isWorking = false.obs;
  final lastBackup = Rxn<File>();

  Future<void> createAndShare() async {
    isWorking.value = true;
    try {
      final file = await _service.createBackup();
      lastBackup.value = file;
      await _service.shareBackup(file);
      Get.snackbar('Backup created', 'Keep this ZIP file in a safe location.');
    } finally {
      isWorking.value = false;
    }
  }

  Future<String?> selectAndValidate() async {
    final file = await _service.pickBackup();
    if (file == null) return null;
    final validation = await _service.validate(file);
    if (!validation.isValid) return validation.message;
    return file.path;
  }

  Future<void> restore(String path) async {
    isWorking.value = true;
    try {
      await _service.restore(File(path));
      Get.snackbar(
        'Restore complete',
        'Close and reopen Invora to load the restored records.',
        duration: const Duration(seconds: 8),
      );
    } finally {
      isWorking.value = false;
    }
  }
}
