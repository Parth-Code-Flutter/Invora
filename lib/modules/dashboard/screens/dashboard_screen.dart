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
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_status_chip.dart';
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
                controller.profile.value?.businessName ?? 'Invora',
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
                final report = controller.report.value;
                if (report.invoiceCount == 0) return _zeroState(context);
                return ListView(
                  children: [
                    _receivedHero(context),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallMetric(
                            label: 'Outstanding',
                            value: CurrencyUtils.formatMinor(
                              report.outstandingMinor,
                              symbol: _symbol,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SmallMetric(
                            label: 'Invoices',
                            value: '${report.invoiceCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Create invoice',
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          Get.toNamed<void>(AppRoutes.invoiceCreate),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Quick actions', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Invoice',
                          icon: Icons.receipt_long_outlined,
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.invoiceCreate),
                        ),
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
                    ...controller.recentInvoices.map(
                      (invoice) => InkWell(
                        onTap: () => Get.toNamed<void>(
                          AppRoutes.invoiceDetails,
                          arguments: invoice.id,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: AppTextStyles.cardTitle,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      invoice.customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.secondaryBody,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyUtils.formatMinor(
                                      invoice.grandTotalMinor,
                                      symbol: _symbol,
                                    ),
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 4),
                                  AppStatusChip(
                                    status: invoice.effectiveStatus(
                                      DateTime.now(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _receivedHero(BuildContext context) {
    final received = controller.report.value.totalReceivedMinor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL RECEIVED',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyUtils.formatMinor(received, symbol: _symbol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displayAmount.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'This month',
            style: AppTextStyles.secondaryBody.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _zeroState(BuildContext context) => ListView(
    children: [
      const SizedBox(height: AppSpacing.xl),
      Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.receipt_long_outlined,
          size: 42,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Ready to create your first invoice?',
        textAlign: TextAlign.center,
        style: AppTextStyles.pageTitle,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Add a customer, choose an item and generate a professional PDF in a few steps.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        label: 'Create invoice',
        icon: Icons.add_rounded,
        onPressed: () => Get.toNamed<void>(AppRoutes.invoiceCreate),
      ),
      const SizedBox(height: AppSpacing.xs),
      TextButton.icon(
        onPressed: () => Get.toNamed<void>(AppRoutes.customerAdd),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add customer first'),
      ),
    ],
  );

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

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sectionTitle,
        ),
      ],
    ),
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
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    ),
  );
}
