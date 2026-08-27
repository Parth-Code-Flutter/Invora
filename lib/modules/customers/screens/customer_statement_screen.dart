import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../data/models/customer_statement_model.dart';
import '../controllers/customer_statement_controller.dart';

class CustomerStatementScreen extends GetView<CustomerStatementController> {
  const CustomerStatementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Obx(() {
        final name = controller.statement.value?.customer.name.trim();
        if (name == null || name.isEmpty) {
          return const AppBarTitle('Customer statement');
        }
        return AppBarTitle(name, subtitle: 'Statement');
      }),
      actions: [
        AppBarIconButton(
          onPressed: controller.share,
          icon: Icons.ios_share_rounded,
          tooltip: l10n('Share PDF'),
        ),
        AppBarIconButton(
          onPressed: () => _showStatementActions(context),
          icon: Icons.more_vert_rounded,
          tooltip: l10n('Statement actions'),
        ),
      ],
    ),
    bottomNavigationBar: Obx(() {
      if (controller.isLoading.value || controller.statement.value == null) {
        return const SizedBox.shrink();
      }
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
            child: AppButton(
              label: 'Preview statement PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () => _preview(context),
            ),
          ),
        ),
      );
    }),
    body: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final statement = controller.statement.value;
      if (statement == null) {
        return const Center(child: Text('Statement is unavailable.'));
      }
      final sections = [
        _StatementHero(statement: statement),
        _StatementTotalsCard(statement: statement),
        _PeriodCard(
          from: statement.from,
          to: statement.to,
          onPick: () => _pickRange(context, statement.from, statement.to),
        ),
        _ActivitySection(statement: statement),
      ];
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isTablet(context) ? 820 : 680,
          ),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              8,
              ResponsiveUtils.horizontalPadding(context),
              16,
            ),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => sections[index],
          ),
        ),
      );
    }),
  );

  Future<void> _showStatementActions(BuildContext context) =>
      showAppBottomSheet<void>(
        context: context,
        title: 'Statement actions',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionTile(
              icon: Icons.download_outlined,
              title: 'Save PDF',
              subtitle: 'Keep a copy of this statement on the device.',
              onTap: () {
                Navigator.pop(context);
                controller.save();
              },
            ),
            _ActionTile(
              icon: Icons.print_outlined,
              title: 'Print',
              subtitle: 'Send this statement to a printer.',
              onTap: () {
                Navigator.pop(context);
                controller.print();
              },
            ),
          ],
        ),
      );

  Future<void> _pickRange(
    BuildContext context,
    DateTime from,
    DateTime to,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: from, end: to),
      helpText: l10n('Select period'),
      saveText: l10n('Apply'),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              secondary: AppColors.primary,
              onSecondary: Colors.white,
              surfaceTint: AppColors.secondaryLight,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppColors.secondaryLight,
              rangePickerHeaderBackgroundColor: AppColors.secondary,
              rangePickerHeaderForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) await controller.setRange(range.start, range.end);
  }

  void _preview(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PdfPreview(
      build: (_) => controller.buildPdf(),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
    ),
  );
}

class _StatementHero extends StatelessWidget {
  const _StatementHero({required this.statement});

  final CustomerStatementModel statement;

  bool get _hasDue => statement.closingBalanceMinor > 0;

  List<Color> get _colors {
    if (_hasDue) return const [AppColors.secondary, AppColors.warning];
    if (statement.totalInvoicedMinor > 0 || statement.openingBalanceMinor > 0) {
      return const [AppColors.secondary, AppColors.success];
    }
    return const [AppColors.secondary, AppColors.primary];
  }

