import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceListOverview extends StatelessWidget {
  const InvoiceListOverview({
    required this.invoices,
    required this.currencySymbol,
    this.now,
    super.key,
  });

  final List<InvoiceSummaryModel> invoices;
  final String currencySymbol;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final active = invoices.where((invoice) {
      final status = invoice.effectiveStatus(today);
      return status != InvoiceStatus.draft &&
          status != InvoiceStatus.cancelled &&
          status != InvoiceStatus.rejected;
    }).toList();
    final received = active.fold<int>(
      0,
      (sum, invoice) =>
          sum +
          (invoice.grandTotalMinor - invoice.balanceMinor).clamp(
            0,
            invoice.grandTotalMinor,
          ),
    );
    final overdueInvoices = active.where(
      (invoice) => invoice.effectiveStatus(today) == InvoiceStatus.overdue,
    );
    final overdue = overdueInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.balanceMinor,
    );
    final pendingInvoices = active.where((invoice) {
      final status = invoice.effectiveStatus(today);
      return invoice.balanceMinor > 0 && status != InvoiceStatus.overdue;
    });
    final pending = pendingInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.balanceMinor,
    );
    final metrics = [
      _OverviewMetric(
        label: 'Received',
        amountMinor: received,
        count: active
            .where((invoice) => invoice.grandTotalMinor > invoice.balanceMinor)
            .length,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _OverviewMetric(
        label: 'Pending',
        amountMinor: pending,
        count: pendingInvoices.length,
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
      ),
      _OverviewMetric(
        label: 'Overdue',
        amountMinor: overdue,
        count: overdueInvoices.length,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
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
          child: compact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      Expanded(
                        child: _MetricView(
                          metric: metrics[index],
                          symbol: currencySymbol,
                        ),
                      ),
                      if (index != metrics.length - 1)
                        Container(
                          width: 1,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                    ],
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: (constraints.maxWidth - 44) / 3,
                          child: _MetricView(
                            metric: metric,
                            symbol: currencySymbol,
                          ),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _MetricView extends StatelessWidget {
  const _MetricView({required this.metric, required this.symbol});

  final _OverviewMetric metric;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(8),
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
            symbol: symbol,
            style: AppTextStyles.listAmount.copyWith(fontSize: 13),
          )
        else
          Text(
            '${metric.count}',
            style: AppTextStyles.listAmount.copyWith(fontSize: 14),
          ),
        const SizedBox(height: 2),
        Text(
          '${metric.count} ${metric.count == 1 ? 'invoice' : 'invoices'}',
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

class _OverviewMetric {
  const _OverviewMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.amountMinor,
  });

  final String label;
  final int count;
  final int? amountMinor;
  final IconData icon;
  final Color color;
}
