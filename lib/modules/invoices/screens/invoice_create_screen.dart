import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/business_icons.dart';
import '../../../app/enums/discount_type.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/product_attribute_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/barcode_capture_result.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_calculation_models.dart';
import '../../../data/models/invoice_item_scan_prefill.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_attribute_model.dart';
import '../../../data/services/unit_service.dart';
import '../../../data/services/invoice_defaults_service.dart';
import '../../../data/services/product_settings_service.dart';
import '../../customers/controllers/customer_form_controller.dart';
import '../controllers/invoice_create_controller.dart';
import '../scan/product_scan_screen.dart';
import '../../../data/models/scanned_invoice_line.dart';
import 'invoice_item_picker_screen.dart';

abstract final class _ComposerUi {
  static const page = Color(0xFFFAF9F7);
  static const ink = Color(0xFF1C1917);
  static const body = Color(0xFF78716C);
  static const muted = Color(0xFFA8A29E);
  static const line = Color(0xFFE7E5E4);
  static const coral = Color(0xFFF43F5E);
  static const cardRadius = 16.0;
  static const appBarHeight = 68.0;
}

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  late final InvoiceCreateController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkBackground : _ComposerUi.page;
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      onSaveDraft: () => controller.save(draft: true),
      child: Scaffold(
        backgroundColor: page,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(_ComposerUi.appBarHeight),
          child: _InvoiceComposerAppBar(controller: controller, page: page),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              12,
              ResponsiveUtils.horizontalPadding(context),
              12,
            ),
            child: Obx(() {
              final hasItems = controller.items.isNotEmpty;
              return AppConstrainedAction(
                maxWidth: ResponsiveUtils.footerMaxWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      onPressed: hasItems ? controller.preview : null,
                      trailingIcon: hasItems
                          ? Icons.arrow_forward_rounded
                          : null,
                      radius: 16,
                      isLoading: controller.isSaving.value,
                      label: !hasItems
                          ? 'Add items to continue'
                          : controller.isQuotation
                          ? 'Review estimate'
                          : 'Review invoice',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Saved offline on phone • Ready for PDF & WhatsApp share',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : _ComposerUi.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
      ),
    );
  }
}

class _InvoiceComposerAppBar extends StatelessWidget {
  const _InvoiceComposerAppBar({required this.controller, required this.page});

