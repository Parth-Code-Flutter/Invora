import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_snapshot_visuals.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/cash_book_models.dart';
import '../controllers/cash_book_controller.dart';
import '../widgets/cash_book_visuals.dart';

class CashBookScreen extends GetView<CashBookController> {
  const CashBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Cash book'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Add account'),
            onPressed: () => _showAccountSheet(context),
            icon: Icons.add_rounded,
          ),
        ],
      ),
      body: Obx(() {
        final symbol = controller.currencySymbol.value;
        final snap = controller.snapshot.value;
        final accounts = controller.accounts;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _CashBookSnapshotCard(
                snap: snap,
                accounts: accounts,
                symbol: symbol,
                isDark: isDark,
                onTransfer: () => _showTransferSheet(context),
                onCloseCash: () => _showClosingSheet(context),
                onAdvances: controller.openAdvance,
              ),
              const SizedBox(height: 18),
              const CashBookSectionHeader(
                title: 'Accounts',
                subtitle:
                    'Tap an account for its statement. Long-press to rename.',
              ),
              if (accounts.isEmpty)
                const AppEmptyState(
                  illustration: AppEmptyIllustration.wallet,
                  title: 'No accounts yet',
                  message:
                      'Cash, Bank, UPI, Card and Other are created automatically. Add another if you use more than one bank.',
                )
              else
                for (final (index, account) in accounts.indexed)
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showAccountSheet(context, account: account);
                    },
                    child: AppGroupedTile(
                      position: AppGroupedPositionX.resolve(
                        index,
                        accounts.length,
                      ),
                      onTap: () => controller.openStatement(account),
                      child: _AccountRow(account: account, symbol: symbol),
                    ),
                  ),
              if (snap.advances.isNotEmpty) ...[
                const SizedBox(height: 18),
                const CashBookSectionHeader(
                  title: 'Open advances',
                  subtitle:
                      'Cash already moved. Apply leftover to invoices or bills.',
                ),
                for (final (index, advance) in snap.advances.indexed)
                  AppGroupedTile(
                    position: AppGroupedPositionX.resolve(
                      index,
                      snap.advances.length,
                    ),
                    onTap: () => controller.openAdvance(
                      args: CashBookAdvanceArgs(
                        partyType: advance.partyType,
                        partyId: advance.partyId,
                        partyName: advance.partyName,
                      ),
                    ),
                    child: _AdvanceRow(advance: advance, symbol: symbol),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showAccountSheet(
    BuildContext context, {
    MoneyAccountModel? account,
  }) async {
    final name = TextEditingController(text: account?.name ?? '');
    final opening = TextEditingController();
    var type = account?.accountType ?? MoneyAccountType.bank;
    final error = await showModalBottomSheet<String>(
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHeader(
                    icon: account == null
                        ? Icons.add_rounded
                        : Icons.edit_outlined,
                    tint: cashBookTint(type),
                    title: account == null ? 'Add account' : 'Rename account',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppDropdownField<MoneyAccountType>(
                    label: 'Type',
                    sheetTitle: 'Account type',
                    value: type,
                    enabled: account?.isSystem != true,
                    options: [
                      for (final value in MoneyAccountType.values)
                        AppDropdownOption(
                          value: value,
                          label: value.label,
                          icon: value.icon,
                        ),
                    ],
                    onChanged: (value) => setState(() => type = value),
                  ),
                  if (account == null) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: opening,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Opening balance (optional)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: account == null ? 'Save account' : 'Save name',
                    onPressed: () async {
                      final result = await controller.saveAccount(
                        id: account?.id,
                        name: name.text,
                        type: type,
                        opening: opening.text,
                      );
                      if (!context.mounted) return;
                      if (result == null) {
                        Navigator.pop(context);
                      } else {
                        AppNotification.error('Cannot save account', result);
                      }
                    },
                  ),
                  if (account != null && !account.isArchived) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final result = await controller.archive(
                          account,
                          archived: true,
                        );
                        if (!context.mounted) return;
                        if (result == null) {
                          Navigator.pop(context);
                        } else {
                          AppNotification.error('Cannot archive', result);
                        }
                      },
                      child: const Text('Hide this account'),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
    name.dispose();
    opening.dispose();
    if (error != null) {
      AppNotification.error('Cannot save account', error);
    }
  }

  Future<void> _showTransferSheet(BuildContext context) async {
    final accounts = controller.accounts;
    if (accounts.length < 2) return;
    var fromId = accounts.first.id!;
    var toId = accounts[1].id!;
    final amount = TextEditingController();
    final note = TextEditingController();
    var date = DateTime.now();
    await showModalBottomSheet<void>(
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHeader(
                    icon: Icons.swap_horiz_rounded,
                    tint: AppColors.accent,
                    title: 'Transfer',
                  ),
                  const SizedBox(height: 16),
                  AppDropdownField<int>(
                    label: 'From',
                    value: fromId,
                    options: [
                      for (final account in accounts)
                        AppDropdownOption(
                          value: account.id!,
                          label: account.name,
                          icon: account.accountType.icon,
                        ),
                    ],
                    onChanged: (value) => setState(() => fromId = value),
                  ),
                  const SizedBox(height: 10),
                  AppDropdownField<int>(
                    label: 'To',
                    value: toId,
                    options: [
                      for (final account in accounts)
                        AppDropdownOption(
                          value: account.id!,
                          label: account.name,
                          icon: account.accountType.icon,
                        ),
                    ],
                    onChanged: (value) => setState(() => toId = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Record transfer',
                    onPressed: () async {
                      final result = await controller.transfer(
                        fromAccountId: fromId,
                        toAccountId: toId,
                        amount: amount.text,
                        date: date,
                        note: note.text,
                      );
                      if (!context.mounted) return;
                      if (result == null) {
                        Navigator.pop(context);
                      } else {
                        AppNotification.error('Cannot transfer', result);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    amount.dispose();
    note.dispose();
  }

  Future<void> _showClosingSheet(BuildContext context) async {
    final cash = controller.cashAccount;
    if (cash == null) return;
    final counted = TextEditingController(
      text: CurrencyUtils.toInputValue(cash.availableMinor),
    );
    final note = TextEditingController();
    await showModalBottomSheet<void>(
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
              const _SheetHeader(
                icon: Icons.point_of_sale_outlined,
                tint: AppColors.warning,
                title: 'Daily cash closing',
              ),
              const SizedBox(height: 8),
              Text(
                'Book cash ${CurrencyUtils.formatMinor(cash.availableMinor, symbol: controller.currencySymbol.value)}. Enter what you actually counted.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: counted,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Counted cash'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Save closing',
                onPressed: () async {
                  final result = await controller.closeCash(
                    counted: counted.text,
                    note: note.text,
                  );
                  if (!context.mounted) return;
                  if (result == null) {
                    Navigator.pop(context);
                  } else {
                    AppNotification.error('Cannot close cash', result);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    counted.dispose();
    note.dispose();
  }
}

class _CashBookSnapshotCard extends StatelessWidget {
  const _CashBookSnapshotCard({
    required this.snap,
    required this.accounts,
    required this.symbol,
    required this.isDark,
    required this.onTransfer,
    required this.onCloseCash,
    required this.onAdvances,
  });

  final CashBookSnapshot snap;
  final List<MoneyAccountModel> accounts;
  final String symbol;
  final bool isDark;
  final VoidCallback onTransfer;
  final VoidCallback onCloseCash;
  final VoidCallback onAdvances;

  @override
  Widget build(BuildContext context) {
    final cashMinor = accounts
        .where((account) => account.isCash)
        .fold<int>(0, (sum, account) => sum + account.availableMinor);
    final pending = snap.pendingMinor;
    final book = snap.bookMinor;
    final available = snap.availableMinor;
    final progress = pending > 0
        ? (book == 0 ? 0.0 : (available / book).clamp(0.0, 1.0))
        : (available <= 0 ? 0.0 : (cashMinor / available).clamp(0.0, 1.0));
    return AppCard(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF3B2038) : Colors.white,
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSnapshotHero(
            title: 'Cash book',
            trailing: AppSnapshotBadge(
              label: snap.todayCashClosing != null
                  ? 'Closed today'
                  : '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
            ),
            amountCaption: 'On hand',
            amountMinor: available,
            symbol: symbol,
            progress: progress,
            ringCaption: pending > 0 ? 'Available' : 'Cash share',
            trendLabel: pending == 0
                ? null
                : '${CurrencyUtils.formatMinor(pending.abs(), symbol: symbol)} pending',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
                const SizedBox(width: 8),
                Expanded(
                  child: AppMetricChip(
                    label: 'Advances',
                    amountMinor: snap.openAdvanceMinor,
                    symbol: symbol,
                    color: AppColors.accent,
                    icon: Icons.savings_outlined,
                    onTap: snap.advances.isEmpty ? null : onAdvances,
                  ),
                ),
              ],
            ),
          ),
          if (accounts.any((account) => account.availableMinor > 0))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: CashBookMixBar(accounts: accounts),
            ),
          CashBookJumpStrip(
            transferEnabled: accounts.length >= 2,
            closeCashEnabled: accounts.any((account) => account.isCash),
            onTransfer: onTransfer,
            onCloseCash: onCloseCash,
            onAdvances: onAdvances,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.symbol});

  final MoneyAccountModel account;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final tint = cashBookTint(account.accountType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final showType =
        account.name.trim().toLowerCase() !=
        account.accountType.label.toLowerCase();
    final pendingLabel = account.pendingMinor == 0
        ? null
        : '${CurrencyUtils.formatMinor(account.pendingMinor.abs(), symbol: symbol)} pending';
    final subtitle = [
      if (showType) account.accountType.label,
      ?pendingLabel,
    ].join(' · ');
    return Row(
      children: [
        CashBookIconWell(icon: account.accountType.icon, tint: tint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppAmountColumn(
          children: [
            AppAmountText(
              amountMinor: account.availableMinor,
              symbol: symbol,
              color: cashBookAmountColor(
                account.availableMinor,
                fallback: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Icon(Icons.chevron_right_rounded, color: muted, size: 20),
      ],
    );
  }
}

class _AdvanceRow extends StatelessWidget {
  const _AdvanceRow({required this.advance, required this.symbol});

  final PartyAdvanceModel advance;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final isCustomer = advance.partyType == PartyKind.customer;
    final tint = isCustomer ? AppColors.accent : AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Row(
      children: [
        CashBookIconWell(
          icon: isCustomer
              ? Icons.person_outline_rounded
              : Icons.storefront_outlined,
          tint: tint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                advance.partyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              const SizedBox(height: 2),
              Text(
                '${isCustomer ? 'Customer' : 'Supplier'} · ${advance.accountName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppAmountText(
          amountMinor: advance.remainingMinor,
          symbol: symbol,
          color: tint,
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.tint,
    required this.title,
  });

  final IconData icon;
  final Color tint;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CashBookIconWell(icon: icon, tint: tint, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
      ],
    );
  }
}
