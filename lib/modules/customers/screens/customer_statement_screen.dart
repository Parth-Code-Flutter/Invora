import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/models/customer_statement_model.dart';
import '../controllers/customer_statement_controller.dart';

class CustomerStatementScreen extends GetView<CustomerStatementController> {
  const CustomerStatementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Customer statement'),
      actions: [
        IconButton(
          onPressed: controller.save,
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Save PDF',
        ),
        IconButton(
          onPressed: controller.share,
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share PDF',
        ),
        IconButton(
          onPressed: controller.print,
          icon: const Icon(Icons.print_outlined),
          tooltip: 'Print',
        ),
      ],
    ),
    body: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final statement = controller.statement.value;
      if (statement == null) {
        return const Center(child: Text('Statement is unavailable.'));
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _StatementHero(statement: statement),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  value: statement.from,
                  onTap: () =>
                      _pick(context, statement.from, controller.setFrom),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  value: statement.to,
                  onTap: () => _pick(context, statement.to, controller.setTo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Account activity',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Text(
                '${statement.entries.length} entries',
                style: AppTextStyles.small,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (statement.entries.isEmpty)
            const AppCard(
              child: Text('No account activity in this date range.'),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (final entry in statement.entries)
                    _StatementEntryTile(
                      entry: entry,
                      symbol: statement.business.currencySymbol,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _preview(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview statement PDF'),
          ),
        ],
      );
    }),
  );

  Future<void> _pick(
    BuildContext context,
    DateTime initial,
    ValueChanged<DateTime> onChanged,
  ) async {
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value != null) onChanged(value);
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
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUSTOMER ACCOUNT',
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
        Text(
          statement.customer.name,
          style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _metric('Opening', statement.openingBalanceMinor),
            _metric('Invoiced', statement.totalInvoicedMinor),
            _metric('Received', statement.totalReceivedMinor),
            _metric('Closing', statement.closingBalanceMinor),
          ],
        ),
      ],
    ),
  );
  Widget _metric(String label, int value) => Expanded(
    child: Column(
      children: [
        Text(
          CurrencyUtils.formatMinor(
            value,
            symbol: statement.business.currencySymbol,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.calendar_month_outlined),
    label: Text('$label ${_date(value)}'),
  );
}

class _StatementEntryTile extends StatelessWidget {
  const _StatementEntryTile({required this.entry, required this.symbol});
  final CustomerStatementEntry entry;
  final String symbol;
  @override
  Widget build(BuildContext context) {
    final invoice =
        entry.type == CustomerStatementEntryType.invoice ||
        entry.type == CustomerStatementEntryType.reversal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (invoice ? AppColors.warning : AppColors.success)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              invoice ? Icons.receipt_long_outlined : Icons.payments_outlined,
              color: invoice ? AppColors.warning : AppColors.success,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
                Text(
                  '${_date(entry.date)} · ${entry.reference}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatMinor(
                  entry.debitMinor > 0 ? entry.debitMinor : entry.creditMinor,
                  symbol: symbol,
                ),
                style: AppTextStyles.cardTitle.copyWith(
                  color: invoice ? AppColors.warning : AppColors.success,
                ),
              ),
              Text(
                'Bal ${CurrencyUtils.formatMinor(entry.balanceMinor, symbol: symbol)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
