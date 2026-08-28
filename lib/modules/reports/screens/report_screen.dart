import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/gst_export_model.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/report_controller.dart';
import '../widgets/report_charts.dart';

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Reports'),
      actions: [
        AppBarIconButton(
          tooltip: l10n('Export report'),
          onPressed: controller.openExport,
          icon: Icons.ios_share_rounded,
        ),
      ],
    ),
    body: Obx(() {
      final value = controller.report.value;
      final symbol = controller.currencySymbol.value;
      final change = value.salesChangePercent.round();
      final trendLabel = !value.hasPreviousSales
          ? (value.totalSalesMinor > 0 ? 'New vs last period' : null)
          : '${change >= 0 ? '+' : ''}$change% from last period';
      final period = controller.isMonthPreset
          ? _monthLabel(controller.from.value)
          : GstExportPeriod(
              from: controller.from.value,
              to: controller.to.value,
              preset: controller.preset.value,
            ).rangeLabel;
      return ResponsiveContent(
        tabletMaxWidth: 920,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _PeriodOptions(
              controller: controller,
              onPickFrom: () => _pickDate(context, from: true),
              onPickTo: () => _pickDate(context, from: false),
            ),
            const SizedBox(height: 14),
            ReportCollectionCard(
              salesMinor: value.totalSalesMinor,
              receivedMinor: value.totalReceivedMinor,
              outstandingMinor: value.outstandingMinor,
              symbol: symbol,
              periodLabel: period,
              trendLabel: trendLabel,
              trendUp: change >= 0,
              onOutstanding: value.outstandingMinor > 0
                  ? controller.openAgeing
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ReportKpiTile(
                    label: 'Received',
                    amountMinor: value.totalReceivedMinor,
                    symbol: symbol,
                    color: AppColors.success,
                    deltaLabel: _deltaLabel(
                      current: value.totalReceivedMinor,
                      previous: value.previousReceivedMinor,
                    ),
                    deltaUp:
                        value.totalReceivedMinor >= value.previousReceivedMinor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportKpiTile(
                    label: 'Outstanding',
                    amountMinor: value.outstandingMinor,
                    symbol: symbol,
                    color: AppColors.warning,
                    deltaLabel: value.outstandingMinor > 0
                        ? '${((value.collectionRate) * 100).round()}% collected'
                        : 'All collected',
                    deltaUp: true,
                    onTap: value.outstandingMinor > 0
                        ? controller.openAgeing
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your sales',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _yearCaption(value),
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ReportSegmentedStyle(
                        value: controller.chartStyle.value,
                        onChanged: controller.selectChartStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _LegendDot(color: AppColors.primary, label: 'Sales'),
                      const SizedBox(width: 14),
                      _LegendDot(color: AppColors.accent, label: 'Received'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ReportYearChart(
                    points: value.monthlySales,
                    style: controller.chartStyle.value,
                    symbol: symbol,
                    highlightIndex: controller.highlightIndex.value < 0
                        ? 0
                        : controller.highlightIndex.value,
                    onSelect: controller.selectPoint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ReportStatusDonut(
              created: value.invoiceCount,
              paid: value.paidCount,
              pending: value.pendingCount,
              creditNoteCount: value.creditNoteCount,
              onPaid: controller.openPaid,
              onPending: controller.openPending,
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.payments_outlined,
              title: 'Expenses',
              subtitle: 'Rent, fuel, salary and other cash spends',
              onTap: controller.openExpenses,
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.assignment_outlined,
              title: 'Purchase orders',
              subtitle:
                  'Order, receive, then convert remaining quantity to bills',
              onTap: controller.openPurchaseOrders,
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Cash book',
              subtitle: 'Cash, bank, UPI, transfers and daily closing',
              onTap: controller.openCashBook,
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.hourglass_bottom_rounded,
              title: 'Ageing & reminders',
              subtitle:
                  'Not due through 90+ days, then share a prepared reminder',
              onTap: controller.openAgeing,
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.account_balance_outlined,
              title: 'GST / CA export',
              subtitle: 'Prepared registers for your accountant',
              onTap: controller.openGst,
            ),
          ],
        ),
      );
    }),
  );

  Future<void> _pickDate(BuildContext context, {required bool from}) async {
    final result = await showDatePicker(
      context: context,
      initialDate: from ? controller.from.value : controller.to.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result == null) return;
    if (from) {
      controller.setFrom(result);
    } else {
      controller.setTo(result);
    }
  }

  static String _yearCaption(ReportSummaryModel value) {
    if (value.monthlySales.length < 2) return 'Last 12 months';
    final first = value.monthlySales.first.month;
    final last = value.monthlySales.last.month;
    return '${_shortMonth(first)} ${first.year}  –  ${_shortMonth(last)} ${last.year}';
  }

  static String _deltaLabel({required int current, required int previous}) {
    if (previous <= 0) {
      return current > 0 ? 'New vs last period' : 'From last period';
    }
    final percent = ((current - previous) / previous * 100).round();
    return '${percent >= 0 ? '+' : ''}$percent% from last period';
  }

  static String _shortMonth(DateTime value) {
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
    return months[value.month - 1];
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PeriodOptions extends StatelessWidget {
  const _PeriodOptions({
    required this.controller,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final ReportController controller;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in GstExportPeriodPreset.values) ...[
                AppFilterChip(
                  label: _presetLabel(value),
                  selected: controller.preset.value == value,
                  onSelected: (_) => controller.applyPreset(value),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (controller.preset.value == GstExportPeriodPreset.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  value: controller.from.value,
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  value: controller.to.value,
                  onTap: onPickTo,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _presetLabel(GstExportPeriodPreset value) => switch (value) {
    GstExportPeriodPreset.thisMonth => 'This month',
    GstExportPeriodPreset.lastMonth => 'Last month',
    GstExportPeriodPreset.thisFy => 'This FY',
    GstExportPeriodPreset.lastFy => 'Last FY',
    GstExportPeriodPreset.custom => 'Custom',
  };
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(
                '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime value) {
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
