import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
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
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: .8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18321D30),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _destination(
              context,
              destination: MainDestination.home,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              route: AppRoutes.dashboard,
            ),
            _destination(
              context,
              destination: MainDestination.invoices,
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
              label: 'Invoices',
              route: AppRoutes.invoices,
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Create new',
                child: Center(
                  child: InkResponse(
                    onTap: () => _showCreateSheet(context),
                    radius: 32,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x335B5CE2),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            _destination(
              context,
              destination: MainDestination.customers,
              icon: Icons.people_outline_rounded,
              selectedIcon: Icons.people_rounded,
              label: 'Customers',
              route: AppRoutes.customers,
            ),
            _destination(
              context,
              destination: MainDestination.more,
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'More',
              route: AppRoutes.more,
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context, {
    required MainDestination destination,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
  }) {
    final selected = current == destination;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: selected ? null : () => _openDestination(route),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 21),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            icon: Icons.receipt_long_outlined,
            title: 'Invoice',
            subtitle: 'Create a customer invoice',
            onTap: () => _open(context, AppRoutes.invoiceCreate),
          ),
          _CreateAction(
            icon: Icons.request_quote_outlined,
            title: 'Estimate',
            subtitle: 'Create a quotation or estimate',
            onTap: () => _open(context, AppRoutes.quotationCreate),
          ),
          _CreateAction(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Customer',
            subtitle: 'Save a new customer',
            onTap: () => _open(context, AppRoutes.customerAdd),
          ),
          _CreateAction(
            icon: Icons.add_box_outlined,
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
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
