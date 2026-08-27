import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/app_snapshot_visuals.dart';
import '../../../app/widgets/app_workspace_switch.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      salesDestination: MainDestination.home,
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
        actions: [
          AppBarIconButton(
            tooltip: l10n('Switch workspace'),
            onPressed: () => showWorkspaceSwitcher(context),
            icon: Icons.swap_horiz_rounded,
          ),
        ],
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
                _AttentionCard(
                  overdueCount: overdue.length,
                  overdueAmount: controller.overdueAmount(),
                  dueSoonCount: dueSoon.length,
                  dueSoonAmount: controller.dueSoonAmount(),
                  oldestName: overdue.isNotEmpty
                      ? overdue.first.customerName
                      : dueSoon.first.customerName,
                  symbol: _symbol,
                  onOverdue: () =>
                      controller.openInvoiceList(InvoiceListFilter.overdue),
                  onDueSoon: () =>
                      controller.openInvoiceList(InvoiceListFilter.unpaid),
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
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: showFollowUp ? 'Needs follow-up' : 'Recent invoices',
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
              const SizedBox(height: AppSpacing.sm),
              if (controller.recentLoading.value)
                const _RecentInvoicesLoading()
              else if (!showFollowUp && controller.recentInvoices.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No invoices yet',
                              style: AppTextStyles.listName,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create an invoice to see activity here.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                for (
                  var i = 0;
                  i <
                      (showFollowUp
                          ? followUp.length
                          : controller.recentInvoices.length);
                  i++
                )
                  Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          i ==
                              (showFollowUp
                                      ? followUp.length
                                      : controller.recentInvoices.length) -
                                  1
                          ? 0
                          : 8,
                    ),
                    child: AppInvoiceSummaryCard(
                      invoice: showFollowUp
                          ? followUp[i]
                          : controller.recentInvoices[i],
                      currencySymbol: _symbol,
                      onTap: () => Get.toNamed<void>(
                        AppRoutes.invoiceDetails,
                        arguments: showFollowUp
                            ? followUp[i].id
                            : controller.recentInvoices[i].id,
                      ),
                    ),
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
                _AttentionCard(
                  overdueCount: overdue.length,
                  overdueAmount: controller.overdueAmount(),
                  dueSoonCount: dueSoon.length,
                  dueSoonAmount: controller.dueSoonAmount(),
                  oldestName: overdue.isNotEmpty
                      ? overdue.first.customerName
                      : dueSoon.first.customerName,
                  symbol: symbol,
                  onOverdue: () =>
                      controller.openInvoiceList(InvoiceListFilter.overdue),
                  onDueSoon: () =>
                      controller.openInvoiceList(InvoiceListFilter.unpaid),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text('No invoices yet', style: AppTextStyles.listName),
            const SizedBox(height: 4),
            Text(
              'Create an invoice to see activity here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    super.key,
  });

  final ReportSummaryModel report;
  final String symbol;
  final VoidCallback? onOutstandingTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collected = report.totalSalesMinor <= 0
        ? 0.0
        : (report.totalReceivedMinor / report.totalSalesMinor).clamp(0.0, 1.0);
    final sparkline = report.monthlySales
        .map((point) => point.amountMinor.toDouble())
        .toList(growable: false);
    return AppCard(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF3B2038) : Colors.white,
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSnapshotHero(
            title: 'This month',
            trailing: AppSnapshotBadge(
              label:
                  '${report.invoiceCount} ${report.invoiceCount == 1 ? 'invoice' : 'invoices'}',
            ),
            amountCaption: 'Total invoiced',
            amountMinor: report.totalSalesMinor,
            symbol: symbol,
            progress: collected,
            ringCaption: 'Collected',
            sparkline: sparkline,
            trendLabel: _monthOverMonthTrend(report.monthlySales),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppMetricChip(
                    label: 'Received',
                    amountMinor: report.totalReceivedMinor,
                    symbol: symbol,
                    color: AppColors.success,
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppMetricChip(
                    label: 'Outstanding',
                    amountMinor: report.outstandingMinor,
                    symbol: symbol,
                    color: AppColors.warning,
                    icon: Icons.schedule_rounded,
                    onTap: report.outstandingMinor > 0
                        ? onOutstandingTap
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const _HomeJumpStrip(),
        ],
      ),
    );
  }
}

String? _monthOverMonthTrend(List<MonthlySalesPoint> points) {
  if (points.length < 2) return null;
  final previous = points[points.length - 2].amountMinor;
  final current = points.last.amountMinor;
  if (previous <= 0) return current > 0 ? 'Up from last month' : null;
  final percent = ((current - previous) / previous * 100).round();
  if (percent == 0) return 'Flat vs last month';
  if (percent.abs() > 400) return null;
  return '${percent > 0 ? '+' : ''}$percent% vs last month';
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
      height: 148,
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
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
                onTap: () => Get.toNamed<void>(AppRoutes.products),
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

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.overdueCount,
    required this.overdueAmount,
    required this.dueSoonCount,
    required this.dueSoonAmount,
    required this.oldestName,
    required this.symbol,
    required this.onOverdue,
    required this.onDueSoon,
  });

  final int overdueCount;
  final int overdueAmount;
  final int dueSoonCount;
  final int dueSoonAmount;
  final String oldestName;
  final String symbol;
  final VoidCallback onOverdue;
  final VoidCallback onDueSoon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          if (overdueCount > 0)
            _AttentionRow(
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
              fill: AppColors.errorLight,
              title: overdueCount == 1
                  ? '1 invoice overdue'
                  : '$overdueCount invoices overdue',
              subtitle: oldestName.trim().isEmpty ? null : oldestName,
              amountMinor: overdueAmount,
              symbol: symbol,
              onTap: onOverdue,
            ),
          if (overdueCount > 0 && dueSoonCount > 0) const Divider(height: 1),
          if (dueSoonCount > 0)
            _AttentionRow(
              icon: Icons.event_available_outlined,
              color: AppColors.warning,
              fill: AppColors.warningLight,
              title: dueSoonCount == 1
                  ? '1 due this week'
                  : '$dueSoonCount due this week',
              amountMinor: dueSoonAmount,
              symbol: symbol,
              onTap: onDueSoon,
            ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.fill,
    required this.title,
    required this.amountMinor,
    required this.symbol,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color fill;
  final String title;
  final String? subtitle;
  final int amountMinor;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.listName),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppAmountColumn(
              maxWidth: 110,
              children: [
                AppAmountText(
                  amountMinor: amountMinor,
                  symbol: symbol,
                  color: color,
                  style: AppTextStyles.listAmount.copyWith(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
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
