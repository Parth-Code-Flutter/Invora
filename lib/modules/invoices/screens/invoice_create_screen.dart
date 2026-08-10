import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/discount_type.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../controllers/invoice_create_controller.dart';

class InvoiceCreateScreen extends GetView<InvoiceCreateController> {
  const InvoiceCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isQuotation ? 'Create quotation' : 'Create invoice',
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.save(draft: true),
              child: const Text('Save draft'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total'),
                      Text(
                        CurrencyUtils.formatMinor(
                          controller.calculation.value?.grandTotalMinor ?? 0,
                          symbol: controller.currencySymbol.value,
                        ),
                        style: AppTextStyles.cardTitle,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.preview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice details', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                Text(
                  controller.invoiceNumber.value,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                      ),
                      label: Text(
                        'Date: ${_date(controller.invoiceDate.value)}',
                      ),
                      onPressed: () => _pickDate(context, due: false),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        controller.dueDate.value == null
                            ? 'Add due date'
                            : 'Due: ${_date(controller.dueDate.value!)}',
                      ),
                      onPressed: () => _pickDate(context, due: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => _selectCustomer(context),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(controller.customer.value?.name ?? 'Select customer'),
              subtitle: controller.customer.value == null
                  ? const Text('Customer billing details are snapshotted')
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
              Expanded(child: Text('Items', style: AppTextStyles.sectionTitle)),
              TextButton.icon(
                onPressed: () => _selectProduct(context),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Saved item'),
              ),
              IconButton(
                tooltip: 'Custom item',
                onPressed: () => _editItem(context),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (controller.items.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('No items yet. Add a saved or custom item.'),
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
                      IconButton(
                        onPressed: () => controller.removeItem(entry.key),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          if (!ResponsiveUtils.isTablet(context)) ...[
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
                  DropdownButtonFormField<TaxType>(
                    initialValue: controller.taxType.value,
                    decoration: const InputDecoration(labelText: 'Tax mode'),
                    items: const [
                      DropdownMenuItem(
                        value: TaxType.none,
                        child: Text('No tax'),
                      ),
                      DropdownMenuItem(
                        value: TaxType.cgstSgst,
                        child: Text('CGST + SGST'),
                      ),
                      DropdownMenuItem(
                        value: TaxType.igst,
                        child: Text('IGST'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setTaxType(value);
                    },
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

  Future<void> _editItem(
    BuildContext context, {
    int? index,
    InvoiceItemModel? item,
  }) async {
    final result = await showDialog<InvoiceItemModel>(
      context: context,
      builder: (_) => _ItemDialog(item: item),
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

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.future,
    required this.titleFor,
    required this.subtitleFor,
  });
  final String title;
  final Future<List<T>> future;
  final String Function(T) titleFor;
  final String Function(T) subtitleFor;

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
                    return const Center(child: Text('Nothing saved yet.'));
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
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({this.item});
  final InvoiceItemModel? item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController name;
  late final TextEditingController quantity;
  late final TextEditingController unit;
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
    unit = TextEditingController(text: item?.unit ?? 'pcs');
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
    return AlertDialog(
      title: Text(widget.item == null ? 'Custom item' : 'Edit item'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Rate'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hsn,
                      decoration: const InputDecoration(labelText: 'HSN/SAC'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<DiscountType>(
                initialValue: discountType,
                decoration: const InputDecoration(labelText: 'Discount type'),
                items: const [
                  DropdownMenuItem(
                    value: DiscountType.none,
                    child: Text('None'),
                  ),
                  DropdownMenuItem(
                    value: DiscountType.percentage,
                    child: Text('Percentage'),
                  ),
                  DropdownMenuItem(
                    value: DiscountType.fixed,
                    child: Text('Fixed amount'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => discountType = value ?? DiscountType.none),
              ),
              if (discountType != DiscountType.none) ...[
                const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    final quantityValue = QuantityUtils.parseScaled(quantity.text);
    final rateValue = CurrencyUtils.parseMinor(rate.text);
    final taxValue = TaxUtils.parseBasisPoints(tax.text);
    if (name.text.trim().isEmpty ||
        unit.text.trim().isEmpty ||
        quantityValue == null ||
        quantityValue <= 0 ||
        rateValue == null ||
        taxValue == null) {
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
        unit: unit.text.trim(),
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
        DropdownButtonFormField<DiscountType>(
          initialValue: type,
          items: const [
            DropdownMenuItem(value: DiscountType.none, child: Text('None')),
            DropdownMenuItem(
              value: DiscountType.percentage,
              child: Text('Percentage'),
            ),
            DropdownMenuItem(
              value: DiscountType.fixed,
              child: Text('Fixed amount'),
            ),
          ],
          onChanged: (selected) =>
              setState(() => type = selected ?? DiscountType.none),
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
