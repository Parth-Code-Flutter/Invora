import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
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
          AppCard(
            child: ListTile(
              leading: const _SettingsIcon(Icons.storefront_outlined),
              title: const Text('Business profile'),
              subtitle: const Text('Identity, GST, bank details and branding'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed<void>(AppRoutes.businessSetup),
            ),
          ),
          const SizedBox(height: 18),
          _heading('Appearance'),
          AppCard(
            child: Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const _SettingsIcon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                value: controller.appController.isDarkMode,
                onChanged: controller.appController.setDarkMode,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _heading('Data'),
          AppCard(
            child: ListTile(
              leading: const _SettingsIcon(Icons.settings_backup_restore),
              title: const Text('Backup & restore'),
              subtitle: const Text('Protect your offline records'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed<void>(AppRoutes.backup),
            ),
          ),
          const SizedBox(height: 18),
          _heading('About'),
          AppCard(
            child: Obx(
              () => ListTile(
                leading: const _SettingsIcon(Icons.info_outline),
                title: const Text('Creovo Invoice'),
                subtitle: Text(
                  controller.appVersion.value.isEmpty
                      ? 'Privacy-first offline invoicing'
                      : 'Version ${controller.appVersion.value}',
                ),
              ),
            ),
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

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.primary, size: 21),
  );
}
