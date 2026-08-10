import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

class AppEntityHeader extends StatelessWidget {
  const AppEntityHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final Widget icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x285B5CE2),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 28),
            child: DefaultTextStyle(
              style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
              child: icon,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
              ),
              if (subtitle?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
