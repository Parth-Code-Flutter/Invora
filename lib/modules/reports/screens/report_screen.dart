import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/report_controller.dart';

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Reports'),
    ),
    body: Obx(() {
      final value = controller.report.value;
      final symbol = controller.currencySymbol.value;
      return ListView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        children: [
          _MonthSelector(controller: controller),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.primary,
                  AppColors.accent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x285B5CE2),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SALES • ${_monthLabel(controller.selectedMonth.value).toUpperCase()}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatMinor(
                    value.totalSalesMinor,
                    symbol: symbol,
                  ),
                  style: AppTextStyles.displayAmount.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${value.invoiceCount} invoices created',
                      style: AppTextStyles.secondaryBody.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Received',
                  value: CurrencyUtils.formatMinor(
                    value.totalReceivedMinor,
                    symbol: symbol,
                  ),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Outstanding',
                  value: CurrencyUtils.formatMinor(
                    value.outstandingMinor,
                    symbol: symbol,
                  ),
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                _CountMetric(
                  label: 'Created',
                  value: value.invoiceCount,
                  icon: Icons.receipt_long_outlined,
                ),
                const _MetricDivider(),
                _CountMetric(
                  label: 'Paid',
                  value: value.paidCount,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const _MetricDivider(),
                _CountMetric(
                  label: 'Pending',
                  value: value.pendingCount,
                  icon: Icons.pending_actions_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales trend', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 3),
                Text(
                  'Six months ending ${_monthLabel(controller.selectedMonth.value)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 180,
                  child: _SalesChart(points: value.monthlySales),
                ),
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.controller});
  final ReportController controller;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Previous month',
        onPressed: controller.previousMonth,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: TextButton.icon(
          onPressed: () => _chooseMonth(context),
          icon: const Icon(Icons.calendar_month_outlined, size: 20),
          label: Text(_monthLabel(controller.selectedMonth.value)),
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Next month',
        onPressed: controller.canMoveNext ? controller.nextMonth : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );

  Future<void> _chooseMonth(BuildContext context) async {
    final now = DateTime.now();
    final months = List.generate(
      24,
      (index) => DateTime(now.year, now.month - index),
    );
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Choose month', style: AppTextStyles.sectionTitle),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final active =
                        month.year == controller.selectedMonth.value.year &&
                        month.month == controller.selectedMonth.value.month;
                    return ListTile(
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: active ? AppColors.primary : null,
                      ),
                      title: Text(_monthLabel(month)),
                      trailing: active
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, month),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) controller.selectMonth(selected);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 16),
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sectionTitle,
        ),
      ],
    ),
  );
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(height: 7),
        Text('$value', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 54, color: AppColors.border);
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

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.points});
  final List<MonthlySalesPoint> points;
  @override
  Widget build(BuildContext context) {
    final max = points.fold<int>(
      1,
      (value, point) => point.amountMinor > value ? point.amountMinor : value,
    );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        final height = 125 * point.amountMinor / max;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  height: height < 3 ? 3 : height,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 7),
                Text(months[point.month.month - 1], style: AppTextStyles.small),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
