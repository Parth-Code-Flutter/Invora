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

const _denseChipStrut = StrutStyle(
  fontSize: 11,
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

const _denseChipCountStrut = StrutStyle(
  fontSize: 9,
  height: 1,
  leading: 0,
  forceStrutHeight: true,
);

/// Selected fill for Documents status chips (All, Unpaid, Overdue, …).
Color appFilterSelectedColor(String status) => switch (status) {
  'all' => const Color(0xFF1E1B1E),
  'unpaid' => const Color(0xFFC2410C),
  'overdue' => const Color(0xFFE11D48),
  'draft' => const Color(0xFF6B7280),
  'paid' => const Color(0xFF059669),
  'partially_paid' => const Color(0xFFD97706),
  'cancelled' => const Color(0xFF78716C),
  'sent' => const Color(0xFF2563EB),
  'accepted' => const Color(0xFF059669),
  'rejected' => const Color(0xFFDC2626),
  'expired' => const Color(0xFF78716C),
  _ => AppColors.secondary,
};

/// Dense white Documents chips with a selected fill that follows the filter.
AppFilterChip documentsStatusChip({
  required String label,
  required String status,
  required bool selected,
  required int count,
  required ValueChanged<bool> onSelected,
}) {
  final overdue = status == 'overdue';
  return AppFilterChip(
    label: label,
    selected: selected,
    dense: true,
    idleFill: Colors.white,
    selectedColor: appFilterSelectedColor(status),
    count: count,
    countFill: overdue ? const Color(0xFFFFE4E6) : const Color(0xFFF5F5F4),
    countColor: overdue ? const Color(0xFFE11D48) : const Color(0xFF78716C),
    onSelected: onSelected,
  );
}

/// Consistent filter option with a clear selected state and optional icon.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.count,
    this.selectedColor,
    this.idleFill,
    this.countFill,
    this.countColor,
    this.dense = false,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final int? count;
  final Color? selectedColor;
  final Color? idleFill;
  final Color? countFill;
  final Color? countColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = selectedColor ?? AppColors.secondary;
    final idleFg = isDark ? AppColors.darkTextSecondary : AppColors.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: BorderSide(
        color: selected
            ? selectedFill
            : isDark
            ? AppColors.darkBorder
            : const Color(0xCCE5E7EB),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '$label filter',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? selectedFill
            : isDark
            ? AppColors.darkSurfaceVariant
            : (idleFill ?? const Color(0xFFF9FAFB)),
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: dense
                ? const EdgeInsets.fromLTRB(10, 5, 8, 5)
                : const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: dense ? 14 : 16,
                    color: selected ? Colors.white : idleFg,
                  ),
                  SizedBox(width: dense ? 4 : 6),
                ],
                Text(
                  label,
                  strutStyle: dense ? _denseChipStrut : _chipStrut,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: dense ? 11 : null,
                    height: 1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : idleFg,
                  ),
                ),
                if (count != null) ...[
                  SizedBox(width: dense ? 6 : 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: .2)
                          : (countFill ??
                                (isDark
                                    ? AppColors.darkSurface
                                    : const Color(0xB3E5E7EB))),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dense ? 5 : 6,
                        vertical: dense ? 1 : 2,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        strutStyle: dense
                            ? _denseChipCountStrut
                            : _chipCountStrut,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? Colors.white
                              : (countColor ??
                                    (isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF4B5563))),
                          fontSize: dense ? 9 : 10,
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
