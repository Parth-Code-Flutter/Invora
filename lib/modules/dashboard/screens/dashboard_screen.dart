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
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_workspace_switch.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/report_summary_model.dart';
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
      body: Row(
        children: [
          if (ResponsiveUtils.isTablet(context)) _navigationRail(),
          Expanded(
            child: ResponsiveContent(
              tabletMaxWidth: 840,
              paddingTop: AppSpacing.xs,
              child: Obx(() {
                final overdue = controller.overdueInvoices();
                final dueSoon = controller.dueSoonInvoices();
                final followUp = controller.followUpInvoices();
                final showFollowUp = followUp.isNotEmpty;
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
                              onOutstandingTap: () => controller
                                  .openInvoiceList(InvoiceListFilter.unpaid),
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
                        onOverdue: () => controller.openInvoiceList(
                          InvoiceListFilter.overdue,
                        ),
                        onDueSoon: () => controller.openInvoiceList(
                          InvoiceListFilter.unpaid,
                        ),
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
                    const SizedBox(height: AppSpacing.md),
                    _SectionHeader(
                      title: 'Quick actions',
                      subtitle: 'Create and manage your business',
                      actionLabel: 'Reports',
                      actionIcon: Icons.insights_rounded,
                      onAction: () => Get.toNamed<void>(AppRoutes.reports),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (ResponsiveUtils.isTablet(context)) ...[
                      AppButton(
                        label: 'Create invoice',
                        icon: Icons.add_rounded,
                        onPressed: () =>
                            Get.toNamed<void>(AppRoutes.invoiceCreate),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Estimate',
                          icon: Icons.request_quote_outlined,
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.quotationCreate),
                        ),
                        const SizedBox(width: 8),
                        _QuickAction(
                          label: 'Customer',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.customerAdd),
                        ),
                        const SizedBox(width: 8),
                        _QuickAction(
                          label: 'Product',
                          icon: Icons.add_box_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.productAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                                            : controller
                                                  .recentInvoices
                                                  .length) -
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
          ),
        ],
      ),
    );
  }

  String get _symbol => controller.profile.value?.currencySymbol ?? '₹';

  String get _businessInitial {
    final name = controller.profile.value?.businessName.trim() ?? '';
    return name.isEmpty ? 'C' : name.characters.first.toUpperCase();
  }

  Widget _navigationRail() => NavigationRail(
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
    return AppCard(
      color: isDark ? const Color(0xFF3B2038) : const Color(0xFFFCFAFF),
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('This month', style: AppTextStyles.listName),
              ),
              Text(
                '${report.invoiceCount} ${report.invoiceCount == 1 ? 'invoice' : 'invoices'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Invoiced',
                  amountMinor: report.totalSalesMinor,
                  symbol: symbol,
                  color: AppColors.secondary,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: _OverviewMetric(
                  label: 'Received',
                  amountMinor: report.totalReceivedMinor,
                  symbol: symbol,
                  color: AppColors.success,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: report.outstandingMinor > 0
                        ? onOutstandingTap
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: _OverviewMetric(
                      label: 'Outstanding',
                      amountMinor: report.outstandingMinor,
                      symbol: symbol,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
      height: 72,
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
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? actionIcon;

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
      TextButton.icon(
        onPressed: onAction,
        icon: actionIcon == null
            ? const SizedBox.shrink()
            : Icon(actionIcon, size: 18),
        label: Text(actionLabel),
      ),
    ],
  );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    required this.color,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        AppAmountText(
          amountMinor: amountMinor,
          symbol: symbol,
          color: color,
          textAlign: TextAlign.start,
          style: AppTextStyles.listAmount.copyWith(fontSize: 13, color: color),
        ),
      ],
    ),
  );
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border,
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 5),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    ),
  );
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
