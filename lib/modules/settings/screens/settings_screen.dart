import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/localization/app_localization.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_menu_group.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/settings_controller.dart';
import '../../../data/services/app_lock_service.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Settings'),
    ),
    body: ResponsiveContent(
      child: ListView(
        children: [
          _heading('Business'),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.storefront_outlined,
                title: 'Business profile',
                subtitle: 'Identity, GST, bank details and branding',
                onTap: () => Get.toNamed<void>(AppRoutes.businessSetup),
              ),
              AppMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Invoice defaults',
                subtitle: 'Due date, GST, payment, notes and terms',
                onTap: () => Get.toNamed<void>(AppRoutes.invoiceDefaults),
              ),
              AppMenuTile(
                icon: Icons.tune_rounded,
                title: 'Product settings',
                subtitle: 'Business category, product fields and PDF display',
                onTap: () => Get.toNamed<void>(AppRoutes.productSettings),
              ),
              AppMenuTile(
                icon: Icons.straighten_rounded,
                title: 'Units',
                subtitle: 'Manage choices and the default item unit',
                onTap: () => Get.toNamed<void>(AppRoutes.unitSettings),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _heading('Appearance'),
          AppMenuGroup(
            children: [
              Obx(
                () => AppMenuTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  subtitle: 'Use a darker appearance throughout the app',
                  onTap: () => controller.appController.setDarkMode(
                    !controller.appController.isDarkMode,
                  ),
                  trailing: Switch.adaptive(
                    value: controller.appController.isDarkMode,
                    onChanged: controller.appController.setDarkMode,
                  ),
                ),
              ),
              Obx(
                () => AppMenuTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: controller.appController.language.value.nativeName,
                  onTap: () => _showLanguageDialog(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _heading('Security'),
          AppMenuGroup(
            children: [
              Obx(() {
                final enabled = Get.find<AppLockService>().isEnabled;
                return AppMenuTile(
                  icon: enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  title: 'App lock',
                  subtitle: enabled
                      ? 'Four-digit PIN required'
                      : 'Protect the app with a four-digit PIN',
                  onTap: () => Get.toNamed<void>(AppRoutes.appLock),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColors.success.withValues(alpha: .12)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      enabled ? 'On' : 'Off',
                      style: AppTextStyles.small.copyWith(
                        color: enabled
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 18),
          _heading('Data'),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.file_download_outlined,
                title: 'Export data',
                subtitle: 'CSV business data and date-range reports',
                onTap: () => Get.toNamed<void>(AppRoutes.dataExport),
              ),
              AppMenuTile(
                icon: Icons.settings_backup_restore,
                title: 'Backup & restore',
                subtitle: 'Protect your offline records',
                onTap: () => Get.toNamed<void>(AppRoutes.backup),
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _heading('About'),
          AppMenuGroup(
            children: [
              Obx(
                () => AppMenuTile(
                  icon: Icons.info_outline,
                  title: 'Creovo Billing',
                  subtitle: controller.appVersion.value.isEmpty
                      ? 'Privacy-first offline invoicing'
                      : 'Version ${controller.appVersion.value}',
                  trailing: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(value.toUpperCase(), style: AppTextStyles.small),
  );

  Future<void> _showLanguageDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose language', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'You can change the app language anytime.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final language in AppLanguage.values)
                Obx(
                  () => ListTile(
                    leading: Icon(
                      controller.appController.language.value == language
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: controller.appController.language.value == language
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    title: Text(language.nativeName),
                    subtitle: language.nativeName == language.englishName
                        ? null
                        : Text(language.englishName),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: () async {
                      await controller.appController.setLanguage(language);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
