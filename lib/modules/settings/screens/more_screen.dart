import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_profile_model.dart';
import '../controllers/more_controller.dart';

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    bottomNavigationBar: const AppMainNavigation(current: MainDestination.more),
    body: ResponsiveContent(
      tabletMaxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Obx(
            () => _BusinessHeader(
              controller: controller,
              profile: controller.profile.value,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Business tools'),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: MediaQuery.sizeOf(context).width >= 600
                ? 1.8
                : 1.28,
            children: const [
              _ToolTile(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                caption: 'Items & pricing',
                route: AppRoutes.products,
                color: AppColors.primary,
                background: AppColors.primaryLight,
              ),
              _ToolTile(
                icon: Icons.request_quote_outlined,
                label: 'Estimates',
                caption: 'Quotes for clients',
                route: AppRoutes.quotations,
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
              ),
              _ToolTile(
                icon: Icons.insert_chart_outlined_rounded,
                label: 'Reports',
                caption: 'Sales overview',
                route: AppRoutes.reports,
                color: AppColors.primary,
                background: AppColors.primaryLight,
              ),
              _ToolTile(
                icon: Icons.settings_backup_restore_rounded,
                label: 'Backup',
                caption: 'Protect your data',
                route: AppRoutes.backup,
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 9),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.storefront_outlined,
                  title: 'Business profile',
                  subtitle: 'Identity, tax and payment details',
                  onTap: controller.editBusiness,
                ),
                const Divider(height: 1, indent: 52),
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'App settings',
                  subtitle: 'Appearance and preferences',
                  onTap: () => Get.toNamed<void>(AppRoutes.settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Private by design • Your data stays on this device',
                    style: AppTextStyles.secondaryBody.copyWith(
                      color: AppColors.primaryDark,
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
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.controller, required this.profile});
  final MoreController controller;
  final BusinessProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.businessName ?? 'Your business';
    final detail =
        profile?.ownerName ??
        profile?.mobile ??
        'Complete your business profile';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0623),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2517172B),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _BusinessLogo(path: profile?.logoPath, name: name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.secondaryBody.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Edit business profile',
            onPressed: controller.editBusiness,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .1),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
        ],
      ),
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  const _BusinessLogo({required this.path, required this.name});
  final String? path;
  final String name;

  @override
  Widget build(BuildContext context) {
    final validPath = path != null && File(path!).existsSync();
    return Container(
      width: 54,
      height: 54,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: validPath
          ? Image.file(File(path!), fit: BoxFit.cover, width: 54, height: 54)
          : Text(
              name.trim().isEmpty
                  ? 'I'
                  : name.trim().characters.first.toUpperCase(),
              style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
            ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.route,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String label;
  final String caption;
  final String route;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => Get.toNamed<void>(route),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(label, style: AppTextStyles.cardTitle),
        const SizedBox(height: 2),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: 64,
    leading: Icon(icon, color: AppColors.primary, size: 22),
    title: Text(title, style: AppTextStyles.cardTitle),
    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    onTap: onTap,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: .3,
    ),
  );
}
