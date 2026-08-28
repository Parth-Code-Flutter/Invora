import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/debit_note_model.dart';
import '../controllers/debit_note_create_controller.dart';

class DebitNoteCreateScreen extends GetView<DebitNoteCreateController> {
  const DebitNoteCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Debit note', subtitle: 'Purchase return'),
      ),
      bottomNavigationBar: Obx(() {
        final symbol = '₹';
        return SafeArea(
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBIT TOTAL',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppAmountText(
                          amountMinor: controller.previewTotalMinor.value,
                          symbol: symbol,
                          textAlign: TextAlign.start,
                          style: AppTextStyles.listAmount.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width * .52)
                        .clamp(188.0, 260.0)
                        .toDouble(),
                    child: AppButton(
                      label: 'Issue debit note',
                      icon: Icons.assignment_return_outlined,
                      isLoading: controller.isWorking.value,
                      onPressed: controller.isWorking.value
                          ? null
                          : controller.submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      body: Obx(() {
        final bill = controller.bill.value;
        if (bill == null) {
          return const Center(child: CircularProgressIndicator());
        }
        const symbol = '₹';
        return ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Against bill',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(bill.billNumber, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            bill.supplierName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppAmountColumn(
                      maxWidth: 108,
                      children: [
                        Text(
                          'Outstanding',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppAmountText(
                          amountMinor: bill.balanceMinor,
                          symbol: symbol,
                          color: bill.balanceMinor > 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What is being returned?',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Returned items')),
                    ButtonSegment(value: true, label: Text('Value adjustment')),
                  ],
                  selected: {controller.isValueAdjustment.value},
                  onSelectionChanged: (selected) =>
                      controller.setValueAdjustment(selected.first),
                ),
              ),
              const SizedBox(height: 12),
              if (controller.isValueAdjustment.value)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: controller.adjustmentController,
                        label: 'Debit amount',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => controller.recalculate(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uses this bill’s tax treatment.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < controller.lines.length;
                        index++
                      ) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        _ReturnLine(
                          draft: controller.lines[index],
                          symbol: symbol,
                          creditMinor: controller.linePreviewMinor(
                            controller.lines[index],
                          ),
                          onStep: (direction) =>
                              controller.stepReturnedQuantity(index, direction),
                          onEdit: () => _editQuantity(context, index),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text('Return details', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _DateField(
                      label: 'Return date',
                      value: _date(controller.pickerInitialDate),
                      onTap: () => _pickDate(context),
                    ),
                    const SizedBox(height: 12),
                    AppDropdownField<String>(
                      label: 'Reason',
                      sheetTitle: 'Why is this being returned?',
                      prefixIcon: Icons.assignment_outlined,
                      value: controller.reasonChoice.value,
                      options: [
                        for (final reason
                            in DebitNoteCreateController.reasonPresets)
                          AppDropdownOption(value: reason, label: reason),
                      ],
                      onChanged: controller.setReasonChoice,
                    ),
                    if (controller.isOtherReason) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: controller.reasonController,
                        label: 'Describe the reason',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ],
                ),
              ),
              if (controller.leftoverMinor > 0) ...[
                const SizedBox(height: 16),
                Text('Remainder', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                AppCard(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.warningLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This debit is more than the bill outstanding. Choose what to do with the remainder.',
                        style: AppTextStyles.secondaryBody,
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<DebitNoteRemainderAction>(
                        label: 'Remainder',
                        value: controller.remainder.value,
                        options: const [
                          AppDropdownOption(
                            value: DebitNoteRemainderAction.applyThenKeep,
                            label: 'Keep as supplier credit',
                          ),
                          AppDropdownOption(
                            value: DebitNoteRemainderAction.applyThenRefund,
                            label: 'Record refund received',
                          ),
                        ],
                        onChanged: (value) =>
                            controller.remainder.value = value,
                      ),
                      if (controller.remainder.value ==
                          DebitNoteRemainderAction.applyThenRefund) ...[
                        const SizedBox(height: 12),
                        AppDropdownField<String>(
                          label: 'Refund method',
                          value: controller.refundMethod.value,
                          options: const [
                            AppDropdownOption(value: 'UPI', label: 'UPI'),
                            AppDropdownOption(value: 'Cash', label: 'Cash'),
                            AppDropdownOption(
                              value: 'Bank transfer',
                              label: 'Bank transfer',
                            ),
                            AppDropdownOption(value: 'Card', label: 'Card'),
                          ],
                          onChanged: (value) =>
                              controller.refundMethod.value = value,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final range = controller.pickerBounds;
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.pickerInitialDate,
      firstDate: range.$1,
      lastDate: range.$2,
    );
    if (picked != null) controller.setReturnDate(picked);
  }

  Future<void> _editQuantity(BuildContext context, int index) async {
    final draft = controller.lines[index];
    final quantity = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReturnQuantitySheet(draft: draft),
    );
    if (quantity != null) {
      controller.setReturnedQuantity(index, quantity);
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isFocused: false,
        isEmpty: false,
        decoration: InputDecoration(
          labelText: l10n(label),
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(value, style: AppTextStyles.body),
      ),
    );
  }
}

class _ReturnLine extends StatelessWidget {
  const _ReturnLine({
    required this.draft,
    required this.symbol,
    required this.creditMinor,
    required this.onStep,
    required this.onEdit,
  });

  final DebitNoteItemDraft draft;
  final String symbol;
  final int creditMinor;
  final ValueChanged<int> onStep;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final remaining = QuantityUtils.toInputValue(draft.remainingScaled);
    final original = QuantityUtils.toInputValue(draft.originalQuantityScaled);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.purchaseItem.name,
                      style: AppTextStyles.listName.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$original ${draft.purchaseItem.unit} · ${CurrencyUtils.formatMinor(draft.purchaseItem.rateMinor, symbol: symbol)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Returnable $remaining ${draft.purchaseItem.unit}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppAmountColumn(
                maxWidth: 96,
                children: [
                  AppAmountText(
                    amountMinor: creditMinor,
                    symbol: symbol,
                    color: creditMinor > 0
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _QuantityStepper(
            value: QuantityUtils.toInputValue(draft.returnedQuantityScaled),
            canIncrease: draft.returnedQuantityScaled < draft.remainingScaled,
            canDecrease: draft.returnedQuantityScaled > 0,
            onDecrease: () => onStep(-1),
            onIncrease: () => onStep(1),
            onEdit: onEdit,
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.canIncrease,
    required this.canDecrease,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
  });

  final String value;
  final bool canIncrease;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: canDecrease ? onDecrease : null,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, size: 17),
          ),
          Container(width: 1, height: 22, color: AppColors.border),
          Tooltip(
            message: 'Enter quantity',
            child: InkWell(
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 22, color: AppColors.border),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: canIncrease ? onIncrease : null,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _ReturnQuantitySheet extends StatefulWidget {
  const _ReturnQuantitySheet({required this.draft});

  final DebitNoteItemDraft draft;

  @override
  State<_ReturnQuantitySheet> createState() => _ReturnQuantitySheetState();
}

class _ReturnQuantitySheetState extends State<_ReturnQuantitySheet> {
  late final TextEditingController _input = TextEditingController(
    text: widget.draft.returnedQuantityScaled == 0
        ? ''
        : QuantityUtils.toInputValue(widget.draft.returnedQuantityScaled),
  );
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = QuantityUtils.toInputValue(widget.draft.remainingScaled);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Return quantity', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Up to $remaining ${widget.draft.purchaseItem.unit}',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _input,
            label: 'Quantity',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: 'Update quantity',
            onPressed: () {
              final parsed = QuantityUtils.parseScaled(_input.text);
              if (parsed == null || parsed < 0) {
                setState(() => _error = 'Enter a valid quantity.');
                return;
              }
              if (parsed > widget.draft.remainingScaled) {
                setState(
                  () => _error =
                      'Cannot return more than $remaining ${widget.draft.purchaseItem.unit}.',
                );
                return;
              }
              Navigator.pop(context, parsed);
            },
          ),
        ],
      ),
    );
  }
}
