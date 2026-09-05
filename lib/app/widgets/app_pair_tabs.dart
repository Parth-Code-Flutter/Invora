import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import '../utils/responsive_utils.dart';

const _countStrut = StrutStyle(
  fontSize: 10,
  height: 1,
  leading: 0,
  forceStrutHeight: true,
);

/// Segmented tabs for Sales | Purchases, Customers | Suppliers,
/// and catalog All | Products | Services.
class AppSegmentTabs extends StatelessWidget {
  const AppSegmentTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
    this.counts,
    this.icons,
    this.leadingIcons,
    this.inkSelected = false,
    this.padding,
    super.key,
  }) : assert(labels.length > 1),
       assert(counts == null || counts.length == labels.length),
       assert(icons == null || icons.length == labels.length),
       assert(leadingIcons == null || leadingIcons.length == labels.length);

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int>? counts;
  final List<IconData>? icons;
  final List<Widget>? leadingIcons;
  final bool inkSelected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? AppColors.darkSurfaceVariant
        : const Color(0xFFF2EDEE);
    final pill = isDark ? AppColors.darkSurface : Colors.white;
    final idle = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
    final selectedColor = inkSelected
        ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF111827))
        : (isDark ? AppColors.primary : AppColors.secondary);
    final hPad = ResponsiveUtils.horizontalPadding(context);
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(hPad, 2, hPad, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / labels.length;
                final twoTabs = labels.length == 2;
                final labelSize = twoTabs ? 14.0 : 13.0;
                final labelStrut = StrutStyle(
                  fontSize: labelSize,
                  height: 1,
                  leading: 0,
                  forceStrutHeight: true,
                );
                final showIcons =
                    leadingIcons != null ||
                    (icons != null && (twoTabs || tabWidth >= 108));
                return Stack(
                  children: [
                    AnimatedPositioned(
                      key: const ValueKey('app-segment-indicator'),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: tabWidth * index,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pill,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(isDark ? 0x40000000 : 0x14321D30),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
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
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (showIcons) ...[
                                            if (leadingIcons != null)
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: leadingIcons![i],
                                              )
                                            else
                                              Icon(
                                                icons![i],
                                                size: 16,
                                                color: i == index
                                                    ? selectedColor
                                                    : idle,
                                              ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              labels[i],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              strutStyle: labelStrut,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    fontSize: labelSize,
                                                    height: 1,
                                                    fontWeight: i == index
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: i == index
                                                        ? selectedColor
                                                        : idle,
                                                  ),
                                            ),
                                          ),
                                          if (counts != null &&
                                              counts![i] > 0) ...[
                                            const SizedBox(width: 6),
                                            DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: i == index
                                                    ? selectedColor
                                                    : (isDark
                                                          ? AppColors
                                                                .darkSurface
                                                          : Colors.white),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                child: Text(
                                                  '${counts![i]}',
                                                  textAlign: TextAlign.center,
                                                  strutStyle: _countStrut,
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        fontSize: 10,
                                                        height: 1,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: i == index
                                                            ? Colors.white
                                                            : selectedColor,
                                                      ),
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
                            ),
                        ],
                      ),
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
    this.leadingIcons,
    this.inkSelected = false,
    super.key,
  });

  final String left;
  final String right;
  final int index;
  final ValueChanged<int> onChanged;
  final IconData leftIcon, rightIcon;
  final List<Widget>? leadingIcons;
  final bool inkSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentTabs(
      labels: [left, right],
      icons: [leftIcon, rightIcon],
      leadingIcons: leadingIcons,
      inkSelected: inkSelected,
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
