import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/responsive_content.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    bottomNavigationBar: const AppMainNavigation(current: MainDestination.more),
    body: ResponsiveContent(
      tabletMaxWidth: 720,
      child: ListView(
        children: [
          _heading('Business'),
          AppCard(
            child: Column(
              children: [
                _tile(
                  Icons.inventory_2_outlined,
                  'Products & services',
                  AppRoutes.products,
                ),
                const Divider(height: 1),
                _tile(
                  Icons.request_quote_outlined,
                  'Estimates',
                  AppRoutes.quotations,
                ),
                const Divider(height: 1),
                _tile(Icons.analytics_outlined, 'Reports', AppRoutes.reports),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _heading('Settings'),
          AppCard(
            child: Column(
              children: [
                _tile(
                  Icons.storefront_outlined,
                  'Business profile',
                  AppRoutes.businessSetup,
                ),
                const Divider(height: 1),
                _tile(Icons.tune_rounded, 'App settings', AppRoutes.settings),
                const Divider(height: 1),
                _tile(
                  Icons.settings_backup_restore,
                  'Backup & restore',
                  AppRoutes.backup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _heading('Invora'),
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
              ),
              title: Text('Private by design'),
              subtitle: Text(
                'Your business and invoice data stays on this device.',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(value.toUpperCase(), style: AppTextStyles.caption),
  );

  Widget _tile(IconData icon, String title, String route) => ListTile(
    minTileHeight: 64,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Get.toNamed<void>(route),
  );
}
