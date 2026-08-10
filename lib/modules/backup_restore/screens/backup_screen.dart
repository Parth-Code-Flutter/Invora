import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/backup_controller.dart';

class BackupScreen extends GetView<BackupController> {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & restore')),
    body: ResponsiveContent(
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 42,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your data lives on this device',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create backups regularly to protect your invoices if this device is lost, reset, or the app is uninstalled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create backup', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                const Text(
                  'Includes the database, business media, and backup metadata.',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => FilledButton.icon(
                    onPressed: controller.isWorking.value
                        ? null
                        : controller.createAndShare,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Create and share ZIP'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Restore backup', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                const Text(
                  'The ZIP is fully validated before existing local data is replaced.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.isWorking.value
                      ? null
                      : () => _restore(context),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Select backup ZIP'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _restore(BuildContext context) async {
    final result = await controller.selectAndValidate();
    if (result == null) return;
    if (!result.endsWith('.zip')) {
      Get.snackbar('Invalid backup', result);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace local data?'),
        content: const Text(
          'Current records will be replaced. Creovo Invoice must be restarted after restore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.restore(result);
  }
}
