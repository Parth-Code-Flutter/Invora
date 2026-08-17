import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_card.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchases'),
            Text(
              'Bills & payables',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n('Switch workspace'),
            onPressed: () => showWorkspaceSwitcher(context),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppPurchaseNavigation(
        current: PurchaseDestination.home,
      ),
      body: ResponsiveContent(
        tabletMaxWidth: 800,
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
                AppCard(
                  color: isDark
                      ? const Color(0xFF3B2038)
                      : const Color(0xFFFCFAFF),
                  borderColor: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE9DFF0),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Purchase overview',
                              style: AppTextStyles.listName,
                            ),
                          ),
                          Text(
                            '${data.billCount} ${data.billCount == 1 ? 'bill' : 'bills'} · ${data.supplierCount} ${data.supplierCount == 1 ? 'supplier' : 'suppliers'}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _OverviewMetric(
                              label: 'Paid',
                              amountMinor: data.paidMinor,
                              color: AppColors.success,
                            ),
                          ),
                          const _OverviewDivider(),
                          Expanded(
                            child: _OverviewMetric(
                              label: 'Payable',
                              amountMinor: data.payableMinor,
                              color: AppColors.warning,
                            ),
                          ),
                          const _OverviewDivider(),
                          Expanded(
                            child: _OverviewMetric(
                              label: 'Overdue',
                              amountMinor: data.overdueMinor,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (data.overdueMinor > 0) ...[
                  const SizedBox(height: 10),
                  AppCard(
                    onTap: () => Get.offAllNamed<void>(AppRoutes.purchaseBills),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overdue payables',
                                style: AppTextStyles.listName,
                              ),
                              Text(
                                'Open bills to see what needs paying.',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppAmountText(
                          amountMinor: data.overdueMinor,
                          symbol: '₹',
                          color: AppColors.error,
                          style: AppTextStyles.listAmount.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      onTap: () => Get.toNamed<void>(AppRoutes.supplierAdd),
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
                          PurchaseBillRow(bill: values[i]),
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

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.amountMinor,
    required this.color,
  });
  final String label;
  final int amountMinor;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        AppAmountText(
          amountMinor: amountMinor,
          symbol: '₹',
          color: color,
          textAlign: TextAlign.start,
          style: AppTextStyles.listAmount.copyWith(fontSize: 13, color: color),
        ),
      ],
    ),
  );
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border,
  );
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(height: 5),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    ),
  );
}
