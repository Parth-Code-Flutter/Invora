import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

/// Segmented tabs for Sales | Purchases, Customers | Suppliers,
/// and catalog All | Products | Services.
class AppSegmentTabs extends StatelessWidget {
  const AppSegmentTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
    this.counts,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int>? counts;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceMuted;
    final pill = isDark ? AppColors.darkSurface : Colors.white;
    final idle = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / labels.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      left: tabWidth * index,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pill,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: Color(isDark ? 0x33000000 : 0x14321D30),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == index,
                              label: counts != null
                                  ? '${labels[i]}, ${counts![i]}'
                                  : labels[i],
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: i == index
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        onChanged(i);
                                      },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 13,
                                          height: 1,
                                          fontWeight: FontWeight.w700,
                                          color: i == index
                                              ? AppColors.secondary
                                              : idle,
                                        ),
                                        child: Text(
                                          labels[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (counts != null && counts![i] > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '${counts![i]}',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: i == index
                                              ? AppColors.secondary
                                              : idle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Two equal tabs for Sales | Purchases and Customers | Suppliers.
class AppPairTabs extends StatelessWidget {
  const AppPairTabs({
    required this.left,
    required this.right,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final String left;
  final String right;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmentTabs(
      labels: [left, right],
      index: index,
      onChanged: onChanged,
    );
  }
}

/// Horizontal swipe between sibling tabs, used on the catalog list.
class AppSwipeTabs extends StatelessWidget {
  const AppSwipeTabs({
    required this.index,
    required this.length,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final int index;
  final int length;
  final ValueChanged<int> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -360 && index < length - 1) {
          HapticFeedback.selectionClick();
          onChanged(index + 1);
        } else if (velocity > 360 && index > 0) {
          HapticFeedback.selectionClick();
          onChanged(index - 1);
        }
      },
      child: child,
    );
  }
}

/// Keeps a [PageView] child alive when it is offstage.
class AppKeepAlive extends StatefulWidget {
  const AppKeepAlive({required this.child, super.key});

  final Widget child;

  @override
  State<AppKeepAlive> createState() => _AppKeepAliveState();
}

class _AppKeepAliveState extends State<AppKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
