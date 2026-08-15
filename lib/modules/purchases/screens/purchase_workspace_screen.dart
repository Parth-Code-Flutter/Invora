import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_purchase_navigation.dart';
import '../../../app/widgets/app_workspace_switch.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/purchase_repository.dart';

class PurchaseWorkspaceScreen extends StatelessWidget {
  const PurchaseWorkspaceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
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
        TextButton.icon(
          onPressed: () => showWorkspaceSwitcher(context),
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Purchases'),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7FC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Purchase overview',
                                style: AppTextStyles.sectionTitle,
                              ),
                              Text(
                                '${data.billCount} bills • ${data.supplierCount} suppliers',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Total purchases', style: AppTextStyles.caption),
                    Text(
                      _money(data.totalSpendMinor),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            'Paid',
                            data.paidMinor,
                            AppColors.success,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _Metric(
                            'Payable',
                            data.payableMinor,
                            AppColors.warning,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _Metric(
                            'Overdue',
                            data.overdueMinor,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Action(
                      icon: Icons.receipt_long_outlined,
                      title: 'Purchase bills',
                      subtitle: 'Record & track bills',
                      onTap: () =>
                          Get.offAllNamed<void>(AppRoutes.purchaseBills),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Action(
                      icon: Icons.storefront_outlined,
                      title: 'Suppliers',
                      subtitle: 'Manage vendors',
                      onTap: () => Get.offAllNamed<void>(AppRoutes.suppliers),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent purchase bills',
                      style: AppTextStyles.sectionTitle,
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
                    return AppCard(
                      onTap: () =>
                          Get.toNamed<void>(AppRoutes.purchaseBillCreate),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Record your first purchase bill',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: values
                        .map(
                          (bill) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              onTap: () => Get.toNamed<void>(
                                AppRoutes.purchaseBillDetails,
                                arguments: bill.id,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: bill.status == 'paid'
                                        ? const Color(0xFFE4F6F2)
                                        : AppColors.primaryLight,
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: bill.status == 'paid'
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.billNumber,
                                          style: AppTextStyles.listName,
                                        ),
                                        Text(
                                          bill.supplierName,
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _money(bill.totalMinor),
                                        style: AppTextStyles.listName,
                                      ),
                                      if (bill.balanceMinor > 0)
                                        Text(
                                          '${_money(bill.balanceMinor)} due',
                                          style: AppTextStyles.caption.copyWith(
                                            color: bill.status == 'overdue'
                                                ? AppColors.error
                                                : AppColors.warning,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
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

String _money(int minor) => CurrencyUtils.formatMinor(minor, symbol: '₹');

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 3),
        Text(
          _money(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.listName.copyWith(color: color),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.listName,
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption,
        ),
      ],
    ),
  );
}
