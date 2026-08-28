import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_snapshot_visuals.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/cash_book_models.dart';
import '../controllers/cash_book_controller.dart';
import '../widgets/cash_book_visuals.dart';

class AccountStatementScreen extends GetView<AccountStatementController> {
  const AccountStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(
          () => AppBarTitle(
            controller.account.value?.name ?? 'Account',
            subtitle: 'Statement',
          ),
        ),
      ),
      body: Obx(() {
        final symbol = controller.currencySymbol.value;
        final account = controller.account.value;
        final rows = controller.movements;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (account != null) ...[
                _StatementHero(
                  account: account,
                  symbol: symbol,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: 'This month',
                    selected:
                        controller.rangePreset.value ==
                        StatementRangePreset.thisMonth,
                    onSelected: (_) =>
                        controller.applyRange(StatementRangePreset.thisMonth),
                  ),
                  AppFilterChip(
                    label: 'Last month',
                    selected:
                        controller.rangePreset.value ==
                        StatementRangePreset.lastMonth,
                    onSelected: (_) =>
                        controller.applyRange(StatementRangePreset.lastMonth),
                  ),
                  AppFilterChip(
                    label: 'All time',
                    selected:
                        controller.rangePreset.value ==
                        StatementRangePreset.all,
                    onSelected: (_) =>
                        controller.applyRange(StatementRangePreset.all),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _pickCustomRange(context),
                  child: Text(
                    '${_date(controller.from.value)} – ${_date(controller.to.value)}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (rows.isEmpty)
                const AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No movements',
                  message:
                      'Receipts, payments, transfers and closings for this account appear here.',
                )
              else
                for (final (index, movement) in rows.indexed)
                  AppGroupedTile(
                    position: AppGroupedPositionX.resolve(index, rows.length),
                    accentColor: movement.isPendingCheque
                        ? AppColors.warning
                        : movement.direction == MoneyDirection.inbound
                        ? AppColors.success
                        : AppColors.error,
                    child: _MovementRow(
                      movement: movement,
                      symbol: symbol,
                      onClear: movement.canClearCheque
                          ? () => controller.clearCheque(movement)
                          : null,
                      onBounce: movement.canBounceCheque
                          ? () => _bounce(context, movement)
                          : null,
                    ),
                  ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final from = await showDatePicker(
      context: context,
      initialDate: controller.from.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (from == null || !context.mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: controller.to.value.isBefore(from)
          ? from
          : controller.to.value,
      firstDate: from,
      lastDate: DateTime.now(),
    );
    if (to == null) return;
    controller.setFrom(from);
    controller.setTo(to);
  }

  Future<void> _bounce(
    BuildContext context,
    MoneyMovementModel movement,
  ) async {
    final reason = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  CashBookIconWell(
                    icon: Icons.block_rounded,
                    tint: AppColors.error,
                    size: 36,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bounce cheque',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The original invoice or bill payment is reversed so the books stay even.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Bounce cheque',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );
    final text = reason.text;
    reason.dispose();
    if (confirmed != true) return;
    final error = await controller.bounceCheque(movement, text);
    if (error != null) {
      AppNotification.error('Cannot bounce cheque', error);
    }
  }
}

class _StatementHero extends StatelessWidget {
  const _StatementHero({
    required this.account,
    required this.symbol,
    required this.isDark,
  });

  final MoneyAccountModel account;
  final String symbol;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final available = account.availableMinor;
    final book = account.bookMinor;
    final pending = account.pendingMinor;
    final progress = book == 0 ? 0.0 : (available / book).clamp(0.0, 1.0);
    return AppCard(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF3B2038) : Colors.white,
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSnapshotHero(
            title: account.name,
            trailing: AppSnapshotBadge(label: account.accountType.label),
            amountCaption: 'Available',
            amountMinor: available,
            symbol: symbol,
            progress: progress,
            ringCaption: 'Of book',
            trendLabel: pending == 0
                ? null
                : '${CurrencyUtils.formatMinor(pending.abs(), symbol: symbol)} pending',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: AppMetricChip(
                    label: 'Book',
                    amountMinor: book,
                    symbol: symbol,
                    color: AppColors.secondary,
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppMetricChip(
                    label: 'Pending',
                    amountMinor: pending.abs(),
                    symbol: symbol,
                    color: AppColors.warning,
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.movement,
    required this.symbol,
    this.onClear,
    this.onBounce,
  });

  final MoneyMovementModel movement;
  final String symbol;
  final Future<String?> Function()? onClear;
  final VoidCallback? onBounce;

  @override
  Widget build(BuildContext context) {
    final inbound = movement.direction == MoneyDirection.inbound;
    final color = movement.isPendingCheque
        ? AppColors.warning
        : inbound
        ? AppColors.success
        : AppColors.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final meta = [
      _date(movement.occurredAt),
      if (movement.reference != null) movement.reference!,
      if (movement.note != null) movement.note!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CashBookIconWell(
              icon: inbound
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              tint: color,
              size: 38,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.listName,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppAmountColumn(
              children: [
                AppAmountText(
                  amountMinor: movement.signedMinor,
                  symbol: symbol,
                  color: color,
                ),
                Text(
                  CurrencyUtils.formatMinor(
                    movement.runningBalanceMinor,
                    symbol: symbol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (onClear != null || onBounce != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (onClear != null)
                CashBookActionPill(
                  label: 'Clear',
                  color: AppColors.success,
                  onTap: () async {
                    final error = await onClear!();
                    if (error != null) {
                      AppNotification.error('Cannot clear cheque', error);
                    }
                  },
                ),
              if (onClear != null && onBounce != null) const SizedBox(width: 8),
              if (onBounce != null)
                CashBookActionPill(
                  label: 'Bounce',
                  color: AppColors.error,
                  onTap: onBounce!,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
