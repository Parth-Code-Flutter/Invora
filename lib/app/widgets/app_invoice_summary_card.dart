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
                padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            invoice.customerName.isEmpty
                                ? 'Customer not selected'
                                : invoice.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateLine(invoice.invoiceDate, invoice.dueDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppStatusChip(status: status),
                        const SizedBox(height: 7),
                        Text(
                          CurrencyUtils.formatMinor(
                            invoice.grandTotalMinor,
                            symbol: currencySymbol,
                          ),
                          style: AppTextStyles.sectionTitle,
                        ),
                        if (invoice.balanceMinor > 0 &&
                            invoice.balanceMinor !=
                                invoice.grandTotalMinor) ...[
                          const SizedBox(height: 2),
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

String _dateLine(DateTime issued, DateTime? due) {
  final issuedText = _shortDate(issued);
  return due == null
      ? 'Issued $issuedText'
      : 'Issued $issuedText  •  Due ${_shortDate(due)}';
}

String _shortDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
