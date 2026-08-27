import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/ageing_model.dart';
import '../controllers/ageing_controller.dart';

class AgeingScreen extends GetView<AgeingController> {
  const AgeingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Ageing & reminders'),
    ),
    bottomNavigationBar: Obx(() {
      if (controller.visibleRows.isEmpty) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.border,
              ),
            ),
          ),
          child: AppConstrainedAction(
            maxWidth: ResponsiveUtils.footerMaxWidth(context),
            child: AppButton(
              label: 'Share reminders',
              icon: Icons.ios_share_rounded,
              onPressed: controller.shareVisible,
            ),
          ),
        ),
      );
    }),
    body: Obx(() {
      if (controller.isLoading.value && controller.pack.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final pack = controller.pack.value;
      if (pack == null) {
        return const Center(child: Text('Ageing is unavailable.'));
      }
      final side = controller.side.value;
      final bucket = controller.bucket.value;
      final rows = pack.inBucket(side, bucket);
      return ResponsiveContent(
        tabletMaxWidth: 640,
        largeTabletMaxWidth: 720,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _SideTabs(
                    side: side,
                    receivablesCount: pack.receivables.length,
                    payablesCount: pack.payables.length,
                    onSelected: controller.selectSide,
                  ),
                  const SizedBox(height: 12),
                  _HeroCard(pack: pack, side: side),
                  const SizedBox(height: 12),
                  _BucketChips(
                    pack: pack,
                    side: side,
                    selected: bucket,
                    onSelected: controller.selectBucket,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reminders stay Prepared, Shared, or Skipped — never Delivered.',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (rows.isEmpty)
              const SliverToBoxAdapter(
                child: AppGroupedTile(
                  child: Text('Nothing outstanding in this bucket.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final row = rows[index];
                    return AppGroupedTile(
                      position: AppGroupedPositionX.resolve(index, rows.length),
                      onTap: () => controller.openRow(row),
                      child: _AgeingLine(
                        row: row,
                        symbol: pack.currencySymbol,
                        onShare: () => controller.shareRow(row),
                      ),
                    );
                  }, childCount: rows.length),
                ),
              ),
          ],
        ),
      );
    }),
  );
}

class _SideTabs extends StatelessWidget {
  const _SideTabs({
    required this.side,
    required this.receivablesCount,
    required this.payablesCount,
    required this.onSelected,
  });

  final AgeingSide side;
  final int receivablesCount;
  final int payablesCount;
  final ValueChanged<AgeingSide> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppFilterChip(
            label: 'To collect',
            count: receivablesCount,
            selected: side == AgeingSide.receivables,
            onSelected: (_) => onSelected(AgeingSide.receivables),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'To pay',
            count: payablesCount,
            selected: side == AgeingSide.payables,
            onSelected: (_) => onSelected(AgeingSide.payables),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pack, required this.side});
  final AgeingPack pack;
  final AgeingSide side;

  @override
  Widget build(BuildContext context) {
    final receivable = side == AgeingSide.receivables;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AS OF ${AgeingMath.dateLabel(pack.asOf)}',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            receivable ? 'To collect' : 'To pay',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          AppAmountText(
            amountMinor: pack.totalMinor(side),
            symbol: pack.currencySymbol,
            hero: true,
            color: Colors.white,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            receivable
                ? '${pack.rowsFor(side).length} invoices'
                : '${pack.rowsFor(side).length} bills',
            style: AppTextStyles.secondaryBody.copyWith(color: Colors.white70),
          ),
          Text(
            'Prepared, never Delivered',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _BucketChips extends StatelessWidget {
  const _BucketChips({
    required this.pack,
    required this.side,
    required this.selected,
    required this.onSelected,
  });

  final AgeingPack pack;
  final AgeingSide side;
  final AgeingBucket selected;
  final ValueChanged<AgeingBucket> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final summary in pack.buckets(side)) ...[
            AppFilterChip(
              label: summary.bucket.label,
              count: summary.count,
              selected: selected == summary.bucket,
              onSelected: (_) => onSelected(summary.bucket),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AgeingLine extends StatelessWidget {
  const _AgeingLine({
    required this.row,
    required this.symbol,
    required this.onShare,
  });

  final AgeingRow row;
  final String symbol;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final overdue = row.daysPastDue > 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.documentNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              const SizedBox(height: 2),
              Text(
                row.partyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(color: muted),
              ),
              const SizedBox(height: 2),
              Text(
                overdue
                    ? '${row.daysPastDue} days overdue'
                    : 'Due ${AgeingMath.dateLabel(row.dueDate)}',
                style: AppTextStyles.caption.copyWith(
                  color: overdue ? AppColors.warning : muted,
                ),
              ),
              if (row.reminderStatus != AgeingReminderStatus.none) ...[
                const SizedBox(height: 4),
                Text(
                  row.reminderStatus.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppAmountColumn(
          children: [
            AppAmountText(amountMinor: row.balanceMinor, symbol: symbol),
          ],
        ),
        IconButton(
          tooltip: l10n('Share reminder'),
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded, size: 20),
        ),
      ],
    );
  }
}
