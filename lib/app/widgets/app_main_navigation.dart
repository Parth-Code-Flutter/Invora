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
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
            Expanded(child: _createButton(context)),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 31,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                  fill: selected ? 1 : 0,
                  weight: selected ? 650 : 450,
                  opticalSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context) => Semantics(
    button: true,
    label: 'Create new',
    child: InkWell(
      onTap: () => _showCreateSheet(context),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x3D7B2F68),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Symbols.add_rounded,
              color: Colors.white,
              size: 25,
              weight: 650,
            ),
          ),
          Text(
            'Create',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
