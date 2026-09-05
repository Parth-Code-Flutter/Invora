import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_amount_text.dart';

class AppMetricOverviewItem {
  const AppMetricOverviewItem({
    required this.label,
    required this.amountMinor,
    required this.count,
    required this.countNoun,
    required this.color,
    required this.ring,
    this.onTap,
  });

  final String label;
  final int amountMinor;
  final int count;
  final String countNoun;
  final Color color;
  final Color ring;
  final VoidCallback? onTap;
}

/// Nested Received / Pending / Overdue tiles used on Sales and Purchases.
class AppMetricOverview extends StatelessWidget {
  const AppMetricOverview({
    required this.items,
    required this.currencySymbol,
    super.key,
  });

  final List<AppMetricOverviewItem> items;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
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
          for (var index = 0; index < items.length; index++) ...[
            if (index != 0) const SizedBox(width: 6),
            Expanded(
              child: _MetricTile(item: items[index], symbol: currencySymbol),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item, required this.symbol});

  final AppMetricOverviewItem item;
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
    final noun = item.count == 1 ? item.countNoun : '${item.countNoun}s';
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
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
                  color: item.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: item.ring, spreadRadius: 4, blurRadius: 0),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.caption.copyWith(
                      color: secondary,
                      fontSize: 11,
                      height: 16.5 / 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppAmountText(
              amountMinor: item.amountMinor,
              symbol: symbol,
              textAlign: TextAlign.start,
              style: AppTextStyles.listAmount.copyWith(
                fontSize: 16,
                height: 24 / 16,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${item.count} $noun',
              maxLines: 1,
              softWrap: false,
              style: AppTextStyles.caption.copyWith(
                color: muted,
                fontSize: 10,
                height: 15 / 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
    if (item.onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
