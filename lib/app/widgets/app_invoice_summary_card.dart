import 'package:flutter/material.dart';

import '../../data/models/invoice_model.dart';
import '../constants/app_colors.dart';
import '../enums/invoice_status.dart';
import '../themes/app_text_styles.dart';
import '../utils/currency_utils.dart';
import 'app_card.dart';
import 'app_status_chip.dart';

class AppInvoiceSummaryCard extends StatelessWidget {
  const AppInvoiceSummaryCard({
    required this.invoice,
    required this.currencySymbol,
    required this.onTap,
    super.key,
  });

  final InvoiceSummaryModel invoice;
  final String currencySymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = invoice.effectiveStatus(DateTime.now());
    final statusColor = _statusColor(status);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, decoration: BoxDecoration(color: statusColor)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AppStatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.customerName.isEmpty
                                    ? 'Customer not selected'
                                    : invoice.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Issued ${_date(invoice.invoiceDate)}${invoice.dueDate == null ? '' : '  •  Due ${_date(invoice.dueDate!)}'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatMinor(
                                invoice.grandTotalMinor,
                                symbol: currencySymbol,
                              ),
                              style: AppTextStyles.sectionTitle,
                            ),
                            if (invoice.balanceMinor > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${CurrencyUtils.formatMinor(invoice.balanceMinor, symbol: currencySymbol)} due',
                                style: AppTextStyles.caption.copyWith(
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(InvoiceStatus status) => switch (status) {
  InvoiceStatus.paid || InvoiceStatus.accepted => AppColors.success,
  InvoiceStatus.overdue ||
  InvoiceStatus.cancelled ||
  InvoiceStatus.rejected => AppColors.error,
  InvoiceStatus.partiallyPaid ||
  InvoiceStatus.unpaid ||
  InvoiceStatus.expired => AppColors.warning,
  _ => AppColors.primary,
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
