import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/expense_controller.dart';

class ExpenseDetailsScreen extends GetView<ExpenseDetailsController> {
  const ExpenseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expense = controller.expense.value;
      if (expense == null) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const AppBarTitle('Expense'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final symbol = controller.currencySymbol.value;
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: AppBarTitle(expense.expenseNumber),
          actions: [
            AppBarIconButton(
              tooltip: l10n('Share'),
              onPressed: controller.share,
              icon: Icons.ios_share_rounded,
            ),
          ],
        ),
        body: ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.isCancelled ? 'Cancelled' : 'Recorded',
                      style: AppTextStyles.caption.copyWith(
                        color: expense.isCancelled
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(expense.payee, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category}  ·  ${_date(expense.expenseDate)}',
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: AppAmountText(
                        amountMinor: expense.grandTotalMinor,
                        symbol: symbol,
                        hero: true,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _Line(label: 'Paid by', value: expense.paymentMethod),
                    _Line(
                      label: 'Taxable',
                      value: null,
                      amountMinor: expense.taxableMinor,
                      symbol: symbol,
                    ),
                    if (expense.taxMinor > 0)
                      _Line(
                        label:
                            'GST ${TaxUtils.formatBasisPoints(expense.taxRateBasisPoints)}',
                        value: expense.itcEligible ? 'ITC eligible' : null,
                        amountMinor: expense.taxMinor,
                        symbol: symbol,
                      ),
                    if (expense.notes != null &&
                        expense.notes!.trim().isNotEmpty)
                      _Line(label: 'Note', value: expense.notes),
                    if (expense.isCancelled)
                      _Line(
                        label: 'Cancelled',
                        value: expense.cancellationReason,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!expense.isCancelled) ...[
                AppButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: controller.openEdit,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _cancel(context),
                  child: const Text('Cancel expense'),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton(
                onPressed: controller.printPdf,
                child: const Text('Print PDF'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: controller.savePdf,
                child: const Text('Save PDF'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this expense?'),
        content: AppTextField(
          controller: reason,
          label: 'Reason',
          hint: 'Entered twice, personal spend…',
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel expense'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancel(reason.text);
    }
    reason.dispose();
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _Line extends StatelessWidget {
  const _Line({required this.label, this.value, this.amountMinor, this.symbol});
  final String label;
  final String? value;
  final int? amountMinor;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (value != null && value!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(value!),
                ],
              ],
            ),
          ),
          if (amountMinor != null)
            AppAmountText(amountMinor: amountMinor!, symbol: symbol ?? '₹'),
        ],
      ),
    );
  }
}
