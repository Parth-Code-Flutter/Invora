import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../invoices/screens/invoice_item_picker_screen.dart';
import '../controllers/purchase_order_controller.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  State<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  late final PurchaseOrderFormController controller = Get.find();
  bool _supplierPromptScheduled = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!_supplierPromptScheduled && controller.shouldPromptForSupplier) {
        _supplierPromptScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectSupplier(context, controller);
        });
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final itemCount = controller.items.length;
      return UnsavedChangesScope(
        hasChanges: () => controller.hasUnsavedChanges,
        onSaveDraft: () => controller.save(asDraft: true, pop: false),
        child: Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: AppBarTitle(
              controller.isEditing
                  ? 'Edit purchase order'
                  : 'Create purchase order',
            ),
            actions: [
              if (!controller.isEditing)
                TextButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.save(asDraft: true),
                  icon: const Icon(Icons.bookmark_border_rounded, size: 19),
                  label: const Text('Draft'),
                ),
              const SizedBox(width: 8),
            ],
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemCount == 0 ? 'NO ITEMS YET' : 'ITEMS',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            itemCount == 0
                                ? 'Add goods to order'
                                : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.sectionTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: (MediaQuery.sizeOf(context).width * .56)
                          .clamp(210.0, 300.0)
                          .toDouble(),
                      child: AppButton(
                        isLoading: controller.isSaving.value,
                        icon: itemCount == 0 ? Icons.add_rounded : null,
                        trailingIcon: itemCount == 0
                            ? null
                            : Icons.arrow_forward_rounded,
                        label: itemCount == 0
                            ? 'Add first item'
                            : controller.isEditing
                            ? 'Update purchase order'
                            : 'Issue purchase order',
                        onPressed: itemCount == 0
                            ? () => _addItem(context, controller)
                            : () => controller.save(asDraft: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: ResponsiveContent(
            tabletMaxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.only(top: 12),
              children: [
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _selectSupplier(context, controller),
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: controller.supplier.value == null
                                    ? AppColors.primaryLight
                                    : AppColors.successLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: controller.supplier.value == null
                                  ? const Icon(
                                      Icons.storefront_outlined,
                                      color: AppColors.primary,
                                    )
                                  : Text(
                                      _initial(controller.supplier.value!.name),
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
                                    controller.supplier.value?.name ??
                                        'Choose a supplier',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    controller.supplier.value?.companyName ??
                                        controller.supplier.value?.mobile ??
                                        'Required to create this purchase order',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              controller.supplier.value == null
                                  ? 'Select'
                                  : 'Change',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetaCell(
                                icon: Icons.tag_rounded,
                                label: 'Purchase order',
                                value: controller.orderNumber.isEmpty
                                    ? 'PO-—'
                                    : controller.orderNumber,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                            Expanded(
                              child: _MetaCell(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date',
                                value: _date(controller.orderDate.value),
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: controller.orderDate.value,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selected != null) {
                                    controller.setDate(selected);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaCell(
                        icon: Icons.event_available_outlined,
                        label: 'Expected date',
                        value: controller.expectedDate.value == null
                            ? 'Optional'
                            : _date(controller.expectedDate.value!),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.expectedDate.value ??
                                controller.orderDate.value,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            controller.setExpectedDate(selected);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Items', style: AppTextStyles.sectionTitle),
                    ),
                    TextButton.icon(
                      onPressed: () => _addItem(context, controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (controller.items.isEmpty)
                  AppCard(
                    child: AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No items yet',
                      message:
                          'Add catalog items or a custom line. Receiving and billing happen after you issue this order.',
                      actionLabel: 'Add first item',
                      onAction: () => _addItem(context, controller),
                    ),
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (var index = 0; index < itemCount; index++) ...[
                          if (index > 0) const Divider(height: 24),
                          _ItemRow(
                            index: index,
                            item: controller.items[index],
                            controller: controller,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _OptionalSection(
                  title: 'Terms',
                  summary: controller.termsSummary,
                  expanded: controller.showTerms.value,
                  onToggle: () =>
                      controller.showTerms.value = !controller.showTerms.value,
                  child: AppTextField(
                    controller: controller.terms,
                    label: 'Terms',
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 10),
                _OptionalSection(
                  title: 'Notes',
                  summary: controller.notes.text.trim().isEmpty
                      ? 'Optional'
                      : controller.notes.text.trim(),
                  expanded: controller.showNotes.value,
                  onToggle: () =>
                      controller.showNotes.value = !controller.showNotes.value,
                  child: AppTextField(
                    controller: controller.notes,
                    label: 'Notes',
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _OptionalSection extends StatelessWidget {
  const _OptionalSection({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.fromLTRB(14, 8, 14, expanded ? 14 : 8),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.listName),
                      Text(summary, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ],
            ),
          ),
          if (expanded) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.controller,
  });
  final int index;
  final PurchaseOrderItemModel item;
  final PurchaseOrderFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                '${index + 1}',
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
                  const SizedBox(height: 2),
                  Text(
                    '${item.unit} · ${CurrencyUtils.formatMinor(item.rateMinor, symbol: '₹')}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (item.receivedQuantityScaled == 0)
              IconButton(
                tooltip: l10n('Remove item'),
                onPressed: () => controller.removeItem(item),
                icon: const Icon(Icons.close_rounded, size: 18),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _QuantityStepper(
              value: QuantityUtils.toInputValue(item.orderedQuantityScaled),
              canDecrease:
                  item.orderedQuantityScaled > 1000 &&
                  item.orderedQuantityScaled - 1000 >=
                      item.receivedQuantityScaled,
              onDecrease: () => controller.setOrdered(
                item,
                item.orderedQuantityScaled - 1000,
              ),
              onRemove: () => controller.removeItem(item),
              onIncrease: () => controller.setOrdered(
                item,
                item.orderedQuantityScaled + 1000,
              ),
              onEdit: () => _editQuantity(context, item, controller),
            ),
            const SizedBox(width: 8),
            Text('Ordered', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onIncrease,
    required this.onEdit,
  });

  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: canDecrease ? 'Decrease quantity' : 'Remove item',
            onPressed: canDecrease ? onDecrease : onRemove,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              canDecrease ? Icons.remove_rounded : Icons.delete_outline_rounded,
              size: 17,
              color: canDecrease ? null : AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          Tooltip(
            message: l10n('Enter quantity'),
            child: InkWell(
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 34),
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
          Container(
            width: 1,
            height: 22,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          IconButton(
            tooltip: l10n('Increase quantity'),
            onPressed: onIncrease,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

Future<void> _editQuantity(
  BuildContext context,
  PurchaseOrderItemModel item,
  PurchaseOrderFormController controller,
) async {
  final input = TextEditingController(
    text: QuantityUtils.toInputValue(item.orderedQuantityScaled),
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ordered quantity'),
      content: AppTextField(
        controller: input,
        label: 'Quantity',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final parsed = QuantityUtils.parseScaled(input.text);
    if (parsed != null) controller.setOrdered(item, parsed);
  }
  input.dispose();
}

Future<void> _selectSupplier(
  BuildContext context,
  PurchaseOrderFormController controller,
) async {
  var query = '';
  final selected = await showModalBottomSheet<SupplierModel>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is this purchase order for?',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose the supplier you are ordering from.',
                          style: AppTextStyles.secondaryBody,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) => setState(() => query = value),
                          decoration: const InputDecoration(
                            hintText: 'Search supplier, mobile or GSTIN',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<SupplierModel>>(
                      future: controller.suppliers(query: query),
                      builder: (context, snapshot) {
                        final suppliers =
                            snapshot.data ?? const <SupplierModel>[];
                        if (suppliers.isEmpty) {
                          return AppEmptyState(
                            icon: Icons.storefront_outlined,
                            title: query.isEmpty
                                ? 'No suppliers yet'
                                : 'No matching supplier',
                            message: query.isEmpty
                                ? 'Create your first supplier to start this purchase order.'
                                : 'Try another name, mobile number or GSTIN.',
                            actionLabel: query.isEmpty
                                ? 'Create supplier'
                                : null,
                            onAction: query.isEmpty
                                ? () {
                                    Navigator.pop(sheetContext);
                                    Get.toNamed<void>(AppRoutes.supplierAdd);
                                  }
                                : null,
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: suppliers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final value = suppliers[index];
                            return AppGroupedTile(
                              onTap: () => Navigator.pop(sheetContext, value),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.name,
                                    style: AppTextStyles.listName,
                                  ),
                                  Text(
                                    value.companyName ??
                                        value.mobile ??
                                        'Supplier',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
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
        },
      );
    },
  );
  if (selected != null) controller.selectSupplier(selected);
}

Future<void> _addItem(
  BuildContext context,
  PurchaseOrderFormController controller,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Choose saved item'),
              onTap: () => Navigator.pop(sheetContext, 'saved'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Create custom item'),
              onTap: () => Navigator.pop(sheetContext, 'custom'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'saved') {
    final selected = await Get.toNamed<dynamic>(
      AppRoutes.invoiceItemPicker,
      arguments: InvoiceItemPickerArgs(
        alreadyAddedIds: controller.items
            .map((item) => item.productId)
            .whereType<int>()
            .toSet(),
        alreadyAddedLabel: 'On purchase order',
      ),
    );
    if (selected is InvoiceItemPickerResult) {
      controller.applyCatalogSelection(
        added: selected.added,
        removedProductIds: selected.removedIds,
      );
    }
    return;
  }
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unit = TextEditingController(text: 'pcs');
  final rate = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: name, label: 'Item name'),
          const SizedBox(height: 12),
          AppTextField(
            controller: quantity,
            label: 'Quantity',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: unit, label: 'Unit'),
          const SizedBox(height: 12),
          AppTextField(
            controller: rate,
            label: 'Rate',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Add item'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final quantityScaled = QuantityUtils.parseScaled(quantity.text) ?? 0;
    final rateMinor = CurrencyUtils.parseMinor(rate.text) ?? 0;
    if (name.text.trim().isNotEmpty && quantityScaled > 0) {
      controller.addCustomItem(
        name: name.text,
        quantityScaled: quantityScaled,
        unit: unit.text,
        rateMinor: rateMinor,
      );
    }
  }
  name.dispose();
  quantity.dispose();
  unit.dispose();
  rate.dispose();
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}
