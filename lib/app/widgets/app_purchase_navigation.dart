import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../utils/app_focus.dart';
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
          SizedBox(
            width: 68,
            height: 70,
            child: Semantics(
              button: true,
              label: 'Create purchase record',
              child: InkWell(
                onTap: () async {
                  await AppFocus.dismissKeyboard();
                  if (!context.mounted) return;
                  await showAppBottomSheet<void>(
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
                  );
                },
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
          onTap: selected
              ? null
              : () async {
                  await AppFocus.dismissKeyboard();
                  Get.offAllNamed<void>(route);
                },
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
}
