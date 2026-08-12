import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    this.content,
    this.actions = const [],
    this.icon = Icons.auto_awesome_rounded,
    this.iconColor = AppColors.primary,
    this.scrollable = false,
    this.stackedActions = false,
    super.key,
  });

  final Widget title;
  final Widget? content;
  final List<Widget> actions;
  final IconData icon;
  final Color iconColor;
  final bool scrollable;
  final bool stackedActions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? .18 : .11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ),
        const SizedBox(height: 16),
        DefaultTextStyle.merge(style: AppTextStyles.sectionTitle, child: title),
        if (content != null) ...[
          const SizedBox(height: 10),
          DefaultTextStyle.merge(
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.4,
            ),
            child: content!,
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (stackedActions)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  actions[index],
                ],
              ],
            )
          else
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
        ],
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: scrollable ? SingleChildScrollView(child: body) : body,
        ),
      ),
    );
  }
}
