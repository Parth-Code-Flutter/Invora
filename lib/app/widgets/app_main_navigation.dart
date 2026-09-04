import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import '../utils/responsive_utils.dart';
import 'app_bottom_sheet.dart';

enum MainDestination { home, documents, parties, more }

class AppMainNavigation extends StatelessWidget {
  const AppMainNavigation({required this.current, super.key});
  final MainDestination current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F321D30),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _destination(
                      destination: MainDestination.home,
                      icon: Symbols.home_rounded,
                      label: 'Home',
                      route: AppRoutes.dashboard,
                    ),
                    _destination(
                      destination: MainDestination.documents,
                      icon: Symbols.receipt_long_rounded,
                      label: 'Documents',
                      route: AppRoutes.documents,
                    ),
                    const Expanded(child: SizedBox()),
                    _destination(
                      destination: MainDestination.parties,
                      icon: Symbols.group_rounded,
                      label: 'Parties',
                      route: AppRoutes.parties,
                    ),
                    _destination(
                      destination: MainDestination.more,
                      icon: Symbols.widgets_rounded,
                      label: 'More',
                      route: AppRoutes.more,
                    ),
                  ],
                ),
              ),
            ),
            _createButton(context),
          ],
        ),
      ),
    );
  }

  Widget _destination({
    required MainDestination destination,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final selected = current == destination;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: selected ? null : () => _openDestination(route),
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
                fill: selected ? 1 : 0,
                weight: selected ? 650 : 450,
                opticalSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context) => SizedBox(
    width: 68,
    height: 70,
    child: Semantics(
      button: true,
      label: 'Create new',
      child: InkWell(
        onTap: () => showCreateSheet(context),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3D7B2F68),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.add_rounded,
                  color: Colors.white,
                  size: 28,
                  weight: 650,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openDestination(String route) async {
    await AppFocus.dismissKeyboard();
    // Main destinations replace the root route and are configured without a
    // page transition, so they behave like tabs rather than pushed screens.
    Get.offAllNamed<void>(route);
  }
}

Future<void> showCreateSheet(BuildContext context) async {
  await AppFocus.dismissKeyboard();
  if (!context.mounted) return;
  await showAppBottomSheet<void>(
    context: context,
    title: 'Create new',
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CreateAction(
              icon: Symbols.receipt_long_rounded,
              title: 'Invoice',
              subtitle: 'Create a customer invoice',
              onTap: () => _openCreateRoute(context, AppRoutes.invoiceCreate),
            ),
            _CreateAction(
              icon: Symbols.request_quote_rounded,
              title: 'Estimate',
              subtitle: 'Create a quotation or estimate',
              onTap: () => _openCreateRoute(context, AppRoutes.quotationCreate),
            ),
            _CreateAction(
              icon: Symbols.receipt_long_rounded,
              title: 'Purchase bill',
              subtitle: 'Record a supplier bill',
              onTap: () =>
                  _openCreateRoute(context, AppRoutes.purchaseBillCreate),
            ),
            _CreateAction(
              icon: Symbols.assignment_rounded,
              title: 'Purchase order',
              subtitle: 'Order goods, then receive and bill later',
              onTap: () =>
                  _openCreateRoute(context, AppRoutes.purchaseOrderCreate),
            ),
            _CreateAction(
              icon: Symbols.person_add_rounded,
              title: 'Customer',
              subtitle: 'Save a new customer',
              onTap: () => _openCreateRoute(context, AppRoutes.customerAdd),
            ),
            _CreateAction(
              icon: Symbols.storefront_rounded,
              title: 'Supplier',
              subtitle: 'Add a supplier',
              onTap: () => _openCreateRoute(context, AppRoutes.supplierAdd),
            ),
            _CreateAction(
              icon: Symbols.inventory_2_rounded,
              title: 'Product or service',
              subtitle: 'Add an item for faster invoicing',
              onTap: () => _openCreateRoute(context, AppRoutes.productAdd),
            ),
          ],
        ),
      ),
    ),
  );
}

@Deprecated('Use showCreateSheet')
Future<void> showSalesCreateSheet(BuildContext context) =>
    showCreateSheet(context);

void _openCreateRoute(BuildContext context, String route) {
  Navigator.pop(context);
  Get.toNamed<void>(route);
}

class AppSalesNavigationRail extends StatelessWidget {
  const AppSalesNavigationRail({required this.current, super.key});
  final MainDestination current;

  static const _routes = [
    AppRoutes.dashboard,
    AppRoutes.documents,
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
      indicatorColor: AppColors.primaryLight,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: AppTextStyles.caption.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: AppTextStyles.caption,
      labelType: ResponsiveUtils.isLargeTablet(context)
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      onDestinationSelected: (index) async {
        if (index == selected) return;
        await AppFocus.dismissKeyboard();
        Get.offAllNamed<void>(_routes[index]);
      },
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton(
              heroTag: 'sales-rail-create',
              tooltip: l10n('Create new'),
              onPressed: () => showCreateSheet(context),
              child: const Icon(Symbols.add_rounded),
            ),
          ),
        ),
      ),
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
          icon: Icon(Symbols.group_rounded),
          selectedIcon: Icon(Symbols.group_rounded, fill: 1),
          label: Text('Parties'),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.widgets_rounded),
          selectedIcon: Icon(Symbols.widgets_rounded, fill: 1),
          label: Text('More'),
        ),
      ],
    );
  }
}

class _CreateAction extends StatelessWidget {
  const _CreateAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(title, style: AppTextStyles.cardTitle),
    subtitle: Text(subtitle),
    trailing: const Icon(Symbols.arrow_forward_ios_rounded, size: 17),
    onTap: onTap,
  );
}
