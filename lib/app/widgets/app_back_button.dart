import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';

ButtonStyle appBarChromeButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return IconButton.styleFrom(
    fixedSize: const Size.square(40),
    minimumSize: const Size.square(40),
    padding: EdgeInsets.zero,
    backgroundColor: isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceSoft,
    foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({this.onPressed, this.tooltip, super.key});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => AppFocus.maybePop(context),
        style: appBarChromeButtonStyle(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }
}

class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: appBarChromeButtonStyle(context),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleStyle = AppTextStyles.caption.copyWith(
      color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
      fontWeight: FontWeight.w500,
      fontSize: 11,
      height: 1.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
      ],
    );
  }
}
