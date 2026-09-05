import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/dock_icons.dart';
import '../routes/app_routes.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import '../utils/responsive_utils.dart';

enum MainDestination { home, documents, products, parties, more }

class _DockItem {
  const _DockItem({
    required this.destination,
    required this.outlineAsset,
    required this.filledAsset,
    required this.label,
    required this.route,
    this.preserveFilledColors = false,
  });

  final MainDestination destination;
  final String outlineAsset;
  final String filledAsset;
  final String label;
  final String route;
  final bool preserveFilledColors;
}

const _dockItems = <_DockItem>[
  _DockItem(
    destination: MainDestination.home,
    outlineAsset: DockIcons.homeOutline,
    filledAsset: DockIcons.homeFilled,
    label: 'Home',
    route: AppRoutes.dashboard,
  ),
  _DockItem(
    destination: MainDestination.documents,
    outlineAsset: DockIcons.documentsOutline,
    filledAsset: DockIcons.documentsFilled,
    label: 'Documents',
    route: AppRoutes.documents,
  ),
  _DockItem(
    destination: MainDestination.products,
    outlineAsset: DockIcons.productsOutline,
    filledAsset: DockIcons.productsFilled,
    label: 'Products',
    route: AppRoutes.products,
    preserveFilledColors: true,
  ),
  _DockItem(
    destination: MainDestination.parties,
    outlineAsset: DockIcons.partiesOutline,
    filledAsset: DockIcons.partiesFilled,
    label: 'Parties',
    route: AppRoutes.parties,
  ),
  _DockItem(
    destination: MainDestination.more,
    outlineAsset: DockIcons.moreOutline,
    filledAsset: DockIcons.moreFilled,
    label: 'More',
    route: AppRoutes.more,
  ),
];

const _dockIdle = Color(0xFF8F827E);
const _dockCoral = Color(0xFFFF6F61);
const _dockPlum = Color(0xFF843B62);
const _dockRing = Color(0xCCEFE6E1);
const _dockHeight = 56.0;

class AppMainNavigation extends StatelessWidget {
  const AppMainNavigation({required this.current, super.key});
  final MainDestination current;

  static Key tabKey(MainDestination destination) =>
      ValueKey('dock-${destination.name}');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Color(isDark ? 0x66000000 : 0x1F881337),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Color(isDark ? 0x33000000 : 0x14F43F5E),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE62A1528)
                    : const Color.fromRGBO(255, 255, 255, 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : _dockRing,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
                child: SizedBox(
                  height: _dockHeight,
                  child: Row(
                    children: [
                      for (final item in _dockItems)
                        _DockTab(
                          item: item,
                          selected: current == item.destination,
                        ),
                    ],
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

class _DockTab extends StatelessWidget {
  const _DockTab({required this.item, required this.selected});

  final _DockItem item;
  final bool selected;

  void _select(BuildContext context) {
    HapticFeedback.lightImpact();
    _openDestination(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.72)
        : _dockIdle;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        excludeSemantics: true,
        child: GestureDetector(
          key: AppMainNavigation.tabKey(item.destination),
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : () => _select(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DockGlyph(item: item, selected: selected, idleColor: idleColor),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [_dockCoral, _dockPlum],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockGlyph extends StatelessWidget {
  const _DockGlyph({
    required this.item,
    required this.selected,
    required this.idleColor,
  });

  final _DockItem item;
  final bool selected;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.asset(
      selected ? item.filledAsset : item.outlineAsset,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      colorFilter: selected
          ? null
          : ColorFilter.mode(idleColor, BlendMode.srcIn),
    );
    if (!selected || item.preserveFilledColors) {
      return SizedBox(width: 24, height: 24, child: picture);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_dockCoral, _dockPlum],
        ).createShader(bounds),
        child: picture,
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

  @override
  Widget build(BuildContext context) {
    final selected = MainDestination.values.indexOf(current);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idle = isDark ? AppColors.darkTextSecondary : _dockIdle;
    return NavigationRail(
      selectedIndex: selected,
      extended: ResponsiveUtils.isLargeTablet(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      useIndicator: false,
      selectedIconTheme: const IconThemeData(color: _dockCoral),
      unselectedIconTheme: IconThemeData(color: idle),
      selectedLabelTextStyle: AppTextStyles.caption.copyWith(
        color: _dockCoral,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: AppTextStyles.caption.copyWith(color: idle),
      labelType: ResponsiveUtils.isLargeTablet(context)
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      onDestinationSelected: (index) async {
        if (index == selected) return;
        await AppFocus.dismissKeyboard();
        Get.offAllNamed<void>(_dockItems[index].route);
      },
      destinations: [
        for (final item in _dockItems)
          NavigationRailDestination(
            icon: _DockGlyph(item: item, selected: false, idleColor: idle),
            selectedIcon: _DockGlyph(
              item: item,
              selected: true,
              idleColor: idle,
            ),
            label: Text(item.label),
          ),
      ],
    );
  }
}
