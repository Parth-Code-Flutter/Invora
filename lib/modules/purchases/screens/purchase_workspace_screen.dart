import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
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
            return StreamBuilder<List<PurchaseBillSummary>>(
              stream: Get.find<PurchaseRepository>().watchBills(),
              builder: (context, billsSnapshot) {
                final bills = billsSnapshot.data;
                if (bills == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final active = bills
                    .where((bill) => bill.status != 'cancelled')
                    .toList();
                final open = active
                    .where((bill) => bill.balanceMinor > 0)
                    .toList();
                final overdue = active
                    .where((bill) => bill.status == 'overdue')
                    .toList();
                final recent = active.take(4).toList();
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
                    if (open.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PayablesPrompt(
                        overdueCount: overdue.length,
                        openCount: open.length,
                        amountMinor: overdue.isNotEmpty
                            ? data.overdueMinor
                            : data.payableMinor,
                        supplierName: (overdue.isNotEmpty ? overdue : open)
                            .first
                            .supplierName,
                        onTap: () =>
                            Get.offAllNamed<void>(AppRoutes.purchaseBills),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quick actions',
                            style: AppTextStyles.listName.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          'Keep purchases up to date',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PrimaryPurchaseAction(
                      onTap: () =>
                          Get.toNamed<void>(AppRoutes.purchaseBillCreate),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Supplier',
                          icon: Icons.storefront_outlined,
                          onTap: () =>
                              Get.offAllNamed<void>(AppRoutes.suppliers),
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
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent purchase bills',
                                style: AppTextStyles.listName.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                recent.isEmpty
                                    ? 'Your latest supplier activity'
                                    : '${recent.length} most recent',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Get.offAllNamed<void>(AppRoutes.purchaseBills),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (recent.isEmpty)
                      AppGroupedTile(
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
                      )
                    else
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        PurchaseBillRow(bill: recent[i], index: i),
                      ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PrimaryPurchaseAction extends StatelessWidget {
  const _PrimaryPurchaseAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 21),
              const SizedBox(width: 8),
              Text(
                'New bill',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PayablesPrompt extends StatelessWidget {
  const _PayablesPrompt({
    required this.overdueCount,
    required this.openCount,
    required this.amountMinor,
    required this.supplierName,
    required this.onTap,
  });

  final int overdueCount, openCount, amountMinor;
  final String supplierName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = overdueCount > 0;
    final color = overdue ? AppColors.error : AppColors.warning;
    final fill = overdue ? AppColors.errorLight : AppColors.warningLight;
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? color.withValues(alpha: .12)
          : fill.withValues(alpha: .55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: color.withValues(alpha: .22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  overdue
                      ? Icons.notification_important_outlined
                      : Icons.event_available_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overdue
                          ? '$overdueCount ${overdueCount == 1 ? 'bill' : 'bills'} overdue'
                          : '$openCount ${openCount == 1 ? 'bill' : 'bills'} to pay',
                      style: AppTextStyles.listName,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMoney(amountMinor),
                    style: AppTextStyles.listAmount.copyWith(color: color),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(int minor) {
    return CurrencyUtils.formatMinor(minor, symbol: '₹');
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
