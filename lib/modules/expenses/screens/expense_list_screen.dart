import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';

class ExpenseListScreen extends GetView<ExpenseListController> {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Expenses'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Add expense'),
            onPressed: controller.openCreate,
            icon: Icons.add_rounded,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreate,
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        final rows = controller.visible;
        final symbol = '₹';
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: controller.search,
                      decoration: const InputDecoration(
                        hintText: 'Search payee, category or number',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFilterChip(
                      label: 'This month',
                      selected: controller.thisMonthOnly.value,
                      onSelected: controller.toggleThisMonth,
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'This month',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          AppAmountText(
                            amountMinor: controller.monthTotalMinor,
                            symbol: symbol,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simple expenses stay separate from supplier bills.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    illustration: AppEmptyIllustration.coins,
                    title: 'No expenses yet',
                    message:
                        'Record rent, fuel, salary and other cash spends here. Supplier item bills stay in Purchases.',
                    actionLabel: 'Add expense',
                    onAction: controller.openCreate,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = rows[index];
                      return AppGroupedTile(
                        position: AppGroupedPositionX.resolve(
                          index,
                          rows.length,
                        ),
                        onTap: () => controller.openDetails(item),
                        child: _ExpenseRow(item: item, symbol: symbol),
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
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.item, required this.symbol});
  final ExpenseSummaryModel item;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final date =
        '${item.expenseDate.day.toString().padLeft(2, '0')}/${item.expenseDate.month.toString().padLeft(2, '0')}/${item.expenseDate.year}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.payee, style: AppTextStyles.listName),
              const SizedBox(height: 2),
              Text(
                '${item.category}  ·  $date  ·  ${item.expenseNumber}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.isCancelled)
                Text(
                  'Cancelled',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
            ],
          ),
        ),
        AppAmountText(
          amountMinor: item.grandTotalMinor,
          symbol: symbol,
          color: item.isCancelled ? AppColors.textTertiary : null,
        ),
      ],
    );
  }
}

class ExpenseFormScreen extends GetView<ExpenseFormController> {
  const ExpenseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return UnsavedChangesScope(
        hasChanges: () => controller.dirty.value,
        onSaveDraft: () => controller.save(pop: false),
        child: Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: AppBarTitle(
              controller.isEditing ? 'Edit expense' : 'Add expense',
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: AppConstrainedAction(
                maxWidth: ResponsiveUtils.footerMaxWidth(context),
                child: AppButton(
                  label: controller.isEditing ? 'Update' : 'Save expense',
                  isLoading: controller.isSaving.value,
                  onPressed: controller.save,
                ),
              ),
            ),
          ),
          body: ResponsiveContent(
            tabletMaxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: controller.date.value,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) controller.setDate(selected);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${controller.date.value.day.toString().padLeft(2, '0')}/${controller.date.value.month.toString().padLeft(2, '0')}/${controller.date.value.year}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<String>(
                        label: 'Category',
                        sheetTitle: 'Choose category',
                        value: controller.category.value,
                        options: [
                          for (final value in ExpenseMath.categories)
                            AppDropdownOption(value: value, label: value),
                        ],
                        onChanged: controller.setCategory,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: controller.payee,
                        label: 'Paid to',
                        hint: 'Landlord, fuel pump, staff…',
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: controller.amount,
                        label: 'Amount paid',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<int>(
                        label: 'GST on this amount',
                        sheetTitle: 'GST rate',
                        value: controller.taxRateBasisPoints.value,
                        options: [
                          for (final rate in TaxUtils.gstRateBasisPoints)
                            AppDropdownOption(
                              value: rate,
                              label: rate == 0
                                  ? 'No GST'
                                  : TaxUtils.formatBasisPoints(rate),
                            ),
                        ],
                        onChanged: controller.setTaxRate,
                      ),
                      if (controller.taxRateBasisPoints.value > 0) ...[
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Claim ITC'),
                          subtitle: const Text(
                            'Mark if this GST can be claimed as input credit',
                          ),
                          value: controller.itcEligible.value,
                          onChanged: controller.setItc,
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppDropdownField<String>(
                        label: 'Paid by',
                        sheetTitle: 'Payment method',
                        value: controller.paymentMethod.value,
                        options: [
                          for (final value in ExpenseMath.paymentMethods)
                            AppDropdownOption(value: value, label: value),
                        ],
                        onChanged: controller.setPaymentMethod,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: controller.notes,
                        label: 'Note',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      _SplitLine(
                        label: 'Taxable',
                        amountMinor: controller.split.taxableMinor,
                      ),
                      _SplitLine(
                        label: 'GST',
                        amountMinor: controller.split.taxMinor,
                      ),
                      _SplitLine(
                        label: 'Total paid',
                        amountMinor: controller.split.grandTotalMinor,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SplitLine extends StatelessWidget {
  const _SplitLine({
    required this.label,
    required this.amountMinor,
    this.bold = false,
  });
  final String label;
  final int amountMinor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold ? AppTextStyles.listName : AppTextStyles.body,
            ),
          ),
          AppAmountText(
            amountMinor: amountMinor,
            symbol: '₹',
            style: bold ? AppTextStyles.listAmount : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
