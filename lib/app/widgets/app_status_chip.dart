import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../enums/invoice_status.dart';
import '../themes/app_text_styles.dart';

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.status, this.compact = false, super.key});
  final InvoiceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      InvoiceStatus.paid ||
      InvoiceStatus.accepted => (AppColors.successBg, AppColors.success),
      InvoiceStatus.overdue ||
      InvoiceStatus.cancelled ||
      InvoiceStatus.rejected ||
      InvoiceStatus.expired => (AppColors.errorBg, AppColors.error),
      InvoiceStatus.draft => (AppColors.surfaceMuted, AppColors.textSecondary),
      InvoiceStatus.sent => (AppColors.primaryLight, AppColors.primary),
      _ => (AppColors.warningBg, const Color(0xFFD97706)),
    };
    final label = switch (status) {
      InvoiceStatus.partiallyPaid => 'Partially paid',
      _ => '${status.name[0].toUpperCase()}${status.name.substring(1)}',
    };
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            color: foreground,
            fontSize: compact ? 10.5 : 12,
            fontWeight: compact ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
