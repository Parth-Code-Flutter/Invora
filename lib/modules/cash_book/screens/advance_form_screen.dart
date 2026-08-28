import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/cash_book_models.dart';
import '../controllers/cash_book_controller.dart';
import '../widgets/cash_book_visuals.dart';

class AdvanceFormScreen extends GetView<AdvanceFormController> {
  const AdvanceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Advances'),
      ),
      body: Obx(() {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                color: isDark ? const Color(0xFF3B2038) : Colors.white,
                borderColor: isDark
                    ? AppColors.darkBorder
                    : const Color(0xFFE9DFF0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          CashBookIconWell(
                            icon: Icons.savings_outlined,
                            tint: AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record an advance',
                                  style: AppTextStyles.listName.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Money moves once. Apply leftover later.',
                                  style: AppTextStyles.small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              AppFilterChip(
                                label: 'Customer',
                                icon: Icons.person_outline_rounded,
                                selected:
                                    controller.partyType.value ==
                                    PartyKind.customer,
                                onSelected: (_) => controller.selectPartyType(
                                  PartyKind.customer,
                                ),
                              ),
                              AppFilterChip(
                                label: 'Supplier',
                                icon: Icons.storefront_outlined,
                                selected:
                                    controller.partyType.value ==
                                    PartyKind.supplier,
                                onSelected: (_) => controller.selectPartyType(
                                  PartyKind.supplier,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (controller.partyType.value ==
                                  PartyKind.customer &&
                              controller.customers.isNotEmpty)
                            AppDropdownField<int>(
                              label: 'Customer',
                              sheetTitle: 'Choose customer',
                              searchable: true,
                              value:
                                  controller.partyId.value ??
                                  controller.customers.first.id!,
                              options: [
                                for (final customer in controller.customers)
                                  if (customer.id != null)
                                    AppDropdownOption(
                                      value: customer.id!,
                                      label: customer.name,
                                    ),
                              ],
                              onChanged: (value) {
                                final customer = controller.customers
                                    .where((item) => item.id == value)
                                    .firstOrNull;
                                if (customer?.id != null) {
                                  controller.selectParty(
                                    id: customer!.id!,
                                    name: customer.name,
                                  );
                                }
                              },
                            )
                          else if (controller.partyType.value ==
                                  PartyKind.supplier &&
                              controller.suppliers.isNotEmpty)
                            AppDropdownField<int>(
                              label: 'Supplier',
                              sheetTitle: 'Choose supplier',
                              searchable: true,
                              value:
                                  controller.partyId.value ??
                                  controller.suppliers.first.id!,
                              options: [
                                for (final supplier in controller.suppliers)
                                  if (supplier.id != null)
                                    AppDropdownOption(
                                      value: supplier.id!,
                                      label: supplier.name,
                                    ),
                              ],
                              onChanged: (value) {
                                final supplier = controller.suppliers
                                    .where((item) => item.id == value)
                                    .firstOrNull;
                                if (supplier?.id != null) {
                                  controller.selectParty(
                                    id: supplier!.id!,
                                    name: supplier.name,
                                  );
                                }
                              },
                            )
                          else
                            Text(
                              controller.partyType.value == PartyKind.customer
                                  ? 'Add a customer first.'
                                  : 'Add a supplier first.',
                              style: AppTextStyles.caption,
                            ),
                          const SizedBox(height: 10),
                          if (controller.accounts.isNotEmpty)
                            AppDropdownField<int>(
                              label: 'Account',
                              value:
                                  controller.accountId.value ??
                                  controller.accounts.first.id!,
                              options: [
                                for (final account in controller.accounts)
                                  AppDropdownOption(
                                    value: account.id!,
                                    label: account.name,
                                    icon: account.accountType.icon,
                                  ),
                              ],
                              onChanged: (value) =>
                                  controller.accountId.value = value,
                            ),
                          const SizedBox(height: 10),
                          AppDropdownField<String>(
                            label: 'Received / paid by',
                            value: controller.method.value,
                            options: const [
                              AppDropdownOption(value: 'UPI', label: 'UPI'),
                              AppDropdownOption(value: 'Cash', label: 'Cash'),
                              AppDropdownOption(
                                value: 'Bank transfer',
                                label: 'Bank transfer',
                              ),
                              AppDropdownOption(
                                value: 'Cheque',
                                label: 'Cheque',
                              ),
                              AppDropdownOption(value: 'Card', label: 'Card'),
                              AppDropdownOption(value: 'Other', label: 'Other'),
                            ],
                            onChanged: (value) =>
                                controller.method.value = value,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller.amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller.note,
                            decoration: const InputDecoration(
                              labelText: 'Note (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Save advance',
                            icon: Icons.check_rounded,
                            isLoading: controller.isSaving.value,
                            onPressed: () async {
                              final error = await controller.saveAdvance();
                              if (error != null) {
                                AppNotification.error(
                                  'Cannot save advance',
                                  error,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: EdgeInsets.zero,
                color: isDark ? const Color(0xFF3B2038) : Colors.white,
                borderColor: isDark
                    ? AppColors.darkBorder
                    : const Color(0xFFE9DFF0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          CashBookIconWell(
                            icon: Icons.assignment_turned_in_outlined,
                            tint: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apply leftover',
                                  style: AppTextStyles.listName.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cash already moved when the advance was recorded. Applying it only reduces the invoice or bill.',
                                  style: AppTextStyles.small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.openAdvances.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'No open advances for this party.',
                          style: AppTextStyles.caption,
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppDropdownField<int>(
                              label: 'Open advance',
                              value: controller.selectedAdvanceId.value!,
                              options: [
                                for (final advance in controller.openAdvances)
                                  AppDropdownOption(
                                    value: advance.id,
                                    label:
                                        '${advance.partyName} · ${CurrencyUtils.formatMinor(advance.remainingMinor, symbol: '₹')}',
                                  ),
                              ],
                              onChanged: (value) {
                                controller.selectedAdvanceId.value = value;
                                controller.loadAllocatable();
                              },
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () async {
                                  final error = await controller.refund(
                                    'Refund leftover',
                                  );
                                  if (error != null) {
                                    AppNotification.error(
                                      'Cannot refund advance',
                                      error,
                                    );
                                  }
                                },
                                child: const Text('Refund remaining'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.allocatable.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            'No unpaid invoices or bills for this party.',
                            style: AppTextStyles.caption,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              for (final (index, document)
                                  in controller.allocatable.indexed)
                                AppGroupedTile(
                                  position: AppGroupedPositionX.resolve(
                                    index,
                                    controller.allocatable.length,
                                  ),
                                  child: _AllocatableRow(
                                    document: document,
                                    onApply: () => _apply(document),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _apply(AllocatableDocument document) async {
    final advance = controller.openAdvances
        .where((item) => item.id == controller.selectedAdvanceId.value)
        .firstOrNull;
    if (advance == null) return;
    final apply = advance.remainingMinor < document.balanceMinor
        ? advance.remainingMinor
        : document.balanceMinor;
    final error = await controller.allocate(
      documentId: document.id,
      amountInput: CurrencyUtils.toInputValue(apply),
    );
    if (error != null) {
      AppNotification.error('Cannot apply advance', error);
    }
  }
}

class _AllocatableRow extends StatelessWidget {
  const _AllocatableRow({required this.document, required this.onApply});

  final AllocatableDocument document;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Row(
      children: [
        CashBookIconWell(
          icon: Icons.receipt_long_outlined,
          tint: AppColors.secondary,
          size: 38,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              const SizedBox(height: 2),
              Text(
                'Due ${CurrencyUtils.formatMinor(document.balanceMinor, symbol: '₹')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CashBookActionPill(
          label: 'Apply',
          color: AppColors.accent,
          onTap: onApply,
        ),
      ],
    );
  }
}
