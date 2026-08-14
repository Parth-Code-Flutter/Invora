import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_amount_text.dart';

class CustomerListOverview extends StatelessWidget {
  const CustomerListOverview({
    required this.totalCustomers,
    required this.amountDueMinor,
    required this.dueCustomers,
    required this.paidAmountMinor,
    required this.paidCustomers,
    required this.currencySymbol,
    super.key,
  });

  final int totalCustomers;
  final int amountDueMinor;
  final int dueCustomers;
  final int paidAmountMinor;
  final int paidCustomers;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = [
      _CustomerMetric(
        label: 'Total customers',
        countLabel: '$totalCustomers active',
        value: '$totalCustomers',
        icon: Icons.group_outlined,
        color: AppColors.secondary,
      ),
      _CustomerMetric(
        label: 'Amount due',
        countLabel: _customersLabel(dueCustomers),
        amountMinor: amountDueMinor,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      ),
      _CustomerMetric(
        label: 'Paid amount',
        countLabel: _customersLabel(paidCustomers),
        amountMinor: paidAmountMinor,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(
              child: _MetricView(
                metric: metrics[index],
                currencySymbol: currencySymbol,
              ),
            ),
            if (index != metrics.length - 1)
              Container(
                width: 1,
                height: 62,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _MetricView extends StatelessWidget {
  const _MetricView({required this.metric, required this.currencySymbol});

  final _CustomerMetric metric;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(metric.icon, size: 15, color: metric.color),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: secondary,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (metric.amountMinor != null)
          AppAmountText(
            amountMinor: metric.amountMinor!,
            symbol: currencySymbol,
            style: AppTextStyles.listAmount.copyWith(fontSize: 14),
          )
        else
          Text(metric.value!, style: AppTextStyles.listAmount),
        const SizedBox(height: 2),
        Text(
          metric.countLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: secondary,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}

class _CustomerMetric {
  const _CustomerMetric({
    required this.label,
    required this.countLabel,
    required this.icon,
    required this.color,
    this.value,
    this.amountMinor,
  });

  final String label;
  final String countLabel;
  final String? value;
  final int? amountMinor;
  final IconData icon;
  final Color color;
}

String _customersLabel(int count) =>
    '$count ${count == 1 ? 'customer' : 'customers'}';
