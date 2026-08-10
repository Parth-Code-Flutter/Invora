import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/report_controller.dart';

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: Obx(() {
      final value = controller.report.value;
      final symbol = controller.currencySymbol.value;
      final entries = [
        (
          'Total received',
          CurrencyUtils.formatMinor(value.totalReceivedMinor, symbol: symbol),
          Icons.payments_outlined,
        ),
        (
          'Outstanding',
          CurrencyUtils.formatMinor(value.outstandingMinor, symbol: symbol),
          Icons.schedule,
        ),
        (
          'Invoices created',
          '${value.invoiceCount}',
          Icons.receipt_long_outlined,
        ),
        ('Paid invoices', '${value.paidCount}', Icons.check_circle_outline),
        (
          'Pending invoices',
          '${value.pendingCount}',
          Icons.pending_actions_outlined,
        ),
      ];
      return ListView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        children: [
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
                  'TOTAL SALES • THIS MONTH',
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.gridColumns(
                context,
                tablet: 2,
                largeTablet: 3,
              ),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 122,
            ),
            itemCount: entries.length,
            itemBuilder: (_, index) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(entries[index].$3, color: AppColors.primary),
                  const Spacer(),
                  Text(
                    entries[index].$1,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(entries[index].$2, style: AppTextStyles.sectionTitle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Six-month sales', style: AppTextStyles.sectionTitle),
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
