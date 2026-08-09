import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_search_field.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/invoice_list_controller.dart';

class InvoiceListScreen extends GetView<InvoiceListController> {
  const InvoiceListScreen({this.quotation = false, super.key});
  final bool quotation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quotation ? 'Quotations' : 'Invoices'),
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
        onPressed: () => Get.toNamed<void>(
          quotation ? AppRoutes.quotationCreate : AppRoutes.invoiceCreate,
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(quotation ? 'Create quotation' : 'Create invoice'),
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
                AppSearchField(
                  onChanged: controller.updateSearch,
                  hint: 'Search invoice, customer or company',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: Obx(
                    () => ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          (quotation
                                  ? const [
                                      InvoiceListFilter.all,
                                      InvoiceListFilter.draft,
                                      InvoiceListFilter.sent,
                                      InvoiceListFilter.accepted,
                                      InvoiceListFilter.rejected,
                                      InvoiceListFilter.expired,
                                    ]
                                  : const [
                                      InvoiceListFilter.all,
                                      InvoiceListFilter.draft,
                                      InvoiceListFilter.unpaid,
                                      InvoiceListFilter.paid,
                                      InvoiceListFilter.overdue,
                                    ])
                              .map(
                                (filter) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(_filterLabel(filter)),
                                    selected:
                                        controller.selectedFilter.value ==
                                        filter,
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
                      : 'Create your first offline ${quotation ? 'quotation' : 'invoice'} to see it here.',
                  actionLabel: searching
                      ? null
                      : quotation
                      ? 'Create quotation'
                      : 'Create invoice',
                  onAction: searching
                      ? null
                      : () => Get.toNamed<void>(
                          quotation
                              ? AppRoutes.quotationCreate
                              : AppRoutes.invoiceCreate,
                        ),
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
              AppStatusChip(status: status),
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

String _filterLabel(InvoiceListFilter filter) => switch (filter) {
  InvoiceListFilter.all => 'All',
  InvoiceListFilter.draft => 'Draft',
  InvoiceListFilter.unpaid => 'Unpaid',
  InvoiceListFilter.paid => 'Paid',
  InvoiceListFilter.overdue => 'Overdue',
  InvoiceListFilter.sent => 'Sent',
  InvoiceListFilter.accepted => 'Accepted',
  InvoiceListFilter.rejected => 'Rejected',
  InvoiceListFilter.expired => 'Expired',
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
