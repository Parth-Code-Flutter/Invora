import 'dart:ui';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import '../utils/responsive_utils.dart';

enum MainDestination { home, documents, products, parties, more }

class _DockItem {
  const _DockItem({
    required this.destination,
    required this.icon,
    required this.label,
    required this.route,
  });

  final MainDestination destination;
  final IconData icon;
  final String label;
  final String route;
}

const _dockItems = <_DockItem>[
  _DockItem(
    destination: MainDestination.home,
    icon: Symbols.home_rounded,
    label: 'Home',
    route: AppRoutes.dashboard,
  ),
  _DockItem(
    destination: MainDestination.documents,
    icon: Symbols.receipt_long_rounded,
    label: 'Documents',
    route: AppRoutes.documents,
  ),
  _DockItem(
    destination: MainDestination.products,
    icon: Symbols.package_2_rounded,
    label: 'Products',
    route: AppRoutes.products,
  ),
  _DockItem(
    destination: MainDestination.parties,
    icon: Symbols.groups_rounded,
    label: 'Parties',
    route: AppRoutes.parties,
  ),
  _DockItem(
    destination: MainDestination.more,
    icon: Symbols.apps_rounded,
    label: 'More',
    route: AppRoutes.more,
  ),
];

const _dockHeight = 52.0;
const _indicatorWidth = 14.0;
const _indicatorHeight = 3.0;

class AppMainNavigation extends StatelessWidget {
  const AppMainNavigation({required this.current, super.key});
  final MainDestination current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final selectedIndex = MainDestination.values.indexOf(current);
    final radius = ios ? 28.0 : 22.0;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        ios ? 18 : 14,
        0,
        ios ? 18 : 14,
        ios ? 6 : 8,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(isDark ? 0x66000000 : 0x1A321D30),
                blurRadius: ios ? 20 : 28,
                offset: Offset(0, ios ? 8 : 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: ios ? 28 : 18,
                sigmaY: ios ? 28 : 18,
              ),
              child: ColoredBox(
                color: isDark
                    ? const Color(0xCC2A1528)
                    : Color.fromRGBO(255, 255, 255, ios ? 0.72 : 0.90),
                child: SizedBox(
                  height: _dockHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabWidth = constraints.maxWidth / _dockItems.length;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            left:
                                tabWidth * selectedIndex +
                                (tabWidth - _indicatorWidth) / 2,
                            bottom: 8,
                            width: _indicatorWidth,
                            height: _indicatorHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (final item in _dockItems)
                                _DockTab(
                                  item: item,
                                  selected: current == item.destination,
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
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatefulWidget {
  const _DockTab({required this.item, required this.selected});

  final _DockItem item;
  final bool selected;

  @override
  State<_DockTab> createState() => _DockTabState();
}

class _DockTabState extends State<_DockTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_bounce);
    if (widget.selected) _bounce.value = 1;
  }

  @override
  void didUpdateWidget(_DockTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _bounce.forward(from: 0);
    } else if (!widget.selected && oldWidget.selected) {
      _bounce.value = 0;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _select() {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    if (ios) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    _openDestination(widget.item.route);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.72)
        : AppColors.textTertiary;
    const activeColor = AppColors.primary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.item.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : _select,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: selected ? 1 : 0),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, fill, _) => Icon(
                  widget.item.icon,
                  size: 28,
                  color: Color.lerp(idleColor, activeColor, fill),
                  fill: fill,
                  weight: 400 + (300 * fill),
                  opticalSize: 28,
                  grade: 25 * fill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openDestination(String route) async {
  await AppFocus.dismissKeyboard();
  Get.offAllNamed<void>(route);
}

class AppSalesNavigationRail extends StatelessWidget {
  const AppSalesNavigationRail({required this.current, super.key});
  final MainDestination current;

  static const _routes = [
    AppRoutes.dashboard,
    AppRoutes.documents,
    AppRoutes.products,
    AppRoutes.parties,
    AppRoutes.more,
  ];

  @override
  Widget build(BuildContext context) {
    final selected = MainDestination.values.indexOf(current);
    return NavigationRail(
      selectedIndex: selected,
      extended: ResponsiveUtils.isLargeTablet(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      useIndicator: false,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
      selectedLabelTextStyle: AppTextStyles.caption.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textTertiary,
      ),
      labelType: ResponsiveUtils.isLargeTablet(context)
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      onDestinationSelected: (index) async {
        if (index == selected) return;
        await AppFocus.dismissKeyboard();
        Get.offAllNamed<void>(_routes[index]);
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Symbols.home_rounded),
          selectedIcon: Icon(Symbols.home_rounded, fill: 1),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.receipt_long_rounded),
          selectedIcon: Icon(Symbols.receipt_long_rounded, fill: 1),
          label: Text('Documents'),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.package_2_rounded),
          selectedIcon: Icon(Symbols.package_2_rounded, fill: 1),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.groups_rounded),
          selectedIcon: Icon(Symbols.groups_rounded, fill: 1),
          label: Text('Parties'),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.apps_rounded),
          selectedIcon: Icon(Symbols.apps_rounded, fill: 1),
          label: Text('More'),
        ),
      ],
    );
  }
}