  String? get _statusLabel {
    if (_hasDue) return 'Outstanding';
    if (statement.totalInvoicedMinor > 0 || statement.openingBalanceMinor > 0) {
      return 'Paid in full';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final customer = statement.customer;
    final caption = [
      if ((customer.companyName ?? '').trim().isNotEmpty) customer.companyName!,
      if ((customer.gstin ?? '').trim().isNotEmpty) 'GSTIN ${customer.gstin}',
      if ((customer.mobile ?? '').trim().isNotEmpty) customer.mobile!,
    ].join(' • ');
    final statusLabel = _statusLabel;
    final colors = _colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .2),
                      ),
                    ),
                    child: Text(
                      _initials(customer.name),
                      style: AppTextStyles.listName.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_date(statement.from)} - ${_date(statement.to)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listName.copyWith(
                            color: Colors.white,
                            fontSize: 14.5,
                          ),
                        ),
                        if (caption.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatementTotalsCard extends StatelessWidget {
  const _StatementTotalsCard({required this.statement});

  final CustomerStatementModel statement;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final closing = statement.closingBalanceMinor;
    final remainingColor = closing > 0 ? AppColors.warning : AppColors.success;
    final remainingFill = closing > 0
        ? AppColors.warningLight
        : AppColors.successLight;
    final symbol = statement.business.currencySymbol;
    final closingCard = _MetricCard(
      label: 'Closing',
      amount: closing,
      symbol: symbol,
      color: remainingColor,
      fill: remainingFill,
    );
    final invoicedCard = _MetricCard(
      label: 'Invoiced',
      amount: statement.totalInvoicedMinor,
      symbol: symbol,
      color: AppColors.secondary,
      fill: AppColors.secondaryLight,
    );
    final receivedCard = _MetricCard(
      label: 'Received',
      amount: statement.totalReceivedMinor,
      symbol: symbol,
      color: AppColors.success,
      fill: AppColors.successLight,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Account summary',
            style: AppTextStyles.listName.copyWith(fontSize: 15),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: closingCard),
                    const SizedBox(width: 10),
                    Expanded(child: invoicedCard),
                    const SizedBox(width: 10),
                    Expanded(child: receivedCard),
                  ],
                )
              else
                Column(
                  children: [
                    closingCard,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: invoicedCard),
                        const SizedBox(width: 10),
                        Expanded(child: receivedCard),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Opening',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppAmountText(
                      amountMinor: statement.openingBalanceMinor,
                      symbol: symbol,
                      textAlign: TextAlign.end,
                      color: AppColors.textSecondary,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.fill,
  });

  final String label;
  final int amount;
  final String symbol;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .18) : fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AppAmountText(
            amountMinor: amount,
            symbol: symbol,
            color: color,
            textAlign: TextAlign.start,
            style: AppTextStyles.listAmount.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.from,
    required this.to,
    required this.onPick,
  });

  final DateTime from;
  final DateTime to;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final well = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSoft;
    final line = isDark ? AppColors.darkBorder : AppColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Period',
            style: AppTextStyles.listName.copyWith(fontSize: 15),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: onPick,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: well,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateChip(label: 'From', value: from),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: muted,
                        ),
                      ),
                      Expanded(
                        child: _DateChip(label: 'To', value: to),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more_rounded, color: muted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});

  final String label;
  final DateTime value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: muted, fontSize: 10),
        ),
        const SizedBox(height: 1),
        Text(
          _calendarDate(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.listName.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.statement});

  final CustomerStatementModel statement;

  @override
  Widget build(BuildContext context) {
    final entries = statement.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Account activity',
                  style: AppTextStyles.listName.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          AppGroupedTile(
            child: Text(
              'No account activity in this date range.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          for (final (index, entry) in entries.indexed)
            AppGroupedTile(
              position: AppGroupedPositionX.resolve(index, entries.length),
              accentColor: _entryColor(entry.type),
              child: _StatementEntryTile(
                entry: entry,
                symbol: statement.business.currencySymbol,
              ),
            ),
      ],
    );
  }
}

class _StatementEntryTile extends StatelessWidget {
  const _StatementEntryTile({required this.entry, required this.symbol});

  final CustomerStatementEntry entry;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final color = _entryColor(entry.type);
    final fill = _entryFill(entry.type);
    final amount = entry.debitMinor > 0 ? entry.debitMinor : entry.creditMinor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: .18) : fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_entryIcon(entry.type), color: color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              const SizedBox(height: 2),
              Text(
                '${_date(entry.date)} · ${entry.reference}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AppAmountColumn(
          maxWidth: 128,
          children: [
            AppAmountText(
              amountMinor: amount,
              symbol: symbol,
              color: color,
              style: AppTextStyles.listAmount.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                'Bal ${CurrencyUtils.formatMinor(entry.balanceMinor, symbol: symbol)}',
                maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.listName),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

Color _entryColor(CustomerStatementEntryType type) => switch (type) {
  CustomerStatementEntryType.invoice => AppColors.warning,
  CustomerStatementEntryType.payment => AppColors.success,
  CustomerStatementEntryType.reversal => AppColors.error,
  CustomerStatementEntryType.creditNote => AppColors.success,
  CustomerStatementEntryType.refund => AppColors.error,
};

Color _entryFill(CustomerStatementEntryType type) => switch (type) {
  CustomerStatementEntryType.invoice => AppColors.warningLight,
  CustomerStatementEntryType.payment => AppColors.successLight,
  CustomerStatementEntryType.reversal => AppColors.errorLight,
  CustomerStatementEntryType.creditNote => AppColors.successLight,
  CustomerStatementEntryType.refund => AppColors.errorLight,
};

IconData _entryIcon(CustomerStatementEntryType type) => switch (type) {
  CustomerStatementEntryType.invoice => Icons.receipt_long_outlined,
  CustomerStatementEntryType.payment => Icons.payments_outlined,
  CustomerStatementEntryType.reversal => Icons.undo_rounded,
  CustomerStatementEntryType.creditNote => Icons.assignment_return_outlined,
  CustomerStatementEntryType.refund => Icons.payments_outlined,
};

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

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _calendarDate(DateTime value) {
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
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}
