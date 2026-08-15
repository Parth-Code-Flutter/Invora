import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/app_focus.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({this.onPressed, this.tooltip, super.key});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: IconButton(
        tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => AppFocus.maybePop(context),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          padding: EdgeInsets.zero,
          backgroundColor: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceSoft,
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.textPrimary,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }
}
