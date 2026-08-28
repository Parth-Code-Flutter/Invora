import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../data/models/cash_book_models.dart';

Color cashBookTint(MoneyAccountType type) => switch (type) {
  MoneyAccountType.cash => AppColors.warning,
  MoneyAccountType.bank => AppColors.secondary,
  MoneyAccountType.upi => AppColors.accent,
  MoneyAccountType.card => AppColors.primary,
  MoneyAccountType.other => AppColors.textTertiary,
};

Color cashBookAmountColor(int amountMinor, {Color? fallback}) {
  if (amountMinor < 0) return AppColors.error;
  return fallback ?? AppColors.textPrimary;
}

class CashBookSectionHeader extends StatelessWidget {
  const CashBookSectionHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.listName.copyWith(fontSize: 15)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTextStyles.small),
          ],
        ],
      ),
    );
  }
}

class CashBookMixBar extends StatelessWidget {
  const CashBookMixBar({required this.accounts, super.key});

  final List<MoneyAccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (final account in accounts)
        if (account.availableMinor > 0)
          (account: account, weight: account.availableMinor),
    ];
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.weight);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                for (final slice in slices)
                  Expanded(
                    flex: slice.weight,
                    child: ColoredBox(
                      color: cashBookTint(slice.account.accountType),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final slice in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: cashBookTint(slice.account.accountType),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    slice.account.name,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class CashBookJumpStrip extends StatelessWidget {
  const CashBookJumpStrip({
    required this.onTransfer,
    required this.onCloseCash,
    required this.onAdvances,
    this.transferEnabled = true,
    this.closeCashEnabled = true,
    super.key,
  });

  final VoidCallback onTransfer;
  final VoidCallback onCloseCash;
  final VoidCallback onAdvances;
  final bool transferEnabled;
  final bool closeCashEnabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF472440) : const Color(0xFFFFF6F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              _JumpAction(
                label: 'Transfer',
                icon: Icons.swap_horiz_rounded,
                tint: AppColors.accent,
                enabled: transferEnabled,
                onTap: onTransfer,
              ),
              _JumpAction(
                label: 'Close cash',
                icon: Icons.point_of_sale_outlined,
                tint: AppColors.warning,
                enabled: closeCashEnabled,
                onTap: onCloseCash,
              ),
              _JumpAction(
                label: 'Advances',
                icon: Icons.savings_outlined,
                tint: AppColors.secondary,
                onTap: onAdvances,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JumpAction extends StatelessWidget {
  const _JumpAction({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CashBookActionPill extends StatelessWidget {
  const CashBookActionPill({
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class CashBookIconWell extends StatelessWidget {
  const CashBookIconWell({
    required this.icon,
    required this.tint,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? tint.withValues(alpha: 0.18)
            : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: tint, size: size * 0.48),
    );
  }
}
