import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/backup_controller.dart';

class BackupScreen extends GetView<BackupController> {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Backup & restore'),
    ),
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
          Obx(
            () => _BackupStatusCard(
              lastBackupAt: controller.lastBackupAt.value,
              isDue: controller.isBackupDue,
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
                  'Includes customers, invoices, bank details, signature, payment QR, business media, and app settings.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The ZIP is not encrypted. Store it only in a private, trusted location.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AppButton(
                    onPressed: controller.isWorking.value
                        ? null
                        : () => _confirmCreate(context),
                    icon: Icons.archive_outlined,
                    label: 'Create and share ZIP',
                    isLoading: controller.isWorking.value,
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
                Text('Backup reminder', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                const Text(
                  'Creovo will show when a new local backup is due. No notification or data leaves this device.',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AppDropdownField<int>(
                    label: 'Remind me',
                    value: controller.reminderDays.value,
                    options: const [
                      AppDropdownOption(value: 7, label: 'Every 7 days'),
                      AppDropdownOption(value: 14, label: 'Every 14 days'),
                      AppDropdownOption(value: 30, label: 'Every 30 days'),
                      AppDropdownOption(value: 0, label: 'Off'),
                    ],
                    onChanged: controller.setReminderDays,
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
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isWorking.value
                        ? null
                        : () => _restore(context),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Select backup ZIP'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmCreate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Create sensitive-data backup?'),
        content: const Text(
          'This unencrypted ZIP contains customer, invoice, bank, signature, and payment QR information. Share it only to a private location you trust.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Create backup'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.createAndShare();
  }

  Future<void> _restore(BuildContext context) async {
    final result = await controller.selectAndValidate();
    if (result == null) return;
    if (!result.endsWith('.zip')) {
      AppNotification.error('Invalid backup', result);
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
    if (confirmed != true) return;
    final restored = await controller.restore(result);
    if (!restored || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        title: const Text('Restore complete'),
        content: const Text(
          'Your backup was restored safely. Close and reopen Creovo Invoice now to load the restored records.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('I’ll restart now'),
          ),
        ],
      ),
    );
  }
}

class _BackupStatusCard extends StatelessWidget {
  const _BackupStatusCard({required this.lastBackupAt, required this.isDue});

  final DateTime? lastBackupAt;
  final bool isDue;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (isDue ? AppColors.warning : AppColors.success).withValues(
              alpha: .11,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isDue ? Icons.notification_important_outlined : Icons.cloud_done,
            color: isDue ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDue ? 'Backup recommended' : 'Backup up to date',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 3),
              Text(
                lastBackupAt == null
                    ? 'No successful backup recorded on this device.'
                    : 'Last successful backup: ${_formatDateTime(lastBackupAt!)}',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _formatDateTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$date at $hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }
}
