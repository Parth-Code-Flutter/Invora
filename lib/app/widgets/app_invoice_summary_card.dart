import 'package:flutter/material.dart';

import '../../data/models/invoice_model.dart';
import '../constants/app_colors.dart';
import '../enums/invoice_status.dart';
import '../themes/app_text_styles.dart';
import 'app_amount_text.dart';
import 'app_grouped_tile.dart';

class AppInvoiceSummaryCard extends StatelessWidget {
  const AppInvoiceSummaryCard({
    required this.invoice,
    required this.currencySymbol,
    required this.onTap,
    this.position = AppGroupedPosition.single,
    super.key,
  });

  final InvoiceSummaryModel invoice;
  final String currencySymbol;
  final VoidCallback onTap;
  final AppGroupedPosition position;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = invoice.effectiveStatus(now);
    final statusColor = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerName = invoice.customerName.isEmpty
        ? 'Customer not selected'
        : invoice.customerName;
    final paid =
        status == InvoiceStatus.paid ||
        status == InvoiceStatus.accepted ||
        status == InvoiceStatus.cancelled;
    final overdue = status == InvoiceStatus.overdue;
    final dateHint = _dateHint(invoice, status, now);
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final initials = _initials(customerName);
    return AppGroupedTile(
      position: position,
      onTap: onTap,
      accentColor: statusColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: AppTextStyles.body.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listName,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: isDark ? 0.22 : 0.11,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: secondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 132,
                      child: AppAmountText(
                        amountMinor: invoice.grandTotalMinor,
                        symbol: currencySymbol,
                        textAlign: TextAlign.end,
                        color: paid ? secondary : null,
                        style: AppTextStyles.listAmount.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (status != InvoiceStatus.paid) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: overdue ? AppColors.error : statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (invoice.balanceMinor > 0) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 132,
                          child: AppAmountText(
                            amountMinor: invoice.balanceMinor,
                            symbol: currencySymbol,
                            suffix: ' due',
                            textAlign: TextAlign.end,
                            color: statusColor,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
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

String _statusLabel(InvoiceStatus status) => switch (status) {
  InvoiceStatus.partiallyPaid => 'Partial',
  _ => '${status.name[0].toUpperCase()}${status.name.substring(1)}',
};

String _dateHint(
  InvoiceSummaryModel invoice,
  InvoiceStatus status,
  DateTime now,
) {
  final showDue =
      invoice.dueDate != null &&
      (status == InvoiceStatus.unpaid ||
          status == InvoiceStatus.partiallyPaid ||
          status == InvoiceStatus.overdue ||
          status == InvoiceStatus.sent ||
          status == InvoiceStatus.expired);
  if (showDue) {
    return 'Due ${_compactDate(invoice.dueDate!, now)}';
  }
  return _compactDate(invoice.invoiceDate, now);
}

String _compactDate(DateTime value, DateTime now) {
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
  final month = months[value.month - 1];
  if (value.year == now.year) return '${value.day} $month';
  return '${value.day} $month ${value.year}';
}
