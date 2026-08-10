import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/discount_type.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/services/unit_service.dart';
import '../controllers/invoice_create_controller.dart';

class InvoiceCreateScreen extends GetView<InvoiceCreateController> {
  const InvoiceCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isQuotation ? 'New estimate' : 'New invoice'),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.save(draft: true),
              icon: const Icon(Icons.bookmark_border_rounded, size: 19),
              label: const Text('Draft'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE TOTAL',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyUtils.formatMinor(
                          controller.calculation.value?.grandTotalMinor ?? 0,
                          symbol: controller.currencySymbol.value,
                        ),
                        style: AppTextStyles.sectionTitle,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.preview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Review invoice'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final form = _InvoiceForm(controller: controller);
        final summary = _InvoiceSummary(controller: controller);
        if (ResponsiveUtils.isTablet(context)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 360, child: summary),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.horizontalPadding(context),
            vertical: 12,
          ),
          children: [form, const SizedBox(height: 16)],
        );
      }),
    );
  }
}

class _InvoiceForm extends StatelessWidget {
  const _InvoiceForm({required this.controller});
  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice details', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NUMBER',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            controller.invoiceNumber.value,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DateButton(
                      label: _date(controller.invoiceDate.value),
                      onTap: () => _pickDate(context, due: false),
                    ),
                  ],
                ),
                const Divider(height: 28),
                InkWell(
                  onTap: () => _pickDate(context, due: true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.dueDate.value == null
                                ? 'Add payment due date'
                                : 'Payment due ${_date(controller.dueDate.value!)}',
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionEyebrow(number: '1', label: 'Bill to'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => _selectCustomer(context),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              title: Text(controller.customer.value?.name ?? 'Select customer'),
              subtitle: controller.customer.value == null
                  ? const Text('Tap to choose billing customer')
                  : Text(
                      controller.customer.value?.companyName ??
                          controller.customer.value?.mobile ??
                          'Billing customer',
                    ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: _SectionEyebrow(number: '2', label: 'Items'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddItemOptions(context),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Add item'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.items.isEmpty)
            Material(
              color: AppColors.primaryLight.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => _showAddItemOptions(context),
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_shopping_cart_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 8),
                      Text('Add a product or service'),
                      SizedBox(height: 3),
                      Text(
                        'Choose a saved item or enter a custom one',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...controller.items.asMap().entries.map((entry) {
              final item = entry.value;
              final result = controller.calculation.value?.items[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _editItem(context, index: entry.key, item: item),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppTextStyles.cardTitle),
                            const SizedBox(height: 4),
                            Text(
                              '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit} × ${CurrencyUtils.formatMinor(item.rateMinor, symbol: controller.currencySymbol.value)} • GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (result != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                CurrencyUtils.formatMinor(
                                  result.totalMinor,
                                  symbol: controller.currencySymbol.value,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Item actions',
                        onSelected: (action) {
                          if (action == 'edit') {
                            _editItem(context, index: entry.key, item: item);
                          } else if (action == 'duplicate') {
                            controller.duplicateItem(entry.key);
                          } else if (action == 'delete') {
                            controller.removeItem(entry.key);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy_outlined),
                              title: Text('Duplicate'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              title: Text('Remove'),
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          if (!ResponsiveUtils.isTablet(context) &&
              controller.items.isNotEmpty) ...[
            _InvoiceSummary(controller: controller),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: controller.toggleMoreOptions,
            icon: Icon(
              controller.showMoreOptions.value
                  ? Icons.expand_less_rounded
                  : Icons.tune_rounded,
            ),
            label: Text(
              controller.showMoreOptions.value
                  ? 'Hide more options'
                  : 'Tax, discount & more',
            ),
          ),
          if (controller.showMoreOptions.value) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taxes & adjustments',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  AppDropdownField<TaxType>(
                    label: 'Tax mode',
                    sheetTitle: 'Choose tax mode',
                    prefixIcon: Icons.account_balance_outlined,
                    value: controller.taxType.value,
                    options: const [
                      AppDropdownOption(
                        value: TaxType.none,
                        label: 'No tax',
                        icon: Icons.money_off_csred_outlined,
                      ),
                      AppDropdownOption(
                        value: TaxType.cgstSgst,
                        label: 'CGST + SGST',
                        icon: Icons.call_split_rounded,
                      ),
                      AppDropdownOption(
                        value: TaxType.igst,
                        label: 'IGST',
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                    onChanged: controller.setTaxType,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invoice discount'),
                    subtitle: Text(
                      _discountLabel(
                        controller.invoiceDiscount.value,
                        controller.currencySymbol.value,
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editDiscount(context),
                  ),
                  ...controller.charges.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.title),
                      subtitle: Text(
                        CurrencyUtils.formatMinor(
                          entry.value.amountMinor,
                          symbol: controller.currencySymbol.value,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => controller.removeCharge(entry.key),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addCharge(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Additional charge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: controller.paidController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount paid'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.termsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Terms & conditions',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    if (!ResponsiveUtils.isTablet(context)) return content;
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
      child: content,
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: due
          ? (controller.dueDate.value ?? controller.invoiceDate.value)
          : controller.invoiceDate.value,
    );
    if (picked == null) return;
    if (due) {
      controller.dueDate.value = picked;
    } else {
      controller.invoiceDate.value = picked;
    }
  }

  Future<void> _selectCustomer(BuildContext context) async {
    final selected = await showModalBottomSheet<CustomerModel>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SelectionSheet<CustomerModel>(
        title: 'Select customer',
        future: controller.customers(),
        titleFor: (item) => item.name,
        subtitleFor: (item) => item.companyName ?? item.mobile ?? 'Customer',
        emptyTitle: 'No customers yet',
        emptyMessage: 'Create your first customer to add them to this invoice.',
        actionLabel: 'Create new customer',
        actionIcon: Icons.person_add_alt_1_rounded,
        onAction: () async =>
            await Get.toNamed<CustomerModel>(AppRoutes.customerAdd),
      ),
    );
    if (selected != null) controller.selectCustomer(selected);
  }

  Future<void> _selectProduct(BuildContext context) async {
    final selected = await showModalBottomSheet<ProductServiceModel>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SelectionSheet<ProductServiceModel>(
        title: 'Select saved item',
        future: controller.products(),
        titleFor: (item) => item.name,
        subtitleFor: (item) =>
            '${item.unit} • ${CurrencyUtils.formatMinor(item.salePriceMinor, symbol: controller.currencySymbol.value)}',
      ),
    );
    if (selected != null) controller.addProduct(selected);
  }

  Future<void> _showAddItemOptions(BuildContext context) async {
    final choice = await showModalBottomSheet<_AddItemChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add an item', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to add this invoice line.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _AddItemOption(
                icon: Icons.inventory_2_outlined,
                title: 'Choose saved item',
                subtitle: 'Use a product or service from your catalog',
                onTap: () => Navigator.pop(sheetContext, _AddItemChoice.saved),
              ),
              const SizedBox(height: 10),
              _AddItemOption(
                icon: Icons.edit_note_rounded,
                title: 'Create custom item',
                subtitle: 'Enter a one-time item for this invoice',
                onTap: () => Navigator.pop(sheetContext, _AddItemChoice.custom),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == _AddItemChoice.saved) {
      await _selectProduct(context);
    } else if (choice == _AddItemChoice.custom) {
      await _editItem(context);
    }
  }

  Future<void> _editItem(
    BuildContext context, {
    int? index,
    InvoiceItemModel? item,
  }) async {
    final result = await showModalBottomSheet<InvoiceItemModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ItemSheet(item: item),
    );
    if (result == null) return;
    if (index == null) {
      controller.addItem(result);
    } else {
      controller.replaceItem(index, result);
    }
  }

  Future<void> _editDiscount(BuildContext context) async {
    final result = await showDialog<DiscountInput>(
      context: context,
      builder: (_) =>
          _DiscountDialog(initial: controller.invoiceDiscount.value),
    );
    if (result != null) controller.setInvoiceDiscount(result);
  }

  Future<void> _addCharge(BuildContext context) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final result = await showDialog<InvoiceChargeModel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Additional charge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final minor = CurrencyUtils.parseMinor(amount.text);
              if (title.text.trim().isNotEmpty && minor != null) {
                Navigator.pop(
                  dialogContext,
                  InvoiceChargeModel(
                    title: title.text.trim(),
                    amountMinor: minor,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    title.dispose();
    amount.dispose();
    if (result != null) controller.addCharge(result);
  }
}

class _InvoiceSummary extends StatelessWidget {
  const _InvoiceSummary({required this.controller});
  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = controller.calculation.value;
      if (result == null) return const SizedBox.shrink();
      final symbol = controller.currencySymbol.value;
      final card = AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Live summary', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            _amountRow('Subtotal', result.subtotalMinor, symbol),
            if (result.itemDiscountTotalMinor > 0)
              _amountRow(
                'Item discounts',
                -result.itemDiscountTotalMinor,
                symbol,
              ),
            if (result.invoiceDiscountMinor > 0)
              _amountRow(
                'Invoice discount',
                -result.invoiceDiscountMinor,
                symbol,
              ),
            _amountRow('Taxable value', result.taxableTotalMinor, symbol),
            if (result.cgstMinor > 0)
              _amountRow('CGST', result.cgstMinor, symbol),
            if (result.sgstMinor > 0)
              _amountRow('SGST', result.sgstMinor, symbol),
            if (result.igstMinor > 0)
              _amountRow('IGST', result.igstMinor, symbol),
            if (result.additionalChargeTotalMinor > 0)
              _amountRow(
                'Additional charges',
                result.additionalChargeTotalMinor,
                symbol,
              ),
            if (result.roundOffMinor != 0)
              _amountRow('Round off', result.roundOffMinor, symbol),
            const Divider(height: 28),
            _amountRow(
              'Grand total',
              result.grandTotalMinor,
              symbol,
              prominent: true,
            ),
            _amountRow('Paid', result.paidAmountMinor, symbol),
            _amountRow(
              'Balance due',
              result.balanceDueMinor,
              symbol,
              prominent: true,
            ),
          ],
        ),
      );
      if (!ResponsiveUtils.isTablet(context)) return card;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            card,
            const SizedBox(height: 12),
            const Text('Values update as you edit the invoice.'),
          ],
        ),
      );
    });
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceMuted,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    ),
  );
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: AppTextStyles.small.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 9),
      Text(label, style: AppTextStyles.sectionTitle),
    ],
  );
}

