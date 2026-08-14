import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../themes/app_text_styles.dart';

/// A compact, branded module header that gives each workspace its own identity
/// without pushing the primary task below the fold.
class AppModuleBanner extends StatelessWidget {
  const AppModuleBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactAction = constraints.maxWidth < 330;
          return Stack(
            children: [
              Positioned(
                right: -24,
                top: -42,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .09),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .2),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 27),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white.withValues(alpha: .78),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 10),
                    if (compactAction)
                      Tooltip(
                        message: actionLabel!,
                        child: IconButton.filled(
                          onPressed: onAction,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colors.first,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colors.first,
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: Text(actionLabel!),
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
