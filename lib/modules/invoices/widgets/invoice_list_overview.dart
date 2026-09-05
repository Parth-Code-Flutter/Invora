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
        color: const Color(0xFF10B981),
        ring: const Color(0xFFECFDF5),
      ),
      _OverviewMetric(
        label: 'Pending',
        amountMinor: pending,
        count: pendingInvoices.length,
        color: const Color(0xFFF59E0B),
        ring: const Color(0xFFFFFBEB),
      ),
      _OverviewMetric(
        label: 'Overdue',
        amountMinor: overdue,
        count: overdueInvoices.length,
        color: const Color(0xFFF43F5E),
        ring: const Color(0xFFFFF1F2),
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEBE7E9),
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                if (index != 0) const SizedBox(width: 8),
                Expanded(
                  child: _MetricView(
                    metric: metrics[index],
                    symbol: currencySymbol,
                  ),
                ),
              ],
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF4B5563);
    final muted = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFFCFAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: metric.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: metric.ring,
                      spreadRadius: 4,
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: secondary,
                    fontSize: 11,
                    height: 16.5 / 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (metric.amountMinor != null)
            AppAmountText(
              amountMinor: metric.amountMinor!,
              symbol: symbol,
              textAlign: TextAlign.start,
              style: AppTextStyles.listAmount.copyWith(
                fontSize: 16,
                height: 24 / 16,
                letterSpacing: -0.4,
              ),
            )
          else
            Text(
              '${metric.count}',
              style: AppTextStyles.listAmount.copyWith(fontSize: 16),
            ),
          const SizedBox(height: 2),
          Text(
            '${metric.count} ${metric.count == 1 ? 'invoice' : 'invoices'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: muted,
              fontSize: 10,
              height: 15 / 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric {
  const _OverviewMetric({
    required this.label,
    required this.count,
    required this.color,
    required this.ring,
    this.amountMinor,
  });

  final String label;
  final int count;
  final int? amountMinor;
  final Color color;
  final Color ring;
}