enum _AddItemChoice { saved, custom }

class _AddItemOption extends StatelessWidget {
  const _AddItemOption({
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
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.future,
    required this.titleFor,
    required this.subtitleFor,
    this.emptyTitle = 'Nothing saved yet',
    this.emptyMessage,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });
  final String title;
  final Future<List<T>> future;
  final String Function(T) titleFor;
  final String Function(T) subtitleFor;
  final String emptyTitle;
  final String? emptyMessage;
  final String? actionLabel;
  final IconData? actionIcon;
  final Future<T?> Function()? onAction;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _runAction,
                      icon: Icon(
                        widget.actionIcon ?? Icons.add_rounded,
                        size: 20,
                      ),
                      label: Text(widget.actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<T>>(
                future: widget.future,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final normalized = query.trim().toLowerCase();
                  final items = snapshot.data!
                      .where(
                        (item) =>
                            normalized.isEmpty ||
                            widget
                                .titleFor(item)
                                .toLowerCase()
                                .contains(normalized) ||
                            widget
                                .subtitleFor(item)
                                .toLowerCase()
                                .contains(normalized),
                      )
                      .toList();
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.actionIcon ?? Icons.inventory_2_outlined,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.emptyTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardTitle,
                            ),
                            if (widget.emptyMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.emptyMessage!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            widget.titleFor(item).trim().isEmpty
                                ? '?'
                                : widget
                                      .titleFor(item)
                                      .characters
                                      .first
                                      .toUpperCase(),
                          ),
                        ),
                        title: Text(widget.titleFor(item)),
                        subtitle: Text(widget.subtitleFor(item)),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAction() async {
    final created = await widget.onAction?.call();
    if (created != null && mounted) {
      Navigator.pop(context, created);
    }
  }
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.item});
  final InvoiceItemModel? item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController name;
  late final TextEditingController quantity;
  late String unit;
  late final TextEditingController rate;
  late final TextEditingController hsn;
  late final TextEditingController tax;
  late final TextEditingController discount;
  late DiscountType discountType;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    name = TextEditingController(text: item?.name ?? '');
    quantity = TextEditingController(
      text: QuantityUtils.toInputValue(item?.quantityScaled ?? 1000),
    );
    unit = item?.unit ?? 'pcs';
    rate = TextEditingController(
      text: CurrencyUtils.toInputValue(item?.rateMinor ?? 0),
    );
    hsn = TextEditingController(text: item?.hsnSac ?? '');
    tax = TextEditingController(
      text: TaxUtils.toInputValue(item?.taxRateBasisPoints ?? 0),
    );
    discountType = item?.discount.type ?? DiscountType.none;
    discount = TextEditingController(
      text: discountType == DiscountType.fixed
          ? CurrencyUtils.toInputValue(item!.discount.fixedMinor)
          : TaxUtils.toInputValue(item?.discount.percentageBasisPoints ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item == null ? 'Create custom item' : 'Edit item',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 5),
            Text(
              'Add the line-item details shown on this invoice.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                hintText: 'e.g. Website design',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantity *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppUnitField(
                    value: unit,
                    unitService: Get.find<UnitService>(),
                    onChanged: (value) => setState(() => unit = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Rate *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hsn,
                    decoration: const InputDecoration(labelText: 'HSN/SAC'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: tax,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'GST %'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppDropdownField<DiscountType>(
              label: 'Discount',
              sheetTitle: 'Choose item discount',
              prefixIcon: Icons.discount_outlined,
              value: discountType,
              options: const [
                AppDropdownOption(
                  value: DiscountType.none,
                  label: 'No discount',
                ),
                AppDropdownOption(
                  value: DiscountType.percentage,
                  label: 'Percentage',
                ),
                AppDropdownOption(
                  value: DiscountType.fixed,
                  label: 'Fixed amount',
                ),
              ],
              onChanged: (value) => setState(() => discountType = value),
            ),
            if (discountType != DiscountType.none) ...[
              const SizedBox(height: 12),
              TextField(
                controller: discount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: discountType == DiscountType.fixed
                      ? 'Discount amount'
                      : 'Discount %',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(widget.item == null ? 'Add item' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    rate.dispose();
    hsn.dispose();
    tax.dispose();
    discount.dispose();
    super.dispose();
  }

  void _submit() {
    final quantityValue = QuantityUtils.parseScaled(quantity.text);
    final rateValue = CurrencyUtils.parseMinor(rate.text);
    final taxValue = TaxUtils.parseBasisPoints(tax.text);
    if (name.text.trim().isEmpty ||
        unit.trim().isEmpty ||
        quantityValue == null ||
        quantityValue <= 0 ||
        rateValue == null ||
        rateValue <= 0 ||
        taxValue == null) {
      AppNotification.warning(
        'Check item details',
        'Enter a name, unit, valid GST, and quantity/rate above zero.',
      );
      return;
    }
    final discountValue = switch (discountType) {
      DiscountType.none => const DiscountInput.none(),
      DiscountType.fixed => DiscountInput.fixed(
        CurrencyUtils.parseMinor(discount.text) ?? 0,
      ),
      DiscountType.percentage => DiscountInput.percentage(
        TaxUtils.parseBasisPoints(discount.text) ?? 0,
      ),
    };
    Navigator.pop(
      context,
      InvoiceItemModel(
        localId:
            widget.item?.localId ??
            'custom-${DateTime.now().microsecondsSinceEpoch}',
        id: widget.item?.id,
        productId: widget.item?.productId,
        name: name.text.trim(),
        description: widget.item?.description,
        quantityScaled: quantityValue,
        unit: unit.trim(),
        rateMinor: rateValue,
        hsnSac: hsn.text.trim().isEmpty ? null : hsn.text.trim(),
        taxRateBasisPoints: taxValue,
        discount: discountValue,
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({required this.initial});
  final DiscountInput initial;
  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late DiscountType type = widget.initial.type;
  late final value = TextEditingController(
    text: type == DiscountType.fixed
        ? CurrencyUtils.toInputValue(widget.initial.fixedMinor)
        : TaxUtils.toInputValue(widget.initial.percentageBasisPoints),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Invoice discount'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDropdownField<DiscountType>(
          label: 'Discount type',
          sheetTitle: 'Choose invoice discount',
          value: type,
          options: const [
            AppDropdownOption(value: DiscountType.none, label: 'No discount'),
            AppDropdownOption(
              value: DiscountType.percentage,
              label: 'Percentage',
            ),
            AppDropdownOption(value: DiscountType.fixed, label: 'Fixed amount'),
          ],
          onChanged: (selected) => setState(() => type = selected),
        ),
        if (type != DiscountType.none) ...[
          const SizedBox(height: 12),
          TextField(
            controller: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: type == DiscountType.fixed ? 'Amount' : 'Percentage',
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, switch (type) {
          DiscountType.none => const DiscountInput.none(),
          DiscountType.fixed => DiscountInput.fixed(
            CurrencyUtils.parseMinor(value.text) ?? 0,
          ),
          DiscountType.percentage => DiscountInput.percentage(
            TaxUtils.parseBasisPoints(value.text) ?? 0,
          ),
        }),
        child: const Text('Apply'),
      ),
    ],
  );
}

Widget _amountRow(
  String label,
  int amount,
  String symbol, {
  bool prominent = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: [
      Expanded(
        child: Text(label, style: prominent ? AppTextStyles.cardTitle : null),
      ),
      Text(
        CurrencyUtils.formatMinor(amount, symbol: symbol),
        style: prominent ? AppTextStyles.cardTitle : null,
      ),
    ],
  ),
);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _discountLabel(DiscountInput discount, String symbol) =>
    switch (discount.type) {
      DiscountType.none => 'No discount',
      DiscountType.fixed => CurrencyUtils.formatMinor(
        discount.fixedMinor,
        symbol: symbol,
      ),
      DiscountType.percentage => TaxUtils.formatBasisPoints(
        discount.percentageBasisPoints,
      ),
    };
