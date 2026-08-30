import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/services/backup_service.dart';
import '../controllers/backup_controller.dart';

class BackupScreen extends GetView<BackupController> {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Backup & restore'),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 640,
      largeTabletMaxWidth: 720,
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
                  'Includes customers, invoices, bank details, signature, payment QR, business media, and app settings. The file is encrypted with a password you choose.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Password protected. Creovo never sends this file to a server. If you forget the password, the backup cannot be opened.',
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
                    label: 'Create and share backup',
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
                  'The file is decrypted and validated in a temporary folder before existing local data is replaced. Older unencrypted backups still restore.',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isWorking.value
                        ? null
                        : () => _openBackup(context, restore: false),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Verify backup'),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isWorking.value
                        ? null
                        : () => _openBackup(context, restore: true),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Select backup file'),
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
                Text('Erase all data', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                const Text(
                  'This cannot be undone. It deletes customers, invoices, bills, products, payments, stock, photos, business profile, PIN, and lock settings on this phone. Creovo then opens like a new install. ZIP files you already saved in Files, Drive, or WhatsApp are not deleted. Create a backup above first if you might need these records.',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isWorking.value
                        ? null
                        : () => _confirmErase(context),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Erase all data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
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
    final password = await _askBackupPassword(
      context,
      title: 'Create encrypted backup',
      confirmLabel: 'Create backup',
      confirmPassword: true,
    );
    if (password == null) return;
    await controller.createAndShare(password);
  }

  Future<void> _openBackup(
    BuildContext context, {
    required bool restore,
  }) async {
    final file = await controller.pickBackup();
    if (file == null) return;
    if (!context.mounted) return;
    var password = '';
    if (await controller.isEncrypted(file)) {
      if (!context.mounted) return;
      final entered = await _askBackupPassword(
        context,
        title: restore ? 'Unlock backup' : 'Verify backup',
        confirmLabel: restore ? 'Continue' : 'Verify',
      );
      if (entered == null) return;
      password = entered;
    }
    controller.isWorking.value = true;
    late final BackupValidation validation;
    try {
      validation = await controller.validateBackup(
        file,
        password: password.isEmpty ? null : password,
      );
    } finally {
      controller.isWorking.value = false;
    }
    if (!validation.isValid) {
      AppNotification.error('Invalid backup', validation.message);
      return;
    }
    if (!context.mounted) return;
    final previewText = _previewMessage(validation.preview);
    await showAppNoticeDialog(
      context: context,
      title: restore ? 'Backup preview' : 'Backup is valid',
      message: previewText,
      icon: Icons.verified_user_outlined,
    );
    if (!restore) return;
    if (!context.mounted) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      tone: AppDialogTone.warning,
      icon: Icons.restore_rounded,
      confirmIcon: Icons.restore_rounded,
      title: 'Replace local data?',
      message:
          'Current records will be replaced. Creovo Billing must be restarted after restore.',
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    Get.offAllNamed<void>(
      AppRoutes.restoreStatus,
      arguments: RestoreBackupRequest(
        path: file.path,
        password: password.isEmpty ? null : password,
      ),
    );
  }

  Future<void> _confirmErase(BuildContext context) async {
    final warned = await showAppConfirmDialog(
      context: context,
      destructive: true,
      tone: AppDialogTone.warning,
      icon: Icons.delete_forever_outlined,
      confirmIcon: Icons.arrow_forward_rounded,
      title: 'Erase all data?',
      message:
          'This cannot be undone. Every record on this phone will be deleted, then Creovo will open like a new install. ZIP backups you already saved outside the app stay. Create a backup above first if you might need these records.',
      confirmLabel: 'Continue',
    );
    if (!warned || !context.mounted) return;
    final typed = await showAppBottomSheet<bool>(
      context: context,
      title: 'Type ERASE to confirm',
      child: const _EraseConfirmationForm(),
    );
    if (typed != true || !context.mounted) return;
    await controller.eraseAllData();
  }

  String _previewMessage(BackupPreview? preview) {
    if (preview == null) {
      return 'This backup passed validation.';
    }
    final created = preview.createdAt;
    final createdLabel = created == null
        ? 'Unknown date'
        : '${created.toLocal().day.toString().padLeft(2, '0')}/${created.toLocal().month.toString().padLeft(2, '0')}/${created.toLocal().year}';
    final kind = preview.legacy
        ? 'Legacy unencrypted backup'
        : 'Password-protected backup';
    final name = (preview.businessName ?? '').trim();
    final invoices = preview.invoiceCount;
    final bills = preview.billCount;
    final attachments = preview.attachmentCount;
    return [
      kind,
      if (name.isNotEmpty) 'Business: $name',
      'Created: $createdLabel',
      if (invoices != null) 'Invoices: $invoices',
      if (bills != null) 'Purchase bills: $bills',
      if (attachments != null) 'Attachments: $attachments',
    ].join('\n');
  }

  Future<String?> _askBackupPassword(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    bool confirmPassword = false,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      title: title,
      child: _BackupPasswordForm(
        confirmLabel: confirmLabel,
        confirmPassword: confirmPassword,
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

class _EraseConfirmationForm extends StatefulWidget {
  const _EraseConfirmationForm();

  @override
  State<_EraseConfirmationForm> createState() => _EraseConfirmationFormState();
}

class _EraseConfirmationFormState extends State<_EraseConfirmationForm> {
  final _formKey = GlobalKey<FormState>();
  final _phrase = TextEditingController();

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  bool get _matches =>
      _phrase.text.trim() == BackupService.eraseConfirmationPhrase;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Type ERASE in capital letters to confirm.'),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phrase,
              label: 'Type ERASE',
              prefixIcon: Icons.warning_amber_rounded,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value?.trim() != BackupService.eraseConfirmationPhrase) {
                  return 'Type ERASE in capital letters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Erase all data',
              icon: Icons.delete_forever_outlined,
              onPressed: _matches ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(true);
  }
}

class _BackupPasswordForm extends StatefulWidget {
  const _BackupPasswordForm({
    required this.confirmLabel,
    required this.confirmPassword,
  });

  final String confirmLabel;
  final bool confirmPassword;

  @override
  State<_BackupPasswordForm> createState() => _BackupPasswordFormState();
}

class _BackupPasswordFormState extends State<_BackupPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _hidePassword = true;
  var _hideConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _password,
              label: 'Backup password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _hidePassword,
              textInputAction: widget.confirmPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              validator: (value) {
                if (value == null ||
                    value.length < BackupService.minPasswordLength) {
                  return 'Use at least 8 characters.';
                }
                return null;
              },
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            if (widget.confirmPassword) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirm,
                label: 'Confirm password',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: _hideConfirm,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != _password.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                  icon: Icon(
                    _hideConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: widget.confirmLabel,
              icon: Icons.lock_rounded,
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(_password.text);
              },
            ),
          ],
        ),
      ),
    );
  }
}