  final InvoiceCreateController controller;
  final Color page;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: page,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _ComposerUi.appBarHeight,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0x80E7E5E4),
              ),
            ),
          ),
          child: Obx(() {
            final number = controller.invoiceNumber.value;
            final business = controller.businessName.value.trim();
            final document = controller.isQuotation
                ? 'Estimate'
                : controller.gstInvoice.value
                ? 'GST Tax Invoice'
                : 'Tax Invoice';
            return Row(
              children: [
                const _ComposerBack(),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _editInvoiceNumber(context, controller),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          number.isEmpty ? 'New invoice' : '#$number',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: _ComposerUi.coral,
                            fontSize: 18,
                            height: 22 / 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          [
                            if (business.isNotEmpty) business,
                            document,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : _ComposerUi.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.save(draft: true),
                  child: const Text('Draft'),
                ),
                IconButton(
                  tooltip: l10n('Invoice defaults'),
                  onPressed: () => Get.toNamed<void>(AppRoutes.invoiceDefaults),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: isDark ? AppColors.darkTextPrimary : _ComposerUi.ink,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ComposerBack extends StatelessWidget {
  const _ComposerBack();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => AppFocus.maybePop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0x99E7E5E4),
              ),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 16,
              height: 16,
              child: SvgPicture.asset(
                BusinessIcons.back,
                width: 16,
                height: 16,
              ),
            ),
          ),
        ),
      ),
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
          _CustomerDetailsSection(controller: controller),
          const SizedBox(height: 14),
          _DateTermsRow(controller: controller),
          const SizedBox(height: 18),
          _ItemsHeader(controller: controller),
          const SizedBox(height: 10),
          if (controller.items.isEmpty)
            _InvoiceEmptyItemsCard(
              onAddProduct: () => _selectProductForInvoice(
                context,
                controller,
                type: ItemType.product,
              ),
              onAddService: () => _selectProductForInvoice(
                context,
                controller,
                type: ItemType.service,
              ),
              onScan: () => _scanProductsForInvoice(context, controller),
            )
          else
            ...controller.items.asMap().entries.map((entry) {
              final item = entry.value;
              final result = controller.calculation.value?.items[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
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
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: Color(0xFF0284C7),
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
                                if ((item.hsnSac ?? '').trim().isNotEmpty ||
                                    item.taxRateBasisPoints > 0)
                                  Text(
                                    [
                                      if ((item.hsnSac ?? '').trim().isNotEmpty)
                                        'HSN: ${item.hsnSac}',
                                      if (item.taxRateBasisPoints > 0)
                                        'Tax: ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)} GST',
                                    ].join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if (Get.find<ProductSettingsService>()
                                        .showAttributesOnInvoice &&
                                    item.attributes.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ProductAttributeUtils.compact(
                                      item.attributes,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 3),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Tooltip(
                                      message: 'Change price for this invoice',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => _editItemRate(
                                          context,
                                          index: entry.key,
                                          item: item,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                CurrencyUtils.formatMinor(
                                                  item.rateMinor,
                                                  symbol: controller
                                                      .currencySymbol
                                                      .value,
                                                ),
                                                style: AppTextStyles.small
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.edit_outlined,
                                                size: 13,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '/ ${item.unit}${item.taxRateBasisPoints > 0 ? ' • GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}' : ''}',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: l10n('Edit item details'),
                            onPressed: () => _editItem(
                              context,
                              index: entry.key,
                              item: item,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _QuantityStepper(
                            value: QuantityUtils.toInputValue(
                              item.quantityScaled,
                            ),
                            canDecrease: item.quantityScaled > 1000,
                            onDecrease: () =>
                                controller.decrementQuantity(entry.key),
                            onRemove: () => _confirmRemoveItem(
                              context,
                              onConfirm: () => controller.removeItem(entry.key),
                            ),
                            onIncrease: () =>
                                controller.incrementQuantity(entry.key),
                            onEdit: () => _editQuantity(
                              context,
                              index: entry.key,
                              value: item.quantityScaled,
                              unit: item.unit,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyUtils.formatMinor(
                              result?.totalMinor ?? 0,
                              symbol: controller.currencySymbol.value,
                            ),
                            style: AppTextStyles.cardTitle.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n('Remove item'),
                            onPressed: () => _confirmRemoveItem(
                              context,
                              onConfirm: () => controller.removeItem(entry.key),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          _PaymentBreakdownCard(
            controller: controller,
            onEditDiscount: () => _editDiscount(context),
            onAddCharge: () => _addCharge(context),
          ),
          if (!controller.isQuotation) ...[
            const SizedBox(height: 16),
            _MarkInvoiceStatus(controller: controller),
          ],
          const SizedBox(height: 16),
          _NotesTermsCard(controller: controller),
        ],
      ),
    );
    if (!ResponsiveUtils.isTablet(context)) return content;
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
      child: content,
    );
  }

  Future<void> _confirmRemoveItem(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      destructive: true,
      icon: Icons.delete_outline_rounded,
      title: 'Remove item?',
      message: controller.isQuotation
          ? 'This item will be removed from this quotation.'
          : 'This item will be removed from this invoice.',
      confirmLabel: 'Remove item',
      cancelLabel: 'Keep item',
    );
    if (confirmed) onConfirm();
  }

  Future<void> _editQuantity(
    BuildContext context, {
    required int index,
    required int value,
    required String unit,
  }) async {
    final quantity = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _QuantityEditorSheet(value: value, unit: unit),
    );
    if (quantity != null) controller.updateItemQuantity(index, quantity);
  }

  Future<void> _editItem(
    BuildContext context, {
    int? index,
    InvoiceItemModel? item,
  }) async {
    await _editInvoiceItem(context, controller, index: index, item: item);
  }

  Future<void> _editItemRate(
    BuildContext context, {
    required int index,
    required InvoiceItemModel item,
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _InvoicePriceSheet(
        itemName: item.name,
        initialRateMinor: item.rateMinor,
        currencySymbol: controller.currencySymbol.value,
      ),
    );
    if (result != null) controller.updateItemRate(index, result);
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

Future<void> _showAddItemOptions(
  BuildContext context,
  InvoiceCreateController controller,
) async {
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
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan barcodes',
              subtitle: 'Add saved products by scanning their codes',
              onTap: () => Navigator.pop(sheetContext, _AddItemChoice.scan),
            ),
            const SizedBox(height: 10),
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
  if (!context.mounted || choice == null) return;
  if (choice == _AddItemChoice.scan) {
    await _scanProductsForInvoice(context, controller);
  } else if (choice == _AddItemChoice.saved) {
    await _selectProductForInvoice(context, controller);
  } else if (choice == _AddItemChoice.custom) {
    await _editInvoiceItem(context, controller);
  }
}

Future<void> _selectProductForInvoice(
  BuildContext context,
  InvoiceCreateController controller, {
  ItemType? type,
}) async {
  final selected = await Get.toNamed<dynamic>(
    AppRoutes.invoiceItemPicker,
    arguments: InvoiceItemPickerArgs(
      alreadyAddedIds: controller.items
          .map((item) => item.productId)
          .whereType<int>()
          .toSet(),
      initialFilter: type,
    ),
  );
  if (!context.mounted || selected is! InvoiceItemPickerResult) return;
  controller.applyCatalogSelection(
    added: selected.added,
    removedProductIds: selected.removedIds,
  );
}

Future<void> _scanProductsForInvoice(
  BuildContext context,
  InvoiceCreateController controller,
) async {
  final result = await Get.toNamed<dynamic>(
    AppRoutes.productScan,
    arguments: ProductScanArgs(quotation: controller.isQuotation),
  );
  if (!context.mounted || result is! List<ScannedInvoiceLine>) return;
  controller.applyScannedLines(result);
}

Future<void> _editInvoiceItem(
  BuildContext context,
  InvoiceCreateController controller, {
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

/// Empty catalog prompt from Figma Create Invoice (`4210:795`).
class _InvoiceEmptyItemsCard extends StatelessWidget {
  const _InvoiceEmptyItemsCard({
    required this.onAddProduct,
    required this.onAddService,
    required this.onScan,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onAddService;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: AppEmptyGraphic(
        illustration: AppEmptyIllustration.package,
        title: 'No items added yet',
        subtitle:
            'Add products from your catalog or scan a barcode to build this invoice.',
        padding: EdgeInsets.zero,
        footer: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Product',
                    icon: Icons.add_rounded,
                    onPressed: onAddProduct,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddService,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Service'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan barcode'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editInvoiceNumber(
  BuildContext context,
  InvoiceCreateController controller,
) async {
  final input = TextEditingController(text: controller.invoiceNumber.value);
  final saved = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AppDialog(
      tone: AppDialogTone.info,
      form: true,
      title: Text(
        controller.isQuotation ? 'Estimate number' : 'Invoice number',
      ),
      content: TextField(
        controller: input,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: controller.isQuotation
              ? 'Estimate number'
              : 'Invoice number',
          hintText: 'INV-0001',
        ),
      ),
      actions: [
        AppDialogButton(
          label: l10n('Cancel'),
          variant: AppDialogButtonVariant.outlined,
          onPressed: () => Navigator.pop(dialogContext),
        ),
        AppDialogButton(
          label: l10n('Save'),
          onPressed: () => Navigator.pop(dialogContext, input.text),
        ),
      ],
    ),
  );
  input.dispose();
  if (saved != null) controller.setInvoiceNumber(saved);
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              color: isDark ? AppColors.darkTextSecondary : _ComposerUi.body,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
              fontSize: 11,
            ),
          ),
        ),
        if (trailing != null)
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
      ],
    );
  }
}

class _CustomerDetailsSection extends StatelessWidget {
  const _CustomerDetailsSection({required this.controller});

  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customer = controller.customer.value;
    if (customer == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionEyebrow('CUSTOMER DETAILS'),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
            child: InkWell(
              onTap: () => _selectCustomer(context, controller),
              borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : _ComposerUi.line,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Add Customer',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    final gstin = customer.gstin?.trim() ?? '';
    final location = [
      customer.city,
      customer.state,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
    final contact = [
      customer.mobile,
      if (location.isNotEmpty) location,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • ');
    final initials = customer.name.characters.take(2).toString().toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionEyebrow(
          'CUSTOMER DETAILS',
          trailing: TextButton(
            onPressed: () => _selectCustomer(context, controller),
            child: const Text('Change'),
          ),
        ),
        Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
          child: InkWell(
            onTap: () => _selectCustomer(context, controller),
            borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_ComposerUi.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : _ComposerUi.line,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.companyName?.trim().isNotEmpty == true
                              ? customer.companyName!
                              : customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        if (contact.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            contact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (gstin.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (_gstinLooksValid(gstin))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Looks valid',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              Text(
                                gstin.length > 12
                                    ? '${gstin.substring(0, 10)}...'
                                    : gstin,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTermsRow extends StatelessWidget {
  const _DateTermsRow({required this.controller});

  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    final due = controller.dueDate.value;
    final days = controller.paymentTermDays;
    return Row(
      children: [
        Expanded(
          child: _MetaTile(
            icon: Icons.calendar_today_outlined,
            iconColor: _ComposerUi.coral,
            label: 'DATE',
            value: _prettyDate(controller.invoiceDate.value),
            onTap: () => _pickComposerDate(context, controller, due: false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaTile(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.secondary,
            label: 'TERMS',
            value: due == null
                ? 'Add due date'
                : 'Net $days (${_shortMonthDay(due)})',
            onTap: () => _pickComposerDate(context, controller, due: true),
          ),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : _ComposerUi.line,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _ComposerUi.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({required this.controller});

  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Invoice Items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isDarkSurface(context)
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFF5F5F4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${controller.items.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n('Scan barcodes'),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(36, 36),
          ),
          onPressed: () => _scanProductsForInvoice(context, controller),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
        ),
        TextButton.icon(
          onPressed: () => _showAddItemOptions(context, controller),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Item'),
        ),
      ],
    );
  }
}

bool _isDarkSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class _PaymentBreakdownCard extends StatelessWidget {
  const _PaymentBreakdownCard({
    required this.controller,
    required this.onEditDiscount,
    required this.onAddCharge,
  });

  final InvoiceCreateController controller;
  final VoidCallback onEditDiscount;
  final VoidCallback onAddCharge;

  @override
  Widget build(BuildContext context) {
    final result = controller.calculation.value;
    final symbol = controller.currencySymbol.value;
    final taxLabel = switch (controller.taxType.value) {
      TaxType.cgstSgst => 'Intrastate (CGST + SGST)',
      TaxType.igst => 'Interstate (IGST)',
      TaxType.none => 'No tax',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionEyebrow(
          'PAYMENT & TAX BREAKDOWN',
          trailing: TextButton(
            onPressed: () => _pickTaxMode(context, controller),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              taxLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Overall invoice discount'),
                subtitle: Text(
                  _discountLabel(controller.invoiceDiscount.value, symbol),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: onEditDiscount,
              ),
              if (result != null) ...[
                _amountRow('Items Subtotal', result.subtotalMinor, symbol),
                if (result.itemDiscountTotalMinor > 0)
                  _amountRow(
                    'Item discounts',
                    -result.itemDiscountTotalMinor,
                    symbol,
                  ),
                if (result.invoiceDiscountMinor > 0)
                  _amountRow('Discount', -result.invoiceDiscountMinor, symbol),
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
                _amountRow('Round off', result.roundOffMinor, symbol),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Invoice Amount',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatMinor(
                        result.grandTotalMinor,
                        symbol: symbol,
                      ),
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (result.cgstMinor + result.sgstMinor + result.igstMinor > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Including ${CurrencyUtils.formatMinor(result.cgstMinor + result.sgstMinor + result.igstMinor, symbol: symbol)} GST total',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
              ...controller.charges.asMap().entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.value.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.removeCharge(entry.key),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddCharge,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Additional charge'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarkInvoiceStatus extends StatelessWidget {
  const _MarkInvoiceStatus({required this.controller});

  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.hasRecordedPayments) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_clock_outlined, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payments are managed from Invoice details. Keep the revised total at or above the amount already paid.',
              ),
            ),
          ],
        ),
      );
    }
    final paid = controller.calculation.value?.paidAmountMinor ?? 0;
    final total = controller.calculation.value?.grandTotalMinor ?? 0;
    final full = total > 0 && paid >= total;
    final partial = paid > 0 && !full;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionEyebrow('MARK INVOICE AS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatusPill(
                label: 'Unpaid',
                selected: paid == 0,
                color: const Color(0xFF2563EB),
                onTap: controller.markUnpaid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusPill(
                label: 'Part Paid',
                selected: controller.requestingPartialPayment.value || partial,
                color: AppColors.warning,
                onTap: controller.markPartPaid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusPill(
                label: 'Paid Full',
                selected: full,
                color: AppColors.success,
                onTap: controller.markPaidInFull,
              ),
            ),
          ],
        ),
        if (controller.requestingPartialPayment.value ||
            (paid > 0 && !full)) ...[
          const SizedBox(height: 10),
          TextField(
            controller: controller.paidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n('Opening payment'),
              hintText: l10n('0.00'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: .12) : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? color : _ComposerUi.line),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesTermsCard extends StatelessWidget {
  const _NotesTermsCard({required this.controller});

  final InvoiceCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionEyebrow('INVOICE NOTES & TERMS'),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: controller.notesController,
                minLines: 2,
                maxLines: 2,
                textAlignVertical: AppTextStyles.inputAlign(maxLines: 2),
                decoration: InputDecoration(
                  labelText: l10n('Notes'),
                  hintText: l10n('Delivery, packing or internal notes'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.termsController,
                minLines: 2,
                maxLines: 2,
                textAlignVertical: AppTextStyles.inputAlign(maxLines: 2),
                decoration: InputDecoration(
                  labelText: l10n('Terms & conditions'),
                  hintText: l10n('e.g. Goods once sold will not be taken back'),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _pickComposerDate(
  BuildContext context,
  InvoiceCreateController controller, {
  required bool due,
}) async {
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
    controller.setDueDate(picked);
  } else {
    controller.setInvoiceDate(picked);
  }
}

Future<void> _pickTaxMode(
  BuildContext context,
  InvoiceCreateController controller,
) async {
  final selected = await showAppDropdownSheet<TaxType>(
    context: context,
    title: 'Choose tax mode',
    value: controller.taxType.value,
    options: [
      AppDropdownOption(value: TaxType.none, label: l10n('No tax')),
      AppDropdownOption(value: TaxType.cgstSgst, label: l10n('CGST + SGST')),
      AppDropdownOption(value: TaxType.igst, label: l10n('IGST')),
    ],
  );
  if (selected != null) controller.setTaxType(selected);
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
                      label: l10n('Total'),
                      amount: result.grandTotalMinor,
                      symbol: symbol,
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.border),
                  Expanded(
                    child: _SummaryMetric(
                      label: l10n('Paid'),
                      amount: result.paidAmountMinor,
                      symbol: symbol,
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.border),
                  Expanded(
                    child: _SummaryMetric(
                      label: l10n('Due'),
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
  Widget build(BuildContext context) => Container(
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
        Container(width: 1, height: 22, color: AppColors.border),
        Tooltip(
          message: 'Enter quantity',
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
        Container(width: 1, height: 22, color: AppColors.border),
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

class _QuantityEditorSheet extends StatefulWidget {
  const _QuantityEditorSheet({required this.value, required this.unit});
  final int value;
  final String unit;

  @override
  State<_QuantityEditorSheet> createState() => _QuantityEditorSheetState();
}

class _QuantityEditorSheetState extends State<_QuantityEditorSheet> {
  late final TextEditingController input = TextEditingController(
    text: QuantityUtils.toInputValue(widget.value),
  );
  String? error;

  @override
  void initState() {
    super.initState();
    input.selection = TextSelection(
      baseOffset: 0,
      extentOffset: input.text.length,
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _save() {
    final value = QuantityUtils.parseScaled(input.text);
    if (value == null || value <= 0) {
      setState(() => error = 'Enter a quantity greater than 0.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter quantity', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Type the exact quantity instead of tapping + repeatedly.',
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          decoration: InputDecoration(
            labelText: l10n('Quantity *'),
            hintText: l10n('e.g. 1'),
            suffixText: widget.unit,
            errorText: error,
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Update quantity'),
        ),
      ],
    ),
  );
}

enum _AddItemChoice { scan, saved, custom }

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
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: l10n('Search ${widget.itemLabel}'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n('Clear search'),
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

class _InvoicePriceSheet extends StatefulWidget {
  const _InvoicePriceSheet({
    required this.itemName,
    required this.initialRateMinor,
    required this.currencySymbol,
  });

  final String itemName;
  final int initialRateMinor;
  final String currencySymbol;

  @override
  State<_InvoicePriceSheet> createState() => _InvoicePriceSheetState();
}

class _InvoicePriceSheetState extends State<_InvoicePriceSheet> {
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(
      text: CurrencyUtils.toInputValue(widget.initialRateMinor),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Price for this invoice', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 5),
        Text(
          widget.itemName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only this invoice changes. The saved catalog price stays the same.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rate,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n('Invoice price *'),
            prefixText: '${widget.currencySymbol} ',
            hintText: l10n('0.00'),
          ),
        ),
        const SizedBox(height: 18),
        AppButton(onPressed: _save, label: l10n('Apply invoice price')),
      ],
    ),
  );

  void _save() {
    final value = CurrencyUtils.parseMinor(_rate.text);
    if (value == null || value <= 0) {
      AppNotification.warning(
        'Enter a valid price',
        'The invoice price must be greater than zero.',
      );
      return;
    }
    AppFocus.pop(context, value);
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.item});
  final InvoiceItemModel? item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  static const _customGstRate = -1;
  late final TextEditingController name;
  late final TextEditingController quantity;
  late String unit;
  late final TextEditingController rate;
  late final TextEditingController hsn;
  late final TextEditingController tax;
  late int selectedTaxRate;
  late final TextEditingController discount;
  late DiscountType discountType;
  int? _productId;
  String? _description;
  List<ProductAttributeValue> _attributes = const [];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _productId = item?.productId;
    _description = item?.description;
    _attributes = item?.attributes ?? const [];
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
    final storedTax =
        item?.taxRateBasisPoints ??
        (Get.isRegistered<InvoiceDefaultsService>()
            ? Get.find<InvoiceDefaultsService>().gstRateBasisPoints
            : 1800);
    selectedTaxRate = TaxUtils.gstRateBasisPoints.contains(storedTax)
        ? storedTax
        : _customGstRate;
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
              widget.item == null
                  ? 'Scan a saved product to fill these fields, or enter a one-time item.'
                  : 'Scan a barcode to load a saved product, then change anything you need.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan barcode'),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n('Item name *'),
                hintText: l10n('e.g. Website design'),
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
                    decoration: InputDecoration(
                      labelText: l10n('Quantity *'),
                      hintText: l10n('1'),
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
              decoration: InputDecoration(
                labelText: l10n('Rate *'),
                hintText: l10n('0.00'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hsn,
                    decoration: InputDecoration(
                      labelText: l10n('HSN/SAC'),
                      hintText: l10n('e.g. 998314'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdownField<int>(
                    label: l10n('GST rate'),
                    sheetTitle: 'Choose GST rate',
                    prefixIcon: Icons.percent_rounded,
                    value: selectedTaxRate,
                    options: [
                      ...TaxUtils.gstRateBasisPoints.map(
                        (rate) => AppDropdownOption(
                          value: rate,
                          label: rate == 0
                              ? 'No GST (0%)'
                              : TaxUtils.formatBasisPoints(rate),
                        ),
                      ),
                      AppDropdownOption(
                        value: _customGstRate,
                        label: l10n('Custom rate'),
                        icon: Icons.edit_outlined,
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedTaxRate = value);
                      if (value == _customGstRate) {
                        tax.clear();
                      } else {
                        tax.text = TaxUtils.toInputValue(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (selectedTaxRate == _customGstRate) ...[
              const SizedBox(height: 12),
              TextField(
                controller: tax,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n('Custom GST percentage *'),
                  hintText: l10n('Enter a rate from 0 to 100'),
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppDropdownField<DiscountType>(
              label: l10n('Discount'),
              sheetTitle: 'Choose item discount',
              prefixIcon: Icons.discount_outlined,
              value: discountType,
              options: [
                AppDropdownOption(
                  value: DiscountType.none,
                  label: l10n('No discount'),
                ),
                AppDropdownOption(
                  value: DiscountType.percentage,
                  label: l10n('Percentage'),
                ),
                AppDropdownOption(
                  value: DiscountType.fixed,
                  label: l10n('Fixed amount'),
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
                  hintText: l10n('0'),
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

  Future<void> _scanBarcode() async {
    final result = await Get.toNamed<dynamic>(AppRoutes.barcodeCapture);
    if (!mounted || result is! BarcodeCaptureResult) return;
    final product = result.product;
    if (product == null) {
      AppNotification.warning(
        'No saved product',
        'No catalog item uses ${result.code}. Enter the details here, or save it in Products first.',
      );
      return;
    }
    setState(() => _applyPrefill(InvoiceItemScanPrefill.fromProduct(product)));
  }

  void _applyPrefill(InvoiceItemScanPrefill prefill) {
    _productId = prefill.productId;
    _description = prefill.description;
    _attributes = prefill.attributes;
    name.text = prefill.name;
    if (quantity.text.trim().isEmpty) {
      quantity.text = prefill.quantityText;
    }
    unit = prefill.unit;
    rate.text = prefill.rateText;
    hsn.text = prefill.hsnSac;
    tax.text = TaxUtils.toInputValue(prefill.taxRateBasisPoints);
    selectedTaxRate =
        TaxUtils.gstRateBasisPoints.contains(prefill.taxRateBasisPoints)
        ? prefill.taxRateBasisPoints
        : _customGstRate;
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
        productId: _productId,
        name: name.text.trim(),
        description: _description,
        quantityScaled: quantityValue,
        unit: unit.trim(),
        rateMinor: rateValue,
        hsnSac: hsn.text.trim().isEmpty ? null : hsn.text.trim(),
        taxRateBasisPoints: taxValue,
        discount: discountValue,
        attributes: _attributes,
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
  Widget build(BuildContext context) => AppDialog(
    tone: AppDialogTone.info,
    icon: Icons.discount_outlined,
    form: true,
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
          decoration: InputDecoration(
            labelText: l10n('Charge title'),
            hintText: l10n('e.g. Delivery'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n('Amount'),
            hintText: l10n('0.00'),
            errorText: error,
          ),
        ),
      ],
    ),
    actions: [
      AppDialogButton(
        label: l10n('Cancel'),
        variant: AppDialogButtonVariant.outlined,
        onPressed: () => AppFocus.pop(context),
      ),
      AppDialogButton(
        label: l10n('Add charge'),
        icon: Icons.add_rounded,
        onPressed: _submit,
      ),
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
  Widget build(BuildContext context) => AppDialog(
    tone: AppDialogTone.info,
    icon: Icons.add_card_rounded,
    form: true,
    title: const Text('Invoice discount'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDropdownField<DiscountType>(
          label: l10n('Discount type'),
          sheetTitle: 'Choose invoice discount',
          value: type,
          options: [
            AppDropdownOption(
              value: DiscountType.none,
              label: l10n('No discount'),
            ),
            AppDropdownOption(
              value: DiscountType.percentage,
              label: l10n('Percentage'),
            ),
            AppDropdownOption(
              value: DiscountType.fixed,
              label: l10n('Fixed amount'),
            ),
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
              hintText: type == DiscountType.fixed ? '0.00' : 'e.g. 10',
            ),
          ),
        ],
      ],
    ),
    actions: [
      AppDialogButton(
        label: l10n('Cancel'),
        variant: AppDialogButtonVariant.outlined,
        onPressed: () => AppFocus.pop(context),
      ),
      AppDialogButton(
        label: l10n('Apply'),
        icon: Icons.check_rounded,
        onPressed: () => AppFocus.pop(context, switch (type) {
          DiscountType.none => const DiscountInput.none(),
          DiscountType.fixed => DiscountInput.fixed(
            CurrencyUtils.parseMinor(value.text) ?? 0,
          ),
          DiscountType.percentage => DiscountInput.percentage(
            TaxUtils.parseBasisPoints(value.text) ?? 0,
          ),
        }),
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

String _prettyDate(DateTime value) => DateFormat('dd MMM yyyy').format(value);

String _shortMonthDay(DateTime value) => DateFormat('dd MMM').format(value);

bool _gstinLooksValid(String gstin) {
  final trimmed = gstin.trim().toUpperCase();
  return trimmed.length == 15 && RegExp(r'^[0-9A-Z]{15}$').hasMatch(trimmed);
}

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
