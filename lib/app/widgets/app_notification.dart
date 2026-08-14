import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

enum AppNotificationType { success, warning, error, info }

abstract final class AppNotification {
  static void success(String title, String message) =>
      show(title, message, type: AppNotificationType.success);

  static void warning(String title, String message) =>
      show(title, message, type: AppNotificationType.warning);

  static void error(String title, String message) =>
      show(title, message, type: AppNotificationType.error);

  static void info(String title, String message) =>
      show(title, message, type: AppNotificationType.info);

  static void show(
    String title,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = Get.context;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _color(type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: EdgeInsets.zero,
          elevation: 12,
          duration: duration,
          dismissDirection: DismissDirection.horizontal,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? .22 : .12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(_icon(type), color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n('Dismiss'),
                  onPressed: messenger.hideCurrentSnackBar,
                  icon: const Icon(Icons.close_rounded, size: 19),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      );
  }

  static Color _color(AppNotificationType type) => switch (type) {
    AppNotificationType.success => AppColors.success,
    AppNotificationType.warning => AppColors.warning,
    AppNotificationType.error => AppColors.error,
    AppNotificationType.info => AppColors.info,
  };

  static IconData _icon(AppNotificationType type) => switch (type) {
    AppNotificationType.success => Icons.check_circle_outline_rounded,
    AppNotificationType.warning => Icons.info_outline_rounded,
    AppNotificationType.error => Icons.error_outline_rounded,
    AppNotificationType.info => Icons.notifications_none_rounded,
  };
}
