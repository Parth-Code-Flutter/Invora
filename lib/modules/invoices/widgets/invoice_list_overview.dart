import 'package:flutter/material.dart';

import '../../../app/enums/invoice_status.dart';
import '../../../app/widgets/app_metric_overview.dart';
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
    return AppMetricOverview(
      currencySymbol: currencySymbol,
      items: [
        AppMetricOverviewItem(
          label: 'Received',
          amountMinor: received,
          count: active
              .where(
                (invoice) => invoice.grandTotalMinor > invoice.balanceMinor,
              )
              .length,
          countNoun: 'invoice',
          color: const Color(0xFF10B981),
          ring: const Color(0xFFECFDF5),
        ),
        AppMetricOverviewItem(
          label: 'Pending',
          amountMinor: pending,
          count: pendingInvoices.length,
          countNoun: 'invoice',
          color: const Color(0xFFF59E0B),
          ring: const Color(0xFFFFFBEB),
        ),
        AppMetricOverviewItem(
          label: 'Overdue',
          amountMinor: overdue,
          count: overdueInvoices.length,
          countNoun: 'invoice',
          color: const Color(0xFFF43F5E),
          ring: const Color(0xFFFFF1F2),
        ),
      ],
    );
  }
}
