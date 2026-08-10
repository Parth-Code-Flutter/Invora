import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ResponsiveUtils.isTablet(context)
          ? null
          : const AppMainNavigation(current: MainDestination.home),
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: AppTextStyles.caption),
              Text(
                controller.profile.value?.businessName ?? 'Creovo Invoice',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Get.toNamed<void>(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          if (ResponsiveUtils.isTablet(context)) _navigationRail(),
          Expanded(
            child: ResponsiveContent(
              tabletMaxWidth: 840,
              paddingTop: AppSpacing.xs,
              child: Obx(() {
                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    _businessOverview(context),
                    if (controller.report.value.outstandingMinor > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _OutstandingPrompt(
                        amount: controller.report.value.outstandingMinor,
                        symbol: _symbol,
                        onTap: () => Get.toNamed<void>(AppRoutes.invoices),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create quickly',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Get.toNamed<void>(AppRoutes.reports),
                          icon: const Icon(Icons.insights_rounded, size: 18),
                          label: const Text('Reports'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Create invoice',
                            icon: Icons.add_rounded,
                            onPressed: () =>
                                Get.toNamed<void>(AppRoutes.invoiceCreate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Estimate',
                          icon: Icons.request_quote_outlined,
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.quotationCreate),
                        ),
                        _QuickAction(
                          label: 'Customer',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.customerAdd),
                        ),
                        _QuickAction(
                          label: 'Product',
                          icon: Icons.add_box_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.productAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent invoices',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed<void>(AppRoutes.invoices),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    if (controller.recentInvoices.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No invoices yet',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Your latest invoices will appear here.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...controller.recentInvoices.map(
                      (invoice) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppInvoiceSummaryCard(
                          invoice: invoice,
                          currencySymbol: _symbol,
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.invoiceDetails,
                            arguments: invoice.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String get _symbol => controller.profile.value?.currencySymbol ?? '₹';

  Widget _businessOverview(BuildContext context) {
    final report = controller.report.value;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24151827),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'CASH FLOW · THIS MONTH',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${report.invoiceCount} invoices',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Invoiced this month',
                style: AppTextStyles.secondaryBody.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                CurrencyUtils.formatMinor(
                  report.totalSalesMinor,
                  symbol: _symbol,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displayAmount.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: report.totalSalesMinor <= 0
                      ? 0
                      : (report.totalReceivedMinor / report.totalSalesMinor)
                            .clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: .13),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF61D7B4)),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _OverviewValue(
                      label: 'Received',
                      value: CurrencyUtils.formatMinor(
                        report.totalReceivedMinor,
                        symbol: _symbol,
                      ),
                      color: const Color(0xFF61D7B4),
                    ),
                  ),
                  Container(width: 1, height: 38, color: Colors.white12),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _OverviewValue(
                      label: 'Outstanding',
                      value: CurrencyUtils.formatMinor(
                        report.outstandingMinor,
                        symbol: _symbol,
                      ),
                      color: const Color(0xFFFFC878),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -34,
          top: -42,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
        ),
      ],
    );
  }

  NavigationRail _navigationRail() => NavigationRail(
    selectedIndex: 0,
    labelType: NavigationRailLabelType.all,
    onDestinationSelected: (index) {
      final route = [
        AppRoutes.dashboard,
        AppRoutes.invoices,
        AppRoutes.customers,
        AppRoutes.more,
      ][index];
      if (index != 0) Get.offAllNamed<void>(route);
    },
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: Text('Invoices'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        label: Text('Customers'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.grid_view_outlined),
        label: Text('More'),
      ),
    ],
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white54)),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardTitle.copyWith(color: color),
      ),
    ],
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 7),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OutstandingPrompt extends StatelessWidget {
  const _OutstandingPrompt({
    required this.amount,
    required this.symbol,
    required this.onTap,
  });

  final int amount;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF4E4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(color: AppColors.warning.withValues(alpha: .22)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.schedule_send_outlined,
                color: AppColors.warning,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Follow up on payments', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyUtils.formatMinor(amount, symbol: symbol)} is still waiting to be collected',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.warning),
          ],
        ),
      ),
    ),
  );
}
