import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../data/models/invoice_model.dart';
import '../../scan/barcode_capture_screen.dart';
import '../controllers/invoice_list_controller.dart';
import '../widgets/invoice_list_overview.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({this.quotation = false, super.key});
  final bool quotation;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  InvoiceListController get controller => Get.find<InvoiceListController>(
    tag: widget.quotation ? InvoiceListController.quotationTag : null,
  );
  bool get quotation => widget.quotation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller.isClosed) return;
      final filter = Get.arguments;
      if (filter is InvoiceListFilter) {
        if (controller.selectedFilter.value == filter) {
          controller.refreshInvoices();
        } else {
          controller.selectFilter(filter);
        }
      } else {
        controller.refreshInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppMainNavigation(
        current: quotation ? MainDestination.more : MainDestination.invoices,
      ),
      appBar: AppSearchAppBar(
        leading: quotation ? const AppBackButton() : null,
        title: quotation ? 'Quotations' : 'Invoices',
        titleSuffix: Obx(
          () => Text(
            '(${controller.summaryInvoices.length})',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        hint: quotation ? 'Quote or customer' : 'Invoice or customer',
        onChanged: controller.updateSearch,
        onScan: BarcodeCaptureScreen.captureQuery,
        actions: [
          Obx(
            () => PopupMenuButton<InvoiceSort>(
              tooltip: l10n('Sort invoices'),
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
                if (!quotation) ...[
                  Obx(
                    () => InvoiceListOverview(
                      invoices: controller.summaryInvoices.toList(),
                      currencySymbol: controller.currencySymbol.value,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                                  child: AppFilterChip(
                                    label: _filterLabel(filter),
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
                return const AppListSkeleton();
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
              final entries = _invoiceListEntries(
                controller.invoices.toList(),
                controller.selectedSort.value,
                DateTime.now(),
              );
              return ListView.builder(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(padding, 2, padding, 90),
                itemCount: entries.length,
                itemBuilder: (_, index) {
                  final entry = entries[index];
                  if (entry.header != null) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        4,
                        index == 0 ? 4 : 18,
                        4,
                        8,
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: entry.header!,
                          children: [
                            TextSpan(
                              text: ' (${entry.count})',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          style: AppTextStyles.caption.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    );
                  }
                  final invoice = entry.invoice!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppListEntrance(
                      index: index,
                      child: AppScrollMotion(
                        key: ValueKey('invoice-scroll-${invoice.id}'),
                        child: AppInvoiceSummaryCard(
                          invoice: invoice,
                          currencySymbol: controller.currencySymbol.value,
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.invoiceDetails,
                            arguments: invoice.id,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

class _InvoiceListEntry {
  const _InvoiceListEntry.header(this.header, this.count) : invoice = null;
  const _InvoiceListEntry.row(this.invoice) : header = null, count = 0;

  final String? header;
  final int count;
  final InvoiceSummaryModel? invoice;
}

List<_InvoiceListEntry> _invoiceListEntries(
  List<InvoiceSummaryModel> invoices,
  InvoiceSort sort,
  DateTime now,
) {
  if (invoices.isEmpty) return const [];
  if (sort == InvoiceSort.highestAmount || sort == InvoiceSort.lowestAmount) {
    return _groupedRows(invoices);
  }
  final groups = <String, List<InvoiceSummaryModel>>{};
  for (final invoice in invoices) {
    final key = '${invoice.invoiceDate.year}-${invoice.invoiceDate.month}';
    (groups[key] ??= []).add(invoice);
  }
  return [
    for (final group in groups.values) ...[
      _InvoiceListEntry.header(
        _monthLabel(group.first.invoiceDate, now),
        group.length,
      ),
      ..._groupedRows(group),
    ],
  ];
}

List<_InvoiceListEntry> _groupedRows(List<InvoiceSummaryModel> invoices) {
  return [for (final invoice in invoices) _InvoiceListEntry.row(invoice)];
}

String _monthLabel(DateTime value, DateTime now) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final lastMonth = DateTime(now.year, now.month - 1);
  if (value.year == now.year && value.month == now.month) {
    return 'This month';
  }
  if (value.year == lastMonth.year && value.month == lastMonth.month) {
    return 'Last month';
  }
  return '${months[value.month - 1]} ${value.year}';
}
