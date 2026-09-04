import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_form_grid.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../data/models/invoice_model.dart';
import '../../scan/barcode_capture_screen.dart';
import '../controllers/invoice_list_controller.dart';
import '../widgets/invoice_list_overview.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    this.quotation = false,
    this.embedded = false,
    this.belowTitle,
    super.key,
  });
  final bool quotation;
  final bool embedded;
  final Widget? belowTitle;

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
    final searchBar = AppSearchAppBar(
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
      primary: !widget.embedded,
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
    );
    final body = Column(
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
                height: 44,
                child: Obx(() {
                  final filters = quotation
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
                          InvoiceListFilter.overdue,
                          InvoiceListFilter.unpaid,
                          InvoiceListFilter.draft,
                          InvoiceListFilter.paid,
                        ];
                  final summaries = controller.summaryInvoices.toList();
                  return Stack(
                    children: [
                      ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 24),
                        itemCount: filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          if (quotation) {
                            return AppFilterChip(
                              label: _filterLabel(filter),
                              selected:
                                  controller.selectedFilter.value == filter,
                              onSelected: (_) =>
                                  controller.selectFilter(filter),
                            );
                          }
                          return _InvoiceStatusFilterChip(
                            filter: filter,
                            count: _invoiceFilterCount(filter, summaries),
                            selected: controller.selectedFilter.value == filter,
                            onSelected: () => controller.selectFilter(filter),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IgnorePointer(
                          child: Container(
                            width: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkBackground
                                          : AppColors.background)
                                      .withValues(alpha: 0),
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkBackground
                                      : AppColors.background,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
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
                illustration: searching
                    ? AppEmptyIllustration.search
                    : quotation
                    ? AppEmptyIllustration.clipboard
                    : AppEmptyIllustration.invoice,
                title: searching
                    ? (quotation ? 'No quotations found' : 'No invoices found')
                    : (quotation ? 'No quotations yet' : 'No invoices yet'),
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
            final columns = ResponsiveUtils.gridColumns(context);
            if (columns == 1) {
              return ListView.builder(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(padding, 2, padding, 90),
                itemCount: entries.length,
                itemBuilder: (_, index) => _invoiceListTile(
                  context,
                  entries[index],
                  index,
                  controller.currencySymbol.value,
                ),
              );
            }
            return ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(padding, 2, padding, 90),
              children: _tabletInvoiceSections(
                context,
                entries,
                controller.currencySymbol.value,
              ),
            );
          }),
        ),
      ],
    );
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: searchBar.preferredSize.height, child: searchBar),
          if (widget.belowTitle != null) widget.belowTitle!,
          Expanded(child: body),
        ],
      );
    }
    return AppShell(
      destination: quotation ? null : MainDestination.documents,
      floatingActionButton: quotation
          ? FloatingActionButton(
              tooltip: l10n('Create quotation'),
              onPressed: () => Get.toNamed<void>(AppRoutes.quotationCreate),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      appBar: searchBar,
      body: body,
    );
  }
}

Widget _invoiceListTile(
  BuildContext context,
  _InvoiceListEntry entry,
  int index,
  String currencySymbol,
) {
  if (entry.header != null) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, index == 0 ? 4 : 18, 4, 8),
      child: Text.rich(
        TextSpan(
          text: entry.header!,
          children: [
            TextSpan(
              text: ' (${entry.count})',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
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
          currencySymbol: currencySymbol,
          onTap: () => Get.toNamed<void>(
            AppRoutes.invoiceDetails,
            arguments: invoice.id,
          ),
        ),
      ),
    ),
  );
}

List<Widget> _tabletInvoiceSections(
  BuildContext context,
  List<_InvoiceListEntry> entries,
  String currencySymbol,
) {
  final sections = <Widget>[];
  var cards = <_InvoiceListEntry>[];
  var index = 0;

  void flushCards() {
    if (cards.isEmpty) return;
    final batch = List<_InvoiceListEntry>.from(cards);
    final start = index - batch.length;
    sections.add(
      AppResponsiveCards(
        itemCount: batch.length,
        itemBuilder: (context, i) =>
            _invoiceListTile(context, batch[i], start + i, currencySymbol),
      ),
    );
    cards = [];
  }

  for (final entry in entries) {
    if (entry.header != null) {
      flushCards();
      sections.add(_invoiceListTile(context, entry, index, currencySymbol));
    } else {
      cards.add(entry);
    }
    index++;
  }
  flushCards();
  return sections;
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({required this.icon, this.showIndicator = false});

  final IconData icon;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
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

int _invoiceFilterCount(
  InvoiceListFilter filter,
  List<InvoiceSummaryModel> invoices,
) {
  if (filter == InvoiceListFilter.all) return invoices.length;
  final now = DateTime.now();
  return invoices.where((invoice) {
    final status = invoice.effectiveStatus(now);
    return switch (filter) {
      InvoiceListFilter.draft => status == InvoiceStatus.draft,
      InvoiceListFilter.unpaid =>
        status == InvoiceStatus.unpaid || status == InvoiceStatus.partiallyPaid,
      InvoiceListFilter.paid => status == InvoiceStatus.paid,
      InvoiceListFilter.overdue => status == InvoiceStatus.overdue,
      _ => false,
    };
  }).length;
}

class _InvoiceStatusFilterChip extends StatelessWidget {
  const _InvoiceStatusFilterChip({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final InvoiceListFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = switch (filter) {
      InvoiceListFilter.overdue => AppColors.error,
      InvoiceListFilter.unpaid => AppColors.warning,
      InvoiceListFilter.paid => AppColors.success,
      _ => AppColors.secondary,
    };
    final quietTone = switch (filter) {
      InvoiceListFilter.overdue => AppColors.errorLight,
      InvoiceListFilter.unpaid => AppColors.warningLight,
      InvoiceListFilter.paid => AppColors.successLight,
      _ => AppColors.secondaryLight,
    };
    final label = _filterLabel(filter);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count ${count == 1 ? 'invoice' : 'invoices'}',
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        label: Text('$label  $count'),
        labelStyle: AppTextStyles.caption.copyWith(
          color: selected
              ? Colors.white
              : count == 0
              ? (isDark ? AppColors.darkTextSecondary : AppColors.textTertiary)
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : count == 0
            ? AppColors.surfaceSoft
            : quietTone.withValues(alpha: .55),
        selectedColor: tone,
        side: BorderSide(
          color: selected
              ? tone
              : count == 0
              ? (isDark ? AppColors.darkBorder : AppColors.border)
              : tone.withValues(alpha: .25),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    );
  }
}

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
