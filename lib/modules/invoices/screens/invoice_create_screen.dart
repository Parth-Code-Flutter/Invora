import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/discount_type.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/services/unit_service.dart';
import '../../customers/controllers/customer_form_controller.dart';
import '../controllers/invoice_create_controller.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  late final InvoiceCreateController controller = Get.find();
  bool _customerPromptScheduled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
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
          child: Obx(() {
            final actionWidth = (MediaQuery.sizeOf(context).width * .56)
                .clamp(210.0, 300.0)
                .toDouble();
            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.calculation.value?.balanceDueMinor == 0 &&
                                controller.items.isNotEmpty
                            ? 'READY TO REVIEW'
                            : 'INVOICE TOTAL',
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: actionWidth,
                  child: AppButton(
                    onPressed: controller.preview,
                    icon: Icons.arrow_forward_rounded,
                    label: controller.isQuotation
                        ? 'Review estimate'
                        : 'Review invoice',
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_customerPromptScheduled && controller.shouldPromptForCustomer) {
          _customerPromptScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _selectCustomer(context, controller);
          });
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
          _WorkflowProgress(
            hasCustomer: controller.customer.value != null,
            hasItems: controller.items.isNotEmpty,
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _selectCustomer(context, controller),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.customer.value == null
                              ? AppColors.primaryLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: controller.customer.value == null
                            ? const Icon(
                                Icons.person_search_outlined,
                                color: AppColors.primary,
                              )
                            : Text(
                                controller.customer.value!.name.characters.first
                                    .toUpperCase(),
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.customer.value?.name ??
                                  'Choose a customer',
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              controller.customer.value?.companyName ??
                                  controller.customer.value?.mobile ??
                                  'Required to create this invoice',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _selectCustomer(context, controller),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                        ),
                        child: Text(
                          controller.customer.value == null
                              ? 'Select'
                              : 'Change',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _InvoiceMetaCell(
                        icon: Icons.tag_rounded,
                        label: controller.isQuotation ? 'Estimate' : 'Invoice',
                        value: controller.invoiceNumber.value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InvoiceMetaCell(
                        icon: Icons.calendar_today_outlined,
                        label: 'Issued',
                        value: _shortDate(controller.invoiceDate.value),
                        onTap: () => _pickDate(context, due: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InvoiceMetaCell(
                        icon: Icons.event_available_outlined,
                        label: 'Due',
                        value: controller.dueDate.value == null
                            ? 'Add date'
                            : _shortDate(controller.dueDate.value!),
                        muted: controller.dueDate.value == null,
                        onTap: () => _pickDate(context, due: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SectionEyebrow(
                  number: '2',
                  label: controller.items.isEmpty
                      ? 'Items'
                      : 'Items · ${controller.items.length}',
                ),
              ),
              if (controller.items.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => _showAddItemOptions(context),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Add item'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .14),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What are you billing for?',
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Add a saved or one-time item.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _selectProduct(context),
                          icon: const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                          ),
                          label: const Text('Saved item'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editItem(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('One-time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...controller.items.asMap().entries.map((entry) {
              final item = entry.value;
              final result = controller.calculation.value?.items[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(13, 12, 9, 12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${CurrencyUtils.formatMinor(item.rateMinor, symbol: controller.currencySymbol.value)} / ${item.unit}${item.taxRateBasisPoints > 0 ? ' • GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}' : ''}',
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                CurrencyUtils.formatMinor(
                                  result?.totalMinor ?? 0,
                                  symbol: controller.currencySymbol.value,
                                ),
                                style: AppTextStyles.cardTitle,
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Item actions',
                            padding: EdgeInsets.zero,
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editItem(
                                  context,
                                  index: entry.key,
                                  item: item,
                                );
                              } else if (action == 'delete') {
                                controller.removeItem(entry.key);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit details'),
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
                                  title: Text('Remove item'),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _QuantityStepper(
                          value: QuantityUtils.toInputValue(
                            item.quantityScaled,
                          ),
                          canDecrease: item.quantityScaled > 1000,
                          onDecrease: () =>
                              controller.decrementQuantity(entry.key),
                          onRemove: () => controller.removeItem(entry.key),
                          onIncrease: () =>
                              controller.incrementQuantity(entry.key),
                        ),
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
                    decoration: const InputDecoration(
                      labelText: 'Amount paid',
                      hintText: '0.00',
                    ),
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

  Future<void> _selectProduct(BuildContext context) async {
    final selected = await showModalBottomSheet<ProductServiceModel>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectionSheet<ProductServiceModel>(
        title: 'Select saved item',
        description: 'Choose a catalog item to add it instantly.',
        itemLabel: 'saved items',
        future: controller.products(),
        titleFor: (item) => item.name,
        subtitleFor: (item) =>
            '${item.type.label} • ${item.unit} • ${CurrencyUtils.formatMinor(item.salePriceMinor, symbol: controller.currencySymbol.value)}',
        iconFor: (item) => item.type.name == 'service'
            ? Icons.design_services_outlined
            : Icons.inventory_2_outlined,
        emptyTitle: 'Nothing saved yet',
        emptyMessage:
            'Create a reusable product or service, then add it to this invoice.',
        actionLabel: 'Create product or service',
        actionIcon: Icons.add_business_rounded,
        onAction: () async {
          // Named GetX pages are dynamically typed. Read the route result as
          // dynamic and validate it before returning it to the typed sheet.
          final result = await Get.toNamed<dynamic>(AppRoutes.productAdd);
          return result is ProductServiceModel ? result : null;
        },
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
    final result = await showDialog<InvoiceChargeModel>(
      context: context,
      builder: (_) => const _AdditionalChargeDialog(),
    );
    if (result != null) controller.addCharge(result);
  }
}

Future<void> _selectCustomer(
  BuildContext context,
  InvoiceCreateController controller,
) async {
  final selected = await showModalBottomSheet<CustomerModel>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SelectionSheet<CustomerModel>(
      title: 'Who is this invoice for?',
      description: 'Choose saved billing details for this invoice.',
      itemLabel: 'customers',
      future: controller.customers(),
      titleFor: (item) => item.name,
      subtitleFor: (item) => [item.companyName, item.mobile]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' • '),
      emptyTitle: 'No customers yet',
      emptyMessage: 'Create your first customer to start this invoice.',
      actionLabel: 'Create new customer',
      actionIcon: Icons.person_add_alt_1_rounded,
      onAction: () async {
        // GetX registers named pages as dynamic routes. Asking Navigator for a
        // typed route result causes a runtime cast before the page can open.
        final result = await Get.toNamed<dynamic>(
          AppRoutes.customerAdd,
          arguments: const CustomerFormArgs(returnToInvoice: true),
        );
        return result is CustomerModel ? result : null;
      },
    ),
  );
  if (selected != null) controller.selectCustomer(selected);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoice summary',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${controller.items.length} ${controller.items.length == 1 ? 'item' : 'items'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Total',
                      amount: result.grandTotalMinor,
                      symbol: symbol,
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.border),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Paid',
                      amount: result.paidAmountMinor,
                      symbol: symbol,
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.border),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Due',
                      amount: result.balanceDueMinor,
                      symbol: symbol,
                      emphasized: true,
                    ),
                  ),
                ],
              ),
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.symbol,
    this.emphasized = false,
  });

  final String label;
  final int amount;
  final String symbol;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 3),
      Text(
        CurrencyUtils.formatMinor(amount, symbol: symbol),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardTitle.copyWith(
          color: emphasized ? AppColors.primary : null,
        ),
      ),
    ],
  );
}

