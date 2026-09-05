import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/services/account_entitlement_service.dart';
import '../controllers/more_controller.dart';
import '../more_destinations.dart';

abstract final class _MoreUi {
  static const page = Color(0xFFFBF9F7);
  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFFA8A29E);
  static const body = Color(0xFF78716C);
  static const line = Color(0xFFF5F5F4);
  static const cardBorder = Color(0x99E7E5E4);
  static const groupBorder = Color(0xCCE7E5E4);
  static const avatar = Color(0xFF4A1D3F);
  static const chevronWell = Color(0xB3F5F5F4);
  static const activeFill = Color(0xFFECFDF5);
  static const activeBorder = Color(0xCCD1FAE5);
  static const activeText = Color(0xFF059669);
  static const shadow = Color(0x0A161118);
}

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkBackground : _MoreUi.page;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: page,
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: page,
          shape: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0x66E7E5E4),
            ),
          ),
        ),
      ),
      child: AppShell(
        destination: MainDestination.more,
        appBar: AppSearchAppBar(
          title: 'More',
          hint: 'Search features',
          largeTitle: true,
          searchIcon: SvgPicture.asset(
            MoreIcons.search,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          onChanged: controller.updateSearch,
        ),
        body: ResponsiveContent(
          tabletMaxWidth: 720,
          paddingBottom: 0,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            children: [
              Obx(
                () => controller.isSearching
                    ? const SizedBox.shrink()
                    : _BusinessHeader(
                        controller: controller,
                        profile: controller.profile.value,
                        categoryLabel: controller.categoryLabel.value,
                      ),
              ),
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
                      for (final group in groups) ...[
                        const SizedBox(height: 24),
                        _section(group),
                      ],
                    ],
                  ],
                );
              }),
              Obx(
                () => controller.isSearching
                    ? const SizedBox(height: 20)
                    : const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: _PrivacyNote(),
                      ),
              ),
            ],
          ),
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
        const SizedBox(height: 8),
        _MoreMenuGroup(
          children: [
            for (final item in group.items)
              _MoreMenuTile(item: item, onTap: () => _open(item)),
          ],
        ),
      ],
    );
  }

  Future<void> _open(MoreDestination item) async {
    final route = item.route;
    if (route == null) return;
    if (route == AppRoutes.products) {
      Get.offAllNamed<void>(route);
      return;
    }
    await Get.toNamed<void>(route);
    await controller.loadProfile();
  }
}

class _MoreMenuGroup extends StatelessWidget {
  const _MoreMenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : _MoreUi.groupBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: _MoreUi.shadow,
            blurRadius: 14,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : _MoreUi.line,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({required this.item, required this.onTap});

  final MoreDestination item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkTextPrimary : _MoreUi.ink;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : _MoreUi.body;
    final wellFill = isDark ? item.color.withValues(alpha: .16) : item.iconWell;
    final wellBorder = isDark ? AppColors.darkBorder : item.iconWellBorder;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: wellFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: wellBorder),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(
                    item.iconAsset,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.listName.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: SvgPicture.asset(
                  MoreIcons.chevron,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  colorFilter: isDark
                      ? const ColorFilter.mode(
                          AppColors.darkTextSecondary,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({
    required this.controller,
    required this.profile,
    required this.categoryLabel,
  });

  final MoreController controller;
  final BusinessProfileModel? profile;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = profile?.businessName.trim().isNotEmpty == true
        ? profile!.businessName.trim()
        : 'Your business';
    final subtitle = _subtitle(profile, categoryLabel);
    final badge = _planBadge();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: _MoreUi.shadow,
            blurRadius: 14,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : _MoreUi.cardBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: controller.editBusiness,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                _BusinessLogo(path: profile?.logoPath, name: name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : _MoreUi.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 22 / 16,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            _StatusBadge(label: badge.label, tone: badge.tone),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : _MoreUi.muted,
                            fontWeight: FontWeight.w400,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : _MoreUi.chevronWell,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: SvgPicture.asset(
                      MoreIcons.chevron,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      colorFilter: isDark
                          ? const ColorFilter.mode(
                              AppColors.darkTextSecondary,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _subtitle(BusinessProfileModel? profile, String category) {
    final parts = <String>[
      if (category.trim().isNotEmpty) category.trim(),
      if (profile?.mobile?.trim().isNotEmpty == true) profile!.mobile!.trim(),
    ];
    if (parts.isEmpty) return 'Complete your business profile';
    return parts.join('  •  ');
  }

  _PlanBadge? _planBadge() {
    if (!Get.isRegistered<AccountEntitlementService>()) return null;
    final snapshot = Get.find<AccountEntitlementService>().lastSnapshot;
    if (snapshot == null) return null;
    if (snapshot.isPaid) {
      return const _PlanBadge(label: 'Active', tone: _BadgeTone.active);
    }
    if (snapshot.isCancelled) {
      return const _PlanBadge(label: 'Ended', tone: _BadgeTone.ended);
    }
    return const _PlanBadge(label: 'Trial', tone: _BadgeTone.trial);
  }
}

enum _BadgeTone { active, trial, ended }

class _PlanBadge {
  const _PlanBadge({required this.label, required this.tone});
  final String label;
  final _BadgeTone tone;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fill;
    final Color border;
    final Color text;
    switch (tone) {
      case _BadgeTone.active:
        fill = isDark
            ? AppColors.success.withValues(alpha: .18)
            : _MoreUi.activeFill;
        border = isDark
            ? AppColors.success.withValues(alpha: .35)
            : _MoreUi.activeBorder;
        text = isDark ? AppColors.success : _MoreUi.activeText;
      case _BadgeTone.trial:
        fill = isDark
            ? AppColors.warning.withValues(alpha: .18)
            : AppColors.warningLight;
        border = isDark
            ? AppColors.warning.withValues(alpha: .35)
            : AppColors.warning.withValues(alpha: .28);
        text = AppColors.warning;
      case _BadgeTone.ended:
        fill = isDark ? AppColors.darkSurfaceVariant : _MoreUi.line;
        border = isDark ? AppColors.darkBorder : _MoreUi.cardBorder;
        text = isDark ? AppColors.darkTextSecondary : _MoreUi.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 16.5 / 11,
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
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: validPath
            ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
            : (isDark ? AppColors.secondary : _MoreUi.avatar),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .2)
                : const Color(0xB3F5F5F4),
            spreadRadius: 4,
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: validPath
          ? Image.file(File(path!), fit: BoxFit.cover, width: 48, height: 48)
          : Text(
              name.trim().isEmpty
                  ? 'I'
                  : name.trim().characters.first.toUpperCase(),
              style: AppTextStyles.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
                height: 28 / 18,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        value.toUpperCase(),
        style: AppTextStyles.small.copyWith(
          color: isDark ? AppColors.darkTextSecondary : _MoreUi.muted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 16.5 / 11,
          letterSpacing: 0.55,
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
    final color = isDark ? AppColors.darkTextSecondary : _MoreUi.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : const Color(0x99E7E5E4),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 14,
              height: 14,
              child: SvgPicture.asset(
                MoreIcons.lock,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Private by design. Your business data stays on this device.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
