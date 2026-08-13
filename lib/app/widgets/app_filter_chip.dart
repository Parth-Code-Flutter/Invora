import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

/// Consistent filter option with a clear selected state and optional icon.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.count,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label filter',
      child: ChoiceChip(
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .2)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? Colors.white : AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceSoft,
        selectedColor: AppColors.secondary,
        side: BorderSide(
          color: selected
              ? AppColors.secondary
              : isDark
              ? AppColors.darkBorder
              : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
    );
  }
}
