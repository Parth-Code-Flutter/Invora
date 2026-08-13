import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppGroupedPosition { single, start, middle, end }

extension AppGroupedPositionX on AppGroupedPosition {
  static AppGroupedPosition resolve(int index, int length) {
    if (length <= 1) return AppGroupedPosition.single;
    if (index == 0) return AppGroupedPosition.start;
    if (index == length - 1) return AppGroupedPosition.end;
    return AppGroupedPosition.middle;
  }

  BorderRadius get borderRadius {
    const radius = Radius.circular(AppSpacing.cardRadius);
    return switch (this) {
      AppGroupedPosition.single => const BorderRadius.all(radius),
      AppGroupedPosition.start => const BorderRadius.vertical(top: radius),
      AppGroupedPosition.end => const BorderRadius.vertical(bottom: radius),
      AppGroupedPosition.middle => BorderRadius.zero,
    };
  }
}

/// One row inside an inset grouped list (iOS Settings / Stripe activity).
class AppGroupedTile extends StatelessWidget {
  const AppGroupedTile({
    required this.child,
    this.position = AppGroupedPosition.single,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.accentColor,
    super.key,
  });

  final Widget child;
  final AppGroupedPosition position;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final side = BorderSide(color: border);
    final radius = position.borderRadius;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: radius,
          border: Border(
            top:
                position == AppGroupedPosition.start ||
                    position == AppGroupedPosition.single
                ? side
                : BorderSide.none,
            left: side,
            right: side,
            bottom: side,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: accentColor == null
                ? Padding(padding: padding, child: child)
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3.5, color: accentColor),
                        Expanded(
                          child: Padding(padding: padding, child: child),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
