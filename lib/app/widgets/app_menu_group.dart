import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';

/// A single bordered panel of destination rows, in the classic settings style.
class AppMenuGroup extends StatelessWidget {
  const AppMenuGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 66,
                endIndent: 16,
                color: border,
              ),
          ],
        ],
      ),
    );
  }
}

/// A compact destination row for grouped settings panels.
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color = AppColors.secondary,
    this.background = AppColors.secondaryLight,
    this.trailing,
    this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final Widget? trailing;

  /// When set, this row is a choice instead of a destination: a check marks
  /// the active option and an empty circle marks the other.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selected == true;
    final iconSurface = isDark ? color.withValues(alpha: .16) : background;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final markColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: isSelected
            ? (isDark
                  ? color.withValues(alpha: .12)
                  : AppColors.secondaryLight.withValues(alpha: .65))
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                  fill: 0,
                  weight: 520,
                  opticalSize: 24,
                  grade: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.listName),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: muted,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    selected == null
                        ? Icons.chevron_right_rounded
                        : isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 22,
                    color: isSelected ? color : markColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
