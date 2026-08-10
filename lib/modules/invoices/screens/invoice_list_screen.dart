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
import '../../../app/widgets/app_search_field.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_module_banner.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/invoice_list_controller.dart';

class InvoiceListScreen extends GetView<InvoiceListController> {
  const InvoiceListScreen({this.quotation = false, super.key});
  final bool quotation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppMainNavigation(
        current: quotation ? MainDestination.more : MainDestination.invoices,
      ),
      appBar: AppBar(
        title: Text(quotation ? 'Quotations' : 'Invoices'),
        actions: [
          Obx(
            () => PopupMenuButton<InvoiceSort>(
              tooltip: 'Sort invoices',
              initialValue: controller.selectedSort.value,
              onSelected: controller.selectSort,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (_) => InvoiceSort.values
                  .map(
                    (sort) => PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: controller.selectedSort.value == sort
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 19,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(_sortLabel(sort)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: _HeaderActionIcon(
                icon: Icons.swap_vert_rounded,
                showIndicator:
                    controller.selectedSort.value != InvoiceSort.newest,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.horizontalPadding(context)),
        ],
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
                AppModuleBanner(
                  title: quotation
                      ? 'Plan the next win'
                      : 'Your money timeline',
                  subtitle: quotation
                      ? 'Create, send and turn accepted work into an invoice.'
                      : 'Create quickly and see what is paid or still due.',
                  icon: quotation
                      ? Icons.request_quote_outlined
                      : Icons.receipt_long_outlined,
                  colors: quotation
                      ? const [AppColors.accent, AppColors.secondary]
                      : const [AppColors.secondary, AppColors.primary],
                  actionLabel: quotation ? 'New quote' : 'New invoice',
                  onAction: () => Get.toNamed<void>(
                    quotation
                        ? AppRoutes.quotationCreate
                        : AppRoutes.invoiceCreate,
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 8),
                Obx(
                  () => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${controller.invoices.length} ${quotation ? 'estimates' : 'invoices'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(padding, 4, padding, 100),
                itemCount: controller.invoices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
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

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({required this.icon, this.showIndicator = false});

  final IconData icon;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 23, color: Theme.of(context).colorScheme.onSurface),
          if (showIndicator)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceSoft,
                    width: 1.5,
                  ),
                ),
              ),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: .11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: _statusColor(status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.customerName.isEmpty
                      ? 'Customer not selected'
                      : invoice.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  '${invoice.invoiceNumber} • ${_date(invoice.invoiceDate)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatMinor(
                  invoice.grandTotalMinor,
                  symbol: symbol,
                ),
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 6),
              AppStatusChip(status: status),
              if (invoice.balanceMinor > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${CurrencyUtils.formatMinor(invoice.balanceMinor, symbol: symbol)} due',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(InvoiceStatus status) => switch (status) {
  InvoiceStatus.paid || InvoiceStatus.accepted => AppColors.success,
  InvoiceStatus.overdue ||
  InvoiceStatus.cancelled ||
  InvoiceStatus.rejected => AppColors.error,
  InvoiceStatus.partiallyPaid ||
  InvoiceStatus.unpaid ||
  InvoiceStatus.expired => AppColors.warning,
  _ => AppColors.primary,
};

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

String _sortLabel(InvoiceSort sort) => switch (sort) {
  InvoiceSort.newest => 'Newest first',
  InvoiceSort.oldest => 'Oldest first',
  InvoiceSort.highestAmount => 'Highest amount',
  InvoiceSort.lowestAmount => 'Lowest amount',
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
