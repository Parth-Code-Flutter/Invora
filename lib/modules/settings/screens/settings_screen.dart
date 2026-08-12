import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_menu_group.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Settings'),
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
                  title: 'Creovo Invoice',
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
}
