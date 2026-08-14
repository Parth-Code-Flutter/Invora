import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import 'app_bottom_sheet.dart';

enum MainDestination { home, invoices, customers, more }

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
                      destination: MainDestination.invoices,
                      icon: Symbols.receipt_long_rounded,
                      label: 'Invoices',
                      route: AppRoutes.invoices,
                    ),
                    const Expanded(child: SizedBox()),
                    _destination(
                      destination: MainDestination.customers,
                      icon: Symbols.group_rounded,
                      label: 'Customers',
                      route: AppRoutes.customers,
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
        onTap: () => _showCreateSheet(context),
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

  Future<void> _showCreateSheet(BuildContext context) {
    return _openCreateSheet(context);
  }

  Future<void> _openDestination(String route) async {
    await AppFocus.dismissKeyboard();
    // Main destinations replace the root route and are configured without a
    // page transition, so they behave like tabs rather than pushed screens.
    Get.offAllNamed<void>(route);
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    await AppFocus.dismissKeyboard();
    if (!context.mounted) return;
    await showAppBottomSheet<void>(
      context: context,
      title: 'Create new',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreateAction(
            icon: Symbols.receipt_long_rounded,
            title: 'Invoice',
            subtitle: 'Create a customer invoice',
            onTap: () => _open(context, AppRoutes.invoiceCreate),
          ),
          _CreateAction(
            icon: Symbols.request_quote_rounded,
            title: 'Estimate',
            subtitle: 'Create a quotation or estimate',
            onTap: () => _open(context, AppRoutes.quotationCreate),
          ),
          _CreateAction(
            icon: Symbols.person_add_rounded,
            title: 'Customer',
            subtitle: 'Save a new customer',
            onTap: () => _open(context, AppRoutes.customerAdd),
          ),
          _CreateAction(
            icon: Symbols.inventory_2_rounded,
            title: 'Product or service',
            subtitle: 'Add an item for faster invoicing',
            onTap: () => _open(context, AppRoutes.productAdd),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String route) {
    Navigator.pop(context);
    Get.toNamed<void>(route);
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
