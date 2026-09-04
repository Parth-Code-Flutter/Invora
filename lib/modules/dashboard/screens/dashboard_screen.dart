import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/report_summary_model.dart';
import '../../reports/widgets/report_charts.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destination: MainDestination.home,
      appBar: AppBar(
        title: Obx(
          () => Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _businessInitial,
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: AppTextStyles.caption),
                    Text(
                      controller.profile.value?.businessName ??
                          'Creovo Billing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.horizontalPadding(context),
          AppSpacing.xs,
          ResponsiveUtils.horizontalPadding(context),
          0,
        ),
        child: Obx(() {
          final overdue = controller.overdueInvoices();
          final dueSoon = controller.dueSoonInvoices();
          final followUp = controller.followUpInvoices();
          final showFollowUp = followUp.isNotEmpty;
          if (ResponsiveUtils.isTablet(context)) {
            return _TabletDashboardHome(
              controller: controller,
              overdue: overdue,
              dueSoon: dueSoon,
              followUp: followUp,
              showFollowUp: showFollowUp,
              symbol: _symbol,
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: controller.reportLoading.value
                    ? const _DashboardOverviewLoadingCard()
                    : DashboardOverviewCard(
                        report: controller.report.value,
                        symbol: _symbol,
                        onOutstandingTap: () => controller.openInvoiceList(
                          InvoiceListFilter.unpaid,
                        ),
                      ),
              ),
              if (!controller.recentLoading.value &&
                  (overdue.isNotEmpty || dueSoon.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.sm),
                _CollectCard(
                  overdue: overdue,
                  dueSoon: dueSoon,
                  symbol: _symbol,
                  onOverdue: () =>
                      controller.openInvoiceList(InvoiceListFilter.overdue),
                  onDueSoon: () =>
                      controller.openInvoiceList(InvoiceListFilter.unpaid),
                  onViewAll: () => controller.openInvoiceList(
                    overdue.isNotEmpty
                        ? InvoiceListFilter.overdue
                        : InvoiceListFilter.unpaid,
                  ),
                ),
              ],
              if (!controller.purchaseLoading.value &&
                  controller.hasPayables) ...[
                const SizedBox(height: AppSpacing.sm),
                _PayCard(
                  payableMinor: controller.purchase.value.payableMinor,
                  overdueMinor: controller.purchase.value.overdueMinor,
                  symbol: _symbol,
                  onOverdue: () =>
                      controller.openPurchaseBills(billFilter: 'overdue'),
                  onPayable: () =>
                      controller.openPurchaseBills(billFilter: 'unpaid'),
                ),
              ],
              if (!controller.reportLoading.value &&
                  controller.backupDue.value) ...[
                const SizedBox(height: AppSpacing.sm),
                _BackupReminderPrompt(
                  onTap: () async {
                    await Get.toNamed<void>(AppRoutes.backup);
                    controller.refreshBackupStatus();
                  },
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  String get _symbol => controller.profile.value?.currencySymbol ?? '₹';

  String get _businessInitial {
    final name = controller.profile.value?.businessName.trim() ?? '';
    return name.isEmpty ? 'C' : name.characters.first.toUpperCase();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _TabletDashboardHome extends StatelessWidget {
  const _TabletDashboardHome({
    required this.controller,
    required this.overdue,
    required this.dueSoon,
    required this.followUp,
    required this.showFollowUp,
    required this.symbol,
  });

  final DashboardController controller;
  final List<InvoiceSummaryModel> overdue;
  final List<InvoiceSummaryModel> dueSoon;
  final List<InvoiceSummaryModel> followUp;
  final bool showFollowUp;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final invoices = showFollowUp ? followUp : controller.recentInvoices;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl, right: 10),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: controller.reportLoading.value
                    ? const _DashboardOverviewLoadingCard()
                    : DashboardOverviewCard(
                        report: controller.report.value,
                        symbol: symbol,
                        onOutstandingTap: () => controller.openInvoiceList(
                          InvoiceListFilter.unpaid,
                        ),
                      ),
              ),
              if (!controller.recentLoading.value &&
                  (overdue.isNotEmpty || dueSoon.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.sm),
                _CollectCard(
                  overdue: overdue,
                  dueSoon: dueSoon,
                  symbol: symbol,
                  onOverdue: () =>
                      controller.openInvoiceList(InvoiceListFilter.overdue),
                  onDueSoon: () =>
                      controller.openInvoiceList(InvoiceListFilter.unpaid),
                  onViewAll: () => controller.openInvoiceList(
                    overdue.isNotEmpty
                        ? InvoiceListFilter.overdue
                        : InvoiceListFilter.unpaid,
                  ),
                ),
              ],
              if (!controller.purchaseLoading.value &&
                  controller.hasPayables) ...[
                const SizedBox(height: AppSpacing.sm),
                _PayCard(
                  payableMinor: controller.purchase.value.payableMinor,
                  overdueMinor: controller.purchase.value.overdueMinor,
                  symbol: symbol,
                  onOverdue: () =>
                      controller.openPurchaseBills(billFilter: 'overdue'),
                  onPayable: () =>
                      controller.openPurchaseBills(billFilter: 'unpaid'),
                ),
              ],
              if (!controller.reportLoading.value &&
                  controller.backupDue.value) ...[
                const SizedBox(height: AppSpacing.sm),
                _BackupReminderPrompt(
                  onTap: () async {
                    await Get.toNamed<void>(AppRoutes.backup);
                    controller.refreshBackupStatus();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg, left: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.border,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(
                      title: showFollowUp
                          ? 'Needs follow-up'
                          : 'Recent invoices',
                      subtitle: controller.recentLoading.value
                          ? 'Loading billing activity'
                          : showFollowUp
                          ? '${followUp.length} ${followUp.length == 1 ? 'invoice' : 'invoices'} to collect'
                          : controller.recentInvoices.isEmpty
                          ? 'Latest billing activity'
                          : '${controller.recentInvoices.length} most recent',
                      actionLabel: 'View all',
                      onAction: () => controller.openInvoiceList(
                        overdue.isNotEmpty
                            ? InvoiceListFilter.overdue
                            : showFollowUp
                            ? InvoiceListFilter.unpaid
                            : InvoiceListFilter.all,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _recentPane(invoices)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentPane(List<InvoiceSummaryModel> invoices) {
    if (controller.recentLoading.value) {
      return const _RecentInvoicesLoading();
    }
    if (!showFollowUp && controller.recentInvoices.isEmpty) {
      return const AppEmptyState(
        illustration: AppEmptyIllustration.invoice,
        title: 'No invoices yet',
        message: 'Create an invoice to see activity here.',
        compact: true,
      );
    }
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => AppInvoiceSummaryCard(
        invoice: invoices[i],
        currencySymbol: symbol,
        onTap: () => Get.toNamed<void>(
          AppRoutes.invoiceDetails,
          arguments: invoices[i].id,
        ),
      ),
    );
  }
}

class DashboardOverviewCard extends StatelessWidget {
  const DashboardOverviewCard({
    required this.report,
    required this.symbol,
    this.onOutstandingTap,
    this.month,
    super.key,
  });

  final ReportSummaryModel report;
  final String symbol;
  final VoidCallback? onOutstandingTap;
  final DateTime? month;

  @override
  Widget build(BuildContext context) {
    final period = month ?? DateTime.now();
    final change = report.salesChangePercent.round();
    final trendLabel = !report.hasPreviousSales
        ? (report.totalSalesMinor > 0 ? 'New vs last period' : null)
        : '${change >= 0 ? '+' : ''}$change% from last period';
    final outstandingTap = report.outstandingMinor > 0
        ? onOutstandingTap
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportCollectionCard(
          salesMinor: report.totalSalesMinor,
          receivedMinor: report.totalReceivedMinor,
          outstandingMinor: report.outstandingMinor,
          symbol: symbol,
          periodLabel: _monthYear(period),
          trendLabel: trendLabel,
          trendUp: change >= 0,
          onOutstanding: outstandingTap,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ReportKpiTile(
                label: 'Received',
                amountMinor: report.totalReceivedMinor,
                symbol: symbol,
                color: AppColors.success,
                deltaLabel: _receivedDeltaLabel(report),
                deltaUp:
                    report.totalReceivedMinor >= report.previousReceivedMinor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReportKpiTile(
                label: 'Outstanding',
                amountMinor: report.outstandingMinor,
                symbol: symbol,
                color: AppColors.warning,
                deltaLabel: report.outstandingMinor > 0
                    ? '${((report.collectionRate) * 100).round()}% collected'
                    : 'All collected',
                deltaUp: true,
                onTap: outstandingTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _HomeJumpStrip(),
      ],
    );
  }
}

String _monthYear(DateTime value) {
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
  return '${months[value.month - 1]} ${value.year}';
}

String _receivedDeltaLabel(ReportSummaryModel report) {
  final previous = report.previousReceivedMinor;
  final current = report.totalReceivedMinor;
  if (previous <= 0) {
    return current > 0 ? 'New vs last period' : 'From last period';
  }
  final percent = ((current - previous) / previous * 100).round();
  return '${percent >= 0 ? '+' : ''}$percent% from last period';
}

class _DashboardOverviewLoadingCard extends StatelessWidget {
  const _DashboardOverviewLoadingCard();

  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey('dashboard-overview-loading'),
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3B2038)
        : const Color(0xFFFCFAFF),
    padding: const EdgeInsets.all(14),
    child: const SizedBox(
      height: 188,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    ),
  );
}

class _RecentInvoicesLoading extends StatelessWidget {
  const _RecentInvoicesLoading();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('dashboard-recent-loading'),
    children: List.generate(
      2,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index == 0 ? 10 : 0),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: const SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.listName.copyWith(fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.small),
          ],
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _HomeJumpStrip extends StatelessWidget {
  const _HomeJumpStrip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF472440) : const Color(0xFFFFF6F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              _JumpAction(
                label: 'Products',
                icon: Icons.inventory_2_outlined,
                tint: AppColors.accent,
                onTap: () => Get.offAllNamed<void>(AppRoutes.products),
              ),
              _JumpAction(
                label: 'Estimates',
                icon: Icons.request_quote_outlined,
                tint: AppColors.primary,
                onTap: () => Get.toNamed<void>(AppRoutes.quotations),
              ),
              _JumpAction(
                label: 'Expenses',
                icon: Icons.payments_outlined,
                tint: AppColors.warning,
                onTap: () => Get.toNamed<void>(AppRoutes.expenses),
              ),
              _JumpAction(
                label: 'Reports',
                icon: Icons.insert_chart_outlined_rounded,
                tint: AppColors.secondary,
                onTap: () => Get.toNamed<void>(AppRoutes.reports),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JumpAction extends StatelessWidget {
  const _JumpAction({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.payableMinor,
    required this.overdueMinor,
    required this.symbol,
    required this.onOverdue,
    required this.onPayable,
  });

  final int payableMinor;
  final int overdueMinor;
  final String symbol;
  final VoidCallback onOverdue;
  final VoidCallback onPayable;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overdue = overdueMinor > 0;
    return AppCard(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF3B2038) : Colors.white,
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      child: InkWell(
        onTap: overdue ? onOverdue : onPayable,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To pay',
                      style: AppTextStyles.listName.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overdue
                          ? 'Includes overdue bills'
                          : 'Unpaid supplier bills',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              AppAmountText(
                amountMinor: payableMinor,
                symbol: symbol,
                color: overdue ? AppColors.error : AppColors.warning,
                style: AppTextStyles.listAmount.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectCard extends StatelessWidget {
  const _CollectCard({
    required this.overdue,
    required this.dueSoon,
    required this.symbol,
    required this.onOverdue,
    required this.onDueSoon,
    required this.onViewAll,
  });

  final List<InvoiceSummaryModel> overdue;
  final List<InvoiceSummaryModel> dueSoon;
  final String symbol;
  final VoidCallback onOverdue;
  final VoidCallback onDueSoon;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF3B2038) : Colors.white,
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      child: _CollectQueue(
        overdue: overdue,
        dueSoon: dueSoon,
        symbol: symbol,
        onOverdue: onOverdue,
        onDueSoon: onDueSoon,
        onViewAll: onViewAll,
      ),
    );
  }
}

class _CollectQueue extends StatelessWidget {
  const _CollectQueue({
    required this.overdue,
    required this.dueSoon,
    required this.symbol,
    required this.onOverdue,
    required this.onDueSoon,
    required this.onViewAll,
  });

  static const _visibleCount = 3;

  final List<InvoiceSummaryModel> overdue;
  final List<InvoiceSummaryModel> dueSoon;
  final String symbol;
  final VoidCallback onOverdue;
  final VoidCallback onDueSoon;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queue = [...overdue, ...dueSoon];
    final visible = queue.take(_visibleCount).toList();
    final overdueAmount = overdue.fold<int>(
      0,
      (sum, invoice) => sum + invoice.balanceMinor,
    );
    final dueSoonAmount = dueSoon.fold<int>(
      0,
      (sum, invoice) => sum + invoice.balanceMinor,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'To collect',
                  style: AppTextStyles.listName.copyWith(fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          Row(
            children: [
              if (overdue.isNotEmpty)
                Expanded(
                  child: _CollectFilter(
                    label: 'Overdue',
                    count: overdue.length,
                    amountMinor: overdueAmount,
                    symbol: symbol,
                    color: AppColors.error,
                    onTap: onOverdue,
                  ),
                ),
              if (overdue.isNotEmpty && dueSoon.isNotEmpty)
                const SizedBox(width: 8),
              if (dueSoon.isNotEmpty)
                Expanded(
                  child: _CollectFilter(
                    label: 'This week',
                    count: dueSoon.length,
                    amountMinor: dueSoonAmount,
                    symbol: symbol,
                    color: AppColors.warning,
                    onTap: onDueSoon,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFF0E6EA),
              ),
            _CollectPersonRow(invoice: visible[i], symbol: symbol),
          ],
        ],
      ),
    );
  }
}

class _CollectFilter extends StatelessWidget {
  const _CollectFilter({
    required this.label,
    required this.count,
    required this.amountMinor,
    required this.symbol,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final int amountMinor;
  final String symbol;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.18 : 0.12),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label · $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppAmountText(
                amountMinor: amountMinor,
                symbol: symbol,
                color: color,
                style: AppTextStyles.listAmount.copyWith(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectPersonRow extends StatelessWidget {
  const _CollectPersonRow({required this.invoice, required this.symbol});

  final InvoiceSummaryModel invoice;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final overdue = invoice.effectiveStatus(now) == InvoiceStatus.overdue;
    final color = overdue ? AppColors.error : AppColors.warning;
    final name = invoice.customerName.trim().isEmpty
        ? 'Customer not selected'
        : invoice.customerName.trim();
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return InkWell(
      onTap: () =>
          Get.toNamed<void>(AppRoutes.invoiceDetails, arguments: invoice.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                _collectInitials(name),
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listName.copyWith(
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 88,
                        child: AppAmountText(
                          amountMinor: invoice.balanceMinor,
                          symbol: symbol,
                          color: color,
                          textAlign: TextAlign.end,
                          style: AppTextStyles.listAmount.copyWith(
                            fontSize: 13.5,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${invoice.invoiceNumber} · ${_collectDueLabel(invoice, overdue, now)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: overdue ? AppColors.error : secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _collectInitials(String value) {
  final words = value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String _collectDueLabel(
  InvoiceSummaryModel invoice,
  bool overdue,
  DateTime now,
) {
  if (overdue) return 'Overdue';
  final due = invoice.dueDate;
  if (due == null) return 'Due this week';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final stamp = due.year == now.year
      ? '${due.day} ${months[due.month - 1]}'
      : '${due.day} ${months[due.month - 1]} ${due.year}';
  return 'Due $stamp';
}

class _BackupReminderPrompt extends StatelessWidget {
  const _BackupReminderPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A242E)
        : const Color(0xFFFFF8F3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : const Color(0xFFF5DED2),
      ),
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
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backup_outlined,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup due', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Protect your latest data with a local backup',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
