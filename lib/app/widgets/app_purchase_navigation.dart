import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import 'app_bottom_sheet.dart';

enum PurchaseDestination { home, bills, suppliers, more }

class AppPurchaseNavigation extends StatelessWidget {
  const AppPurchaseNavigation({required this.current, super.key});
  final PurchaseDestination current;

  @override
  Widget build(BuildContext context) => SafeArea(
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
                border: Border.all(color: AppColors.border),
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
                  _item(
                    PurchaseDestination.home,
                    Symbols.home_rounded,
                    AppRoutes.purchases,
                    'Purchase home',
                  ),
                  _item(
                    PurchaseDestination.bills,
                    Symbols.receipt_long_rounded,
                    AppRoutes.purchaseBills,
                    'Purchase bills',
                  ),
                  const Expanded(child: SizedBox()),
                  _item(
                    PurchaseDestination.suppliers,
                    Symbols.storefront_rounded,
                    AppRoutes.suppliers,
                    'Suppliers',
                  ),
                  _item(
                    PurchaseDestination.more,
                    Symbols.widgets_rounded,
                    AppRoutes.more,
                    'More',
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => showAppBottomSheet<void>(
              context: context,
              title: 'Create purchase record',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Symbols.receipt_long_rounded),
                    title: const Text('Purchase bill'),
                    subtitle: const Text('Record a supplier bill'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed<void>(AppRoutes.purchaseBillCreate);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Symbols.person_add_rounded),
                    title: const Text('Supplier'),
                    subtitle: const Text('Add a supplier'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed<void>(AppRoutes.supplierAdd);
                    },
                  ),
                ],
              ),
            ),
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: const Icon(
                Symbols.add_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _item(
    PurchaseDestination destination,
    IconData icon,
    String route,
    String label,
  ) {
    final selected = current == destination;
    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: selected ? null : () => Get.offAllNamed<void>(route),
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
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
