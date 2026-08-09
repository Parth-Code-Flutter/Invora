import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome', style: AppTextStyles.small),
              Text(controller.profile.value?.businessName ?? 'Invora'),
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
          if (ResponsiveUtils.isTablet(context))
            NavigationRail(
              selectedIndex: 0,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                final route = [
                  AppRoutes.dashboard,
                  AppRoutes.invoices,
                  AppRoutes.quotations,
                  AppRoutes.customers,
                  AppRoutes.products,
                  AppRoutes.reports,
                  AppRoutes.settings,
                ][index];
                if (index != 0) Get.toNamed<void>(route);
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: Text('Invoices'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  label: Text('Quotes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  label: Text('Customers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Items'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: Text('Settings'),
                ),
              ],
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ResponsiveContent(
                  paddingTop: 8,
                  child: Column(
                    children: [
                      Obx(() {
                        final report = controller.report.value;
                        final symbol =
                            controller.profile.value?.currencySymbol ?? '₹';
                        return AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This month',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 24,
                                runSpacing: 16,
                                children: [
                                  _Metric(
                                    label: 'Sales',
                                    value: CurrencyUtils.formatMinor(
                                      report.totalSalesMinor,
                                      symbol: symbol,
                                    ),
                                  ),
                                  _Metric(
                                    label: 'Received',
                                    value: CurrencyUtils.formatMinor(
                                      report.totalReceivedMinor,
                                      symbol: symbol,
                                    ),
                                  ),
                                  _Metric(
                                    label: 'Outstanding',
                                    value: CurrencyUtils.formatMinor(
                                      report.outstandingMinor,
                                      symbol: symbol,
                                    ),
                                  ),
                                  _Metric(
                                    label: 'Invoices',
                                    value: '${report.invoiceCount}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () =>
                                    Get.toNamed<void>(AppRoutes.reports),
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text('View reports'),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.recentInvoices.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final symbol =
                            controller.profile.value?.currencySymbol ?? '₹';
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent invoices',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              ...controller.recentInvoices.map(
                                (invoice) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(invoice.invoiceNumber),
                                  subtitle: Text(invoice.customerName),
                                  trailing: Text(
                                    CurrencyUtils.formatMinor(
                                      invoice.grandTotalMinor,
                                      symbol: symbol,
                                    ),
                                  ),
                                  onTap: () => Get.toNamed<void>(
                                    AppRoutes.invoiceDetails,
                                    arguments: invoice.id,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      AppCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.people_outline,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text('Customers'),
                          subtitle: const Text(
                            'Manage customer and billing details',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.toNamed<void>(AppRoutes.customers),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text('Create invoice'),
                          subtitle: const Text(
                            'Build and save an offline invoice',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.invoiceCreate),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.warningLight,
                            child: Icon(
                              Icons.list_alt_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          title: const Text('Invoices'),
                          subtitle: const Text(
                            'Search and manage saved invoices',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.toNamed<void>(AppRoutes.invoices),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondaryLight,
                            child: Icon(
                              Icons.request_quote_outlined,
                              color: AppColors.secondary,
                            ),
                          ),
                          title: const Text('Quotations'),
                          subtitle: const Text(
                            'Create and track customer quotations',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.toNamed<void>(AppRoutes.quotations),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondaryLight,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.secondary,
                            ),
                          ),
                          title: const Text('Products & services'),
                          subtitle: const Text('Manage reusable invoice items'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.toNamed<void>(AppRoutes.products),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 135,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.cardTitle),
      ],
    ),
  );
}
