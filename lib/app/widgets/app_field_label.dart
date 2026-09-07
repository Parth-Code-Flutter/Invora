import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../localization/app_localization.dart';
import '../themes/app_text_styles.dart';

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(
    this.label, {
    this.requiredField = false,
    this.trailing,
    super.key,
  });

  final String label;
  final bool requiredField;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Flexible(
          child: Text(
            AppLocalizer.text(label),
            style: AppTextStyles.small.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (requiredField) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primary,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    required this.label,
    required this.child,
    this.requiredField = false,
    this.trailing,
    this.helperText,
    super.key,
  });

  final String label;
  final Widget child;
  final bool requiredField;
  final Widget? trailing;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label, requiredField: requiredField, trailing: trailing),
        const SizedBox(height: 6),
        child,
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            AppLocalizer.text(helperText),
            style: AppTextStyles.small.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textTertiary,
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
