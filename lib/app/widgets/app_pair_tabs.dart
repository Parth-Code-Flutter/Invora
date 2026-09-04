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
    this.icons,
    super.key,
  }) : assert(labels.length > 1),
       assert(counts == null || counts.length == labels.length),
       assert(icons == null || icons.length == labels.length);

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int>? counts;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? AppColors.darkSurface : const Color(0xFFFFF8F4);
    final idle = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final selected = isDark ? AppColors.primary : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 42,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / labels.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      key: const ValueKey('app-segment-indicator'),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: tabWidth * index,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: track,
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: const SizedBox.expand(),
                          ),
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
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: i == index
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        onChanged(i);
                                      },
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  scale: i == index ? 1 : .97,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (icons != null) ...[
                                        Icon(
                                          icons![i],
                                          size: 17,
                                          color: i == index ? selected : idle,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Flexible(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 12.5,
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                            color: i == index ? selected : idle,
                                          ),
                                          child: Text(
                                            labels[i],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      if (counts != null && counts![i] > 0) ...[
                                        const SizedBox(width: 5),
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            border: Border.all(
                                              color: i == index
                                                  ? selected.withValues(
                                                      alpha: .45,
                                                    )
                                                  : (isDark
                                                        ? AppColors.darkBorder
                                                        : AppColors.border),
                                            ),
                                          ),
                                          child: Text(
                                            '${counts![i]}',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  fontSize: 10,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w800,
                                                  color: i == index
                                                      ? selected
                                                      : idle,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
    required this.leftIcon,
    required this.rightIcon,
    super.key,
  });

  final String left;
  final String right;
  final int index;
  final ValueChanged<int> onChanged;
  final IconData leftIcon, rightIcon;

  @override
  Widget build(BuildContext context) {
    return AppSegmentTabs(
      labels: [left, right],
      icons: [leftIcon, rightIcon],
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
