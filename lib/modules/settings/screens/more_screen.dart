import 'dart:io';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_menu_group.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../../../data/services/entitlement_policy.dart';
import '../controllers/more_controller.dart';
import '../more_destinations.dart';

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destination: MainDestination.more,
      appBar: AppSearchAppBar(
        title: 'More',
        hint: 'Search features',
        onChanged: controller.updateSearch,
      ),
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
            Obx(
              () => controller.isSearching
                  ? const SizedBox.shrink()
                  : const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: _PlanBanner(),
                    ),
            ),
            const SizedBox(height: 14),
            Obx(() {
              final groups = controller.visibleGroups;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (groups.isEmpty) ...[
                    const SizedBox(height: 28),
                    AppEmptyState(
                      illustration: AppEmptyIllustration.search,
                      title: 'No matching features',
                      message:
                          'Try a different name, like GST, stock, or backup.',
                    ),
                  ] else ...[
                    for (var index = 0; index < groups.length; index++) ...[
                      SizedBox(height: index == 0 ? 18 : 22),
                      _section(groups[index]),
                    ],
                  ],
                ],
              );
            }),
            Obx(
              () => controller.isSearching
                  ? const SizedBox(height: 20)
                  : const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: _PrivacyNote(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(MoreDestinationGroup group) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(group.label),
        AppMenuGroup(
          children: [
            for (final item in group.items)
              AppMenuTile(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                color: item.color,
                background: item.background,
                onTap: () => _open(item),
              ),
          ],
        ),
      ],
    );
  }

  void _open(MoreDestination item) {
    final route = item.route;
    if (route == null) return;
    if (route == AppRoutes.products) {
      Get.offAllNamed<void>(route);
      return;
    }
    Get.toNamed<void>(route);
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.controller, required this.profile});
  final MoreController controller;
  final BusinessProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = profile?.businessName.trim().isNotEmpty == true
        ? profile!.businessName.trim()
        : 'Your business';
    final contact = _contactLine(profile);
    final gstin = profile?.gstin?.trim();
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final tertiary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textTertiary;
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business profile',
                      style: AppTextStyles.caption.copyWith(
                        color: tertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle,
                    ),
                    if (contact != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        contact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: secondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    if (gstin != null && gstin.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _GstinChip(value: gstin, isDark: isDark),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String? _contactLine(BusinessProfileModel? profile) {
    if (profile == null) return 'Complete your business profile';
    final parts = <String>[
      if (profile.ownerName?.trim().isNotEmpty == true)
        profile.ownerName!.trim(),
      if (profile.mobile?.trim().isNotEmpty == true) profile.mobile!.trim(),
    ];
    if (parts.isEmpty) return 'Complete your business profile';
    return parts.join(' · ');
  }
}

class _GstinChip extends StatelessWidget {
  const _GstinChip({required this.value, required this.isDark});

  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validPath = path != null && File(path!).existsSync();
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: validPath
            ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
            : AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: validPath
          ? Image.file(File(path!), fit: BoxFit.cover, width: 56, height: 56)
          : Text(
              name.trim().isEmpty
                  ? 'I'
                  : name.trim().characters.first.toUpperCase(),
              style: AppTextStyles.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
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

class _PlanBanner extends StatefulWidget {
  const _PlanBanner();

  @override
  State<_PlanBanner> createState() => _PlanBannerState();
}

class _PlanBannerState extends State<_PlanBanner> {
  EntitlementSnapshot? get _snapshot {
    if (!Get.isRegistered<AccountEntitlementService>()) return null;
    return Get.find<AccountEntitlementService>().lastSnapshot;
  }

  String get _title {
    return _snapshot?.displayTitle ?? 'Creovo Yearly';
  }

  String get _subtitle {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return 'Trial, Creovo Yearly, and account mobile';
    }
    if (snapshot.isPaid || snapshot.isCancelled) {
      return snapshot.moreSubtitle();
    }
    final days = snapshot.remainingDays();
    if (days <= 0) return 'Trial ended';
    if (days == 1) return 'Trial · 1 day left';
    return '${l10n('Trial')} · ${l10n('$days days left')}';
  }

  String get _badge {
    return _snapshot?.statusLabel ?? 'Trial';
  }

  Future<void> _open() async {
    await Get.toNamed<void>(AppRoutes.plan);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final days = _snapshot?.remainingDays() ?? 0;
    final paid = _snapshot?.isPaid ?? false;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _badge,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listName.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: .92),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!paid && days > 0) ...[
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        '$days',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        days == 1 ? 'day' : 'days',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: .88),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: .9),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