class _WorkflowProgress extends StatelessWidget {
  const _WorkflowProgress({required this.hasCustomer, required this.hasItems});

  final bool hasCustomer;
  final bool hasItems;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        _WorkflowStep(
          number: 1,
          label: 'Customer',
          complete: hasCustomer,
          active: !hasCustomer,
        ),
        _WorkflowLine(active: hasCustomer),
        _WorkflowStep(
          number: 2,
          label: 'Items',
          complete: hasItems,
          active: hasCustomer && !hasItems,
        ),
        _WorkflowLine(active: hasItems),
        _WorkflowStep(number: 3, label: 'Review', active: hasItems),
      ],
    ),
  );
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.label,
    this.complete = false,
    this.active = false,
  });

  final int number;
  final String label;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: complete
              ? AppColors.success
              : active
              ? AppColors.primary
              : AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: complete
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
            : Text(
                '$number',
                style: AppTextStyles.caption.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: active || complete
              ? Theme.of(context).colorScheme.onSurface
              : AppColors.textTertiary,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

class _WorkflowLine extends StatelessWidget {
  const _WorkflowLine({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: active ? AppColors.success : AppColors.border,
    ),
  );
}

class _InvoiceMetaCell extends StatelessWidget {
  const _InvoiceMetaCell({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) => Material(
    color: onTap == null ? Colors.transparent : AppColors.surfaceSoft,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: muted
                    ? AppColors.textTertiary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onIncrease,
  });

  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: canDecrease ? 'Decrease quantity' : 'Remove item',
          onPressed: canDecrease ? onDecrease : onRemove,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: EdgeInsets.zero,
          icon: Icon(
            canDecrease ? Icons.remove_rounded : Icons.delete_outline_rounded,
            size: 18,
            color: canDecrease ? null : AppColors.error,
          ),
        ),
        Container(width: 1, height: 22, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            value,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(width: 1, height: 22, color: AppColors.border),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: onIncrease,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    ),
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
    required this.description,
    required this.itemLabel,
    required this.future,
    required this.titleFor,
    required this.subtitleFor,
    this.emptyTitle = 'Nothing saved yet',
    this.emptyMessage,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconFor,
  });
  final String title;
  final String description;
  final String itemLabel;
  final Future<List<T>> future;
  final String Function(T) titleFor;
  final String Function(T) subtitleFor;
  final String emptyTitle;
  final String? emptyMessage;
  final String? actionLabel;
  final IconData? actionIcon;
  final Future<T?> Function()? onAction;
  final IconData Function(T)? iconFor;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  final search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.actionIcon ?? Icons.checklist_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.description,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: search,
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.itemLabel}',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
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
            const SizedBox(height: 12),
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
                              normalized.isEmpty
                                  ? widget.emptyTitle
                                  : 'No matching ${widget.itemLabel}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardTitle,
                            ),
                            if (normalized.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Try a different name, number, or detail.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ] else if (widget.emptyMessage != null) ...[
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
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${items.length} ${widget.itemLabel}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final item = items[index - 1];
                      return _SelectionResultTile(
                        icon: widget.iconFor?.call(item),
                        fallback: widget.titleFor(item).trim().isEmpty
                            ? '?'
                            : widget
                                  .titleFor(item)
                                  .characters
                                  .first
                                  .toUpperCase(),
                        title: widget.titleFor(item),
                        subtitle: widget.subtitleFor(item),
                        onTap: () => AppFocus.pop(context, item),
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
      AppFocus.pop(context, created);
    }
  }
}

