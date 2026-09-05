import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.radius,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    // Keep progress visible on the branded surface even when callers disable
    // taps while an asynchronous action is running.
    final branded = onPressed != null || isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = isLoading
        ? const SizedBox(
            key: ValueKey('app-button-loader'),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                SizedBox(width: 16, height: 16, child: leading),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 20),
              ],
            ],
          );

    final button = Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: ResponsiveUtils.height(
          context,
          ResponsiveUtils.isTablet(context) ? 56 : AppSpacing.buttonHeight,
        ),
        decoration: BoxDecoration(
          gradient: branded
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: branded
              ? null
              : isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(
            radius ?? AppSpacing.buttonRadius,
          ),
          boxShadow: branded
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: .2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: .12),
            ),
            child: Center(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: branded
                      ? Colors.white
                      : isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textTertiary,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: branded
                        ? Colors.white
                        : isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textTertiary,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
