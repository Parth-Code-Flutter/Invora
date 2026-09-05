import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

const _chipStrut = StrutStyle(
  fontSize: 12,
  height: 1,
  leading: 0,
  forceStrutHeight: true,
);

const _chipCountStrut = StrutStyle(
  fontSize: 10,
  height: 1,
  leading: 0,
  forceStrutHeight: true,
);

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
    final idleFg = isDark ? AppColors.darkTextSecondary : AppColors.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected
            ? AppColors.secondary
            : isDark
            ? AppColors.darkBorder
            : AppColors.border,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '$label filter',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.secondary
            : isDark
            ? AppColors.darkSurfaceVariant
            : Colors.white,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? Colors.white : idleFg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  strutStyle: _chipStrut,
                  style: AppTextStyles.caption.copyWith(
                    height: 1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : idleFg,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: .2)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        strutStyle: _chipCountStrut,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.primaryDark,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
