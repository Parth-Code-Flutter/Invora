import 'dart:io';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_purchase_navigation.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/app_menu_group.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/services/business_workspace_service.dart';
import '../controllers/more_controller.dart';

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final purchases = Get.find<BusinessWorkspaceService>().isPurchases;
      return AppShell(
        salesDestination: purchases ? null : MainDestination.more,
        purchaseDestination: purchases ? PurchaseDestination.more : null,
        appBar: AppBar(title: const AppBarTitle('More')),
        body: ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            children: [
              Obx(
                () => _BusinessHeader(
                  controller: controller,
                  profile: controller.profile.value,
                ),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Change workspace'),
              Obx(() {
                final workspace = Get.find<BusinessWorkspaceService>();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppMenuGroup(
                      children: [
                        AppMenuTile(
                          icon: Icons.trending_up_rounded,
                          title: 'Sales',
                          subtitle: 'Invoices, customers and money to receive',
                          selected: workspace.isSales,
                          onTap: () =>
                              workspace.select(BusinessWorkspace.sales),
                        ),
                        AppMenuTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Purchases',
                          subtitle: 'Supplier bills and money to pay',
                          selected: workspace.isPurchases,
                          onTap: () =>
                              workspace.select(BusinessWorkspace.purchases),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Tap Sales or Purchases to change mode. Records stay separate.',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 22),
              const _SectionLabel('Customization'),
              AppMenuGroup(
                children: [
                  AppMenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Product settings',
                    subtitle: 'Business category, fields and invoice display',
                    onTap: () => Get.toNamed<void>(AppRoutes.productSettings),
                  ),
                  AppMenuTile(
                    icon: Icons.straighten_rounded,
                    title: 'Set default unit',
                    subtitle:
                        'Manage units and choose the default for new items',
                    onTap: () => Get.toNamed<void>(AppRoutes.unitSettings),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Create & manage'),
              AppMenuGroup(
                children: [
                  AppMenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Products & services',
                    subtitle: 'Saved items, pricing and tax',
                    onTap: () => Get.toNamed<void>(AppRoutes.products),
                  ),
                  AppMenuTile(
                    icon: Icons.request_quote_outlined,
                    title: 'Estimates',
                    subtitle: 'Create and manage client quotations',
                    onTap: () => Get.toNamed<void>(AppRoutes.quotations),
                  ),
                  AppMenuTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery challans',
                    subtitle:
                        'Dispatch goods, then convert remaining quantities',
                    onTap: () => Get.toNamed<void>(AppRoutes.deliveryChallans),
                  ),
                  AppMenuTile(
                    icon: Icons.payments_outlined,
                    title: 'Expenses',
                    subtitle: 'Rent, fuel, salary and other cash spends',
                    onTap: () => Get.toNamed<void>(AppRoutes.expenses),
                  ),
                  AppMenuTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Cash book',
                    subtitle: 'Cash, bank, UPI, transfers and daily closing',
                    onTap: () => Get.toNamed<void>(AppRoutes.cashBook),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Insights & data'),
              AppMenuGroup(
                children: [
                  AppMenuTile(
                    icon: Icons.insert_chart_outlined_rounded,
                    title: 'Reports',
                    subtitle: 'Review sales, receipts and outstanding totals',
                    onTap: () => Get.toNamed<void>(AppRoutes.reports),
                  ),
                  AppMenuTile(
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Ageing & reminders',
                    subtitle:
                        'Buckets to collect or pay, then share a reminder',
                    onTap: () => Get.toNamed<void>(AppRoutes.ageing),
                  ),
                  AppMenuTile(
                    icon: Icons.file_upload_outlined,
                    title: 'Import data',
                    subtitle:
                        'CSV templates for parties, items and unpaid bills',
                    onTap: () => Get.toNamed<void>(AppRoutes.dataImport),
                  ),
                  AppMenuTile(
                    icon: Icons.account_balance_outlined,
                    title: 'GST / CA export',
                    subtitle: 'Prepared registers for your accountant',
                    onTap: () => Get.toNamed<void>(AppRoutes.gstExport),
                  ),
                  AppMenuTile(
                    icon: Icons.settings_backup_restore_rounded,
                    title: 'Backup & restore',
                    subtitle: 'Export or restore your offline records',
                    onTap: () => Get.toNamed<void>(AppRoutes.backup),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Preferences'),
              AppMenuGroup(
                children: [
                  AppMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'App settings',
                    subtitle: 'Invoice defaults, look, language and lock',
                    onTap: () => Get.toNamed<void>(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _PrivacyNote(),
            ],
          ),
        ),
      );
    });
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.controller, required this.profile});
  final MoreController controller;
  final BusinessProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = profile?.businessName ?? 'Your business';
    final detail = _detailLine(profile);
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.editBusiness,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
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
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: controller.editBusiness,
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _detailLine(BusinessProfileModel? profile) {
    if (profile == null) return 'Complete your business profile';
    final parts = <String>[
      if (profile.ownerName?.trim().isNotEmpty == true)
        profile.ownerName!.trim(),
      if (profile.mobile?.trim().isNotEmpty == true) profile.mobile!.trim(),
      if (profile.gstin?.trim().isNotEmpty == true) profile.gstin!.trim(),
    ];
    if (parts.isEmpty) return 'Complete your business profile';
    return parts.join(' · ');
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
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: validPath
          ? Image.file(File(path!), fit: BoxFit.cover, width: 48, height: 48)
          : Text(
              name.trim().isEmpty
                  ? 'I'
                  : name.trim().characters.first.toUpperCase(),
              style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        value.toUpperCase(),
        style: AppTextStyles.small.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkTextSecondary : AppColors.textTertiary;
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Private by design. Your data stays on this device.',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
