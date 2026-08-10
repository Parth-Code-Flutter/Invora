import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_card.dart';

/// A compact, grouped navigation surface for settings and secondary tools.
class AppMenuGroup extends StatelessWidget {
  const AppMenuGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const Divider(height: 1, indent: 60),
        ],
      ],
    ),
  );
}

/// A consistent destination row with enough context to scan before opening it.
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color = AppColors.primary,
    this.background = AppColors.primaryLight,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    minTileHeight: 72,
    leading: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
    title: Text(title, style: AppTextStyles.cardTitle),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    ),
    trailing:
        trailing ??
        const Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: AppColors.textTertiary,
        ),
  );
}
