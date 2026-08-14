import 'dart:io';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_menu_group.dart';
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
          const SizedBox(height: 20),
          const _SectionLabel('Customization'),
          const SizedBox(height: 9),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.tune_rounded,
                title: 'Product settings',
                subtitle: 'Business category, fields and invoice display',
                color: AppColors.primary,
                background: AppColors.primaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.productSettings),
              ),
              AppMenuTile(
                icon: Icons.straighten_rounded,
                title: 'Set default unit',
                subtitle: 'Manage units and choose the default for new items',
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.unitSettings),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Create & manage'),
          const SizedBox(height: 9),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.inventory_2_outlined,
                title: 'Products & services',
                subtitle: 'Saved items, pricing, tax and units',
                color: AppColors.primary,
                background: AppColors.primaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.products),
              ),
              AppMenuTile(
                icon: Icons.request_quote_outlined,
                title: 'Estimates',
                subtitle: 'Create and manage client quotations',
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.quotations),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Insights & data'),
          const SizedBox(height: 9),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.insert_chart_outlined_rounded,
                title: 'Reports',
                subtitle: 'Review sales, receipts and outstanding totals',
                color: AppColors.primary,
                background: AppColors.primaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.reports),
              ),
              AppMenuTile(
                icon: Icons.settings_backup_restore_rounded,
                title: 'Backup & restore',
                subtitle: 'Export or restore your offline records',
                color: AppColors.secondary,
                background: AppColors.secondaryLight,
                onTap: () => Get.toNamed<void>(AppRoutes.backup),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 9),
          AppMenuGroup(
            children: [
              AppMenuTile(
                icon: Icons.storefront_outlined,
                title: 'Business profile',
                subtitle: 'Identity, tax and payment details',
                onTap: controller.editBusiness,
              ),
              AppMenuTile(
                icon: Icons.tune_rounded,
                title: 'App settings',
                subtitle: 'Appearance and preferences',
                onTap: () => Get.toNamed<void>(AppRoutes.settings),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2517172B),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _BusinessLogo(path: profile?.logoPath, name: name),
          const SizedBox(width: 12),
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
            tooltip: l10n('Edit business profile'),
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
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: validPath
          ? Image.file(File(path!), fit: BoxFit.cover, width: 50, height: 50)
          : Text(
              name.trim().isEmpty
                  ? 'I'
                  : name.trim().characters.first.toUpperCase(),
              style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: AppTextStyles.caption.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      letterSpacing: .1,
    ),
  );
}
