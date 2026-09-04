import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

/// Two equal tabs for Sales | Purchases and Customers | Suppliers.
class AppPairTabs extends StatelessWidget {
  const AppPairTabs({
    required this.left,
    required this.right,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final String left;
  final String right;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _Tab(
                label: left,
                selected: index == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(0);
                },
              ),
              _Tab(
                label: right,
                selected: index == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        elevation: selected ? 0.4 : 0,
        shadowColor: const Color(0x33321D30),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
