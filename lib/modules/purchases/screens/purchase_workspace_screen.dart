import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_purchase_navigation.dart';
import '../../../app/widgets/app_workspace_switch.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/purchase_repository.dart';
import 'purchase_screens.dart';

class PurchaseWorkspaceScreen extends StatelessWidget {
  const PurchaseWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle('Purchases', subtitle: 'Bills & payables'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Switch workspace'),
            onPressed: () => showWorkspaceSwitcher(context),
            icon: Icons.swap_horiz_rounded,
          ),
        ],
      ),
      bottomNavigationBar: const AppPurchaseNavigation(
        current: PurchaseDestination.home,
      ),
      body: ResponsiveContent(
        tabletMaxWidth: 800,
        paddingTop: AppSpacing.xs,
        child: StreamBuilder<PurchaseDashboardSummary>(
          stream: Get.find<PurchaseRepository>().watchDashboard(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                PurchaseOverviewCard(
                  data: data,
                  onPayableTap: () =>
                      Get.offAllNamed<void>(AppRoutes.purchaseBills),
                  onOverdueTap: data.overdueMinor > 0
                      ? () => Get.offAllNamed<void>(AppRoutes.purchaseBills)
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _QuickAction(
                      label: 'New bill',
                      icon: Icons.receipt_long_outlined,
                      onTap: () =>
                          Get.toNamed<void>(AppRoutes.purchaseBillCreate),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      label: 'Supplier',
                      icon: Icons.storefront_outlined,
                      onTap: () => Get.offAllNamed<void>(AppRoutes.suppliers),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      label: 'All bills',
                      icon: Icons.receipt_long_rounded,
                      onTap: () =>
                          Get.offAllNamed<void>(AppRoutes.purchaseBills),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent purchase bills',
                        style: AppTextStyles.listName.copyWith(fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Get.offAllNamed<void>(AppRoutes.purchaseBills),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                StreamBuilder<List<PurchaseBillSummary>>(
                  stream: Get.find<PurchaseRepository>().watchBills(),
                  builder: (_, bills) {
                    final values = (bills.data ?? []).take(4).toList();
                    if (values.isEmpty) {
                      return AppGroupedTile(
                        onTap: () =>
                            Get.toNamed<void>(AppRoutes.purchaseBillCreate),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Record your first purchase bill',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.listName,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < values.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          PurchaseBillRow(bill: values[i], index: i),
                        ],
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
