import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/invoice_list_controller.dart';

class InvoiceListScreen extends GetView<InvoiceListController> {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          Obx(
            () => PopupMenuButton<InvoiceSort>(
              tooltip: 'Sort invoices',
              initialValue: controller.selectedSort.value,
              onSelected: controller.selectSort,
              icon: const Icon(Icons.sort_rounded),
              itemBuilder: (_) => const [
                PopupMenuItem(value: InvoiceSort.newest, child: Text('Newest')),
                PopupMenuItem(value: InvoiceSort.oldest, child: Text('Oldest')),
                PopupMenuItem(
                  value: InvoiceSort.highestAmount,
                  child: Text('Highest amount'),
                ),
                PopupMenuItem(
                  value: InvoiceSort.lowestAmount,
                  child: Text('Lowest amount'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed<void>(AppRoutes.invoiceCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create invoice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              8,
              ResponsiveUtils.horizontalPadding(context),
              10,
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: controller.updateSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search invoice, customer or company',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: Obx(
                    () => ListView(
                      scrollDirection: Axis.horizontal,
                      children: InvoiceListFilter.values
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_filterLabel(filter)),
                                selected:
                                    controller.selectedFilter.value == filter,
                                onSelected: (_) =>
                                    controller.selectFilter(filter),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.invoices.isEmpty) {
                final searching =
                    controller.searchQuery.value.isNotEmpty ||
                    controller.selectedFilter.value != InvoiceListFilter.all;
                return AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: searching ? 'No invoices found' : 'No invoices yet',
                  message: searching
                      ? 'Try a different search or status filter.'
                      : 'Create your first offline invoice to see it here.',
                  actionLabel: searching ? null : 'Create invoice',
                  onAction: searching
                      ? null
                      : () => Get.toNamed<void>(AppRoutes.invoiceCreate),
                );
              }
              final padding = ResponsiveUtils.horizontalPadding(context);
              final columns = ResponsiveUtils.gridColumns(
                context,
                tablet: 2,
                largeTablet: 3,
              );
              if (columns == 1) {
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(padding, 4, padding, 100),
                  itemCount: controller.invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _InvoiceCard(
                    invoice: controller.invoices[index],
                    symbol: controller.currencySymbol.value,
                  ),
                );
              }
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(padding, 4, padding, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 178,
                ),
                itemCount: controller.invoices.length,
                itemBuilder: (_, index) => _InvoiceCard(
                  invoice: controller.invoices[index],
                  symbol: controller.currencySymbol.value,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.symbol});
  final InvoiceSummaryModel invoice;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final status = invoice.effectiveStatus(DateTime.now());
    return AppCard(
      onTap: () =>
          Get.toNamed<void>(AppRoutes.invoiceDetails, arguments: invoice.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.invoiceNumber,
                  style: AppTextStyles.cardTitle,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(invoice.customerName, style: AppTextStyles.body),
          if (invoice.companyName?.isNotEmpty ?? false)
            Text(
              invoice.companyName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  _date(invoice.invoiceDate),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                CurrencyUtils.formatMinor(
                  invoice.grandTotalMinor,
                  symbol: symbol,
                ),
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      InvoiceStatus.paid => (AppColors.successLight, AppColors.success),
      InvoiceStatus.overdue ||
      InvoiceStatus.cancelled => (AppColors.errorLight, AppColors.error),
      InvoiceStatus.draft => (
        AppColors.surfaceVariant,
        AppColors.textSecondary,
      ),
      _ => (AppColors.warningLight, AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTextStyles.small.copyWith(color: foreground),
      ),
    );
  }
}

String _filterLabel(InvoiceListFilter filter) => switch (filter) {
  InvoiceListFilter.all => 'All',
  InvoiceListFilter.draft => 'Draft',
  InvoiceListFilter.unpaid => 'Unpaid',
  InvoiceListFilter.paid => 'Paid',
  InvoiceListFilter.overdue => 'Overdue',
};

String _statusLabel(InvoiceStatus status) => switch (status) {
  InvoiceStatus.partiallyPaid => 'Partially paid',
  _ => '${status.name[0].toUpperCase()}${status.name.substring(1)}',
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