class _SelectionResultTile extends StatelessWidget {
  const _SelectionResultTile({
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
  });

  final IconData? icon;
  final String fallback;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: icon == null
                  ? Text(
                      fallback,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 19,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      text: item == null ? '' : QuantityUtils.toInputValue(item.quantityScaled),
    );
    unit = item?.unit ?? Get.find<UnitService>().defaultUnit;
    rate = TextEditingController(
      text: item == null ? '' : CurrencyUtils.toInputValue(item.rateMinor),
    );
    hsn = TextEditingController(text: item?.hsnSac ?? '');
    tax = TextEditingController(
      text: item == null ? '' : TaxUtils.toInputValue(item.taxRateBasisPoints),
    );
    discountType = item?.discount.type ?? DiscountType.none;
    discount = TextEditingController(
      text: item == null
          ? ''
          : discountType == DiscountType.fixed
          ? CurrencyUtils.toInputValue(item.discount.fixedMinor)
          : TaxUtils.toInputValue(item.discount.percentageBasisPoints),
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
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: '1',
                    ),
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
              decoration: const InputDecoration(
                labelText: 'Rate *',
                hintText: '0.00',
              ),
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
                    decoration: const InputDecoration(
                      labelText: 'GST %',
                      hintText: '0',
                    ),
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
                  hintText: '0',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => AppFocus.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    onPressed: _submit,
                    label: widget.item == null ? 'Add item' : 'Save item',
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
    final quantityValue = quantity.text.trim().isEmpty
        ? 1000
        : QuantityUtils.parseScaled(quantity.text);
    final rateValue = CurrencyUtils.parseMinor(rate.text);
    final taxValue = tax.text.trim().isEmpty
        ? 0
        : TaxUtils.parseBasisPoints(tax.text);
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
    AppFocus.pop(
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

class _AdditionalChargeDialog extends StatefulWidget {
  const _AdditionalChargeDialog();

  @override
  State<_AdditionalChargeDialog> createState() =>
      _AdditionalChargeDialogState();
}

class _AdditionalChargeDialogState extends State<_AdditionalChargeDialog> {
  final title = TextEditingController();
  final amount = TextEditingController();
  String? error;

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmedTitle = title.text.trim();
    final minor = CurrencyUtils.parseMinor(amount.text);
    if (trimmedTitle.isEmpty || minor == null || minor <= 0) {
      setState(() => error = 'Enter a title and an amount above zero.');
      return;
    }
    AppFocus.pop(
      context,
      InvoiceChargeModel(title: trimmedTitle, amountMinor: minor),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Additional charge'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: title,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Charge title',
            hintText: 'e.g. Delivery',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: 'Amount', errorText: error),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => AppFocus.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Add charge')),
    ],
  );
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late DiscountType type = widget.initial.type;
  late final value = TextEditingController(
    text: type == DiscountType.fixed
        ? CurrencyUtils.toInputValue(widget.initial.fixedMinor)
        : TaxUtils.toInputValue(widget.initial.percentageBasisPoints),
  );

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

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
        onPressed: () => AppFocus.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => AppFocus.pop(context, switch (type) {
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

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

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
