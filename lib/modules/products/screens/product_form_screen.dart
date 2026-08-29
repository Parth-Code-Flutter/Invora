import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/barcode_capture_result.dart';
import '../controllers/product_form_controller.dart';

String? _attributeHint(String key) => switch (key) {
  'size' => 'e.g. XL, 10 inch or 2 × 4 ft',
  'color' => 'e.g. Black',
  'material' => 'e.g. MDF, Wood or Cotton',
  'shape' => 'e.g. Round or Rectangle',
  'dimensions' => 'e.g. 10 × 6 × 6 inch',
  'weight' => 'e.g. 500 g',
  _ => null,
};

class ProductFormScreen extends GetView<ProductFormController> {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Obx(
            () => AppBarTitle(
              controller.isEditing.value ? 'Edit item' : 'Add item',
              subtitle: 'Catalog',
            ),
          ),
          actions: [
            AppBarIconButton(
              tooltip: l10n('Scan barcode'),
              onPressed: () => _scanIntoForm(context, controller),
              icon: Icons.qr_code_scanner_rounded,
            ),
          ],
        ),
        body: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: controller.formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.horizontalPadding(context),
                      AppSpacing.xs,
                      ResponsiveUtils.horizontalPadding(context),
                      AppSpacing.md,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: ResponsiveUtils.formMaxWidth(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TypeSelector(
                                value: controller.type.value,
                                onChanged: controller.selectType,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppCard(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    AppTextField(
                                      controller: controller.name,
                                      label: 'Item name *',
                                      hint:
                                          controller.type.value ==
                                              ItemType.product
                                          ? 'e.g. 10 Inch MDF'
                                          : 'e.g. Brand consultation',
                                      validator: controller.validateName,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _ResponsiveFields(
                                      children: [
                                        AppTextField(
                                          controller: controller.salePrice,
                                          label:
                                              'Sale price (${controller.currencySymbol.value}) *',
                                          hint: '0.00',
                                          validator: controller.validatePrice,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}'),
                                            ),
                                          ],
                                        ),
                                        if (controller.fieldEnabled('unit'))
                                          AppUnitField(
                                            value:
                                                controller.selectedUnit.value,
                                            unitService: controller.unitService,
                                            recommendedUnits: controller
                                                .productSettings
                                                .preferredUnits,
                                            onChanged: (value) =>
                                                controller.selectedUnit.value =
                                                    value,
                                          ),
                                      ],
                                    ),
                                    if (controller.fieldEnabled(
                                      'description',
                                    )) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      AppTextField(
                                        controller: controller.description,
                                        label: 'Invoice description',
                                        hint: 'What should the customer know?',
                                        maxLines: 2,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ],
                                    if (controller.showStockCard) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      _KeepStockRow(
                                        trackStock: controller.trackStock.value,
                                        showQty: controller.showQtyField,
                                        quantity: controller.openingQty,
                                        unit: controller.selectedUnit.value,
                                        validateQty:
                                            controller.validateOpeningQty,
                                        onChanged: controller.setTrackStock,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (controller.fieldEnabled('hsnSac') ||
                                  (controller.fieldEnabled('tax') &&
                                      controller.gstEnabled.value)) ...[
                                const SizedBox(height: AppSpacing.sm),
                                AppCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (controller.fieldEnabled('hsnSac'))
                                        AppTextField(
                                          controller: controller.hsnSac,
                                          label: 'HSN/SAC',
                                        ),
                                      if (controller.fieldEnabled('tax') &&
                                          controller.gstEnabled.value) ...[
                                        if (controller.fieldEnabled('hsnSac'))
                                          const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'GST rate',
                                          style: AppTextStyles.listName,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ...ProductFormController.taxRates.map(
                                              (rate) => ChoiceChip(
                                                label: Text(
                                                  TaxUtils.formatBasisPoints(
                                                    rate,
                                                  ),
                                                ),
                                                selected:
                                                    !controller
                                                        .isCustomTax
                                                        .value &&
                                                    controller
                                                            .selectedTaxBasisPoints
                                                            .value ==
                                                        rate,
                                                onSelected: (_) =>
                                                    controller.selectTax(rate),
                                              ),
                                            ),
                                            ChoiceChip(
                                              label: const Text('Custom'),
                                              selected:
                                                  controller.isCustomTax.value,
                                              onSelected: (_) =>
                                                  controller.selectTax(null),
                                            ),
                                          ],
                                        ),
                                        if (controller.isCustomTax.value)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: AppSpacing.sm,
                                            ),
                                            child: AppTextField(
                                              controller: controller.taxRate,
                                              label: 'Custom tax percentage *',
                                              hint: 'e.g. 18',
                                              validator: controller.validateTax,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              AppCard(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final fields = controller
                                        .attributeDefinitions
                                        .where(
                                          (field) => controller.fieldEnabled(
                                            field.key,
                                          ),
                                        )
                                        .toList(growable: false);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _FormSectionHeading(
                                          icon: Icons.tune_rounded,
                                          title: 'Product details',
                                          subtitle:
                                              '${controller.productSettings.category.label} recommendations · optional',
                                          action: TextButton(
                                            onPressed: () =>
                                                _manageFields(context),
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text('Manage'),
                                          ),
                                        ),
                                        if (fields.isEmpty) ...[
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'No optional fields are enabled. Add only the details your business uses.',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ],
                                        for (
                                          var i = 0;
                                          i < fields.length;
                                          i++
                                        ) ...[
                                          if (i == 0)
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            )
                                          else
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          AppTextField(
                                            controller:
                                                controller
                                                    .attributeControllers[fields[i]
                                                    .key]!,
                                            label: fields[i].label,
                                            hint: _attributeHint(fields[i].key),
                                            keyboardType: fields[i].number
                                                ? const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  )
                                                : TextInputType.text,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ListenableBuilder(
                                listenable: Listenable.merge([
                                  controller.name,
                                  controller.salePrice,
                                ]),
                                builder: (context, _) => _InvoiceLinePreview(
                                  name: controller.name.text.trim(),
                                  price: controller.salePrice.text.trim(),
                                  currency: controller.currencySymbol.value,
                                  unit: controller.selectedUnit.value,
                                  type: controller.type.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              12,
              ResponsiveUtils.horizontalPadding(context),
              12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Obx(
              () => AppConstrainedAction(
                child: AppButton(
                  label: controller.isEditing.value
                      ? 'Save changes'
                      : 'Save ${controller.type.value == ItemType.product ? 'product' : 'service'}',
                  icon: Icons.check_rounded,
                  isLoading: controller.isSaving.value,
                  onPressed: controller.save,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanIntoForm(
    BuildContext context,
    ProductFormController controller,
  ) async {
    final result = await Get.toNamed<dynamic>(AppRoutes.barcodeCapture);
    if (!context.mounted || result is! BarcodeCaptureResult) return;
    if (result.product != null && controller.hasUnsavedChanges) {
      final confirmed = await showAppConfirmDialog(
        context: context,
        icon: Icons.qr_code_scanner_rounded,
        tone: AppDialogTone.info,
        title: 'Load ${result.product!.name}?',
        message:
            'This barcode belongs to a saved item. Load it here so you can edit the values before saving.',
        confirmLabel: 'Load product',
        cancelLabel: 'Keep typing',
      );
      if (!confirmed || !context.mounted) return;
    }
    await controller.applyCapture(result);
    if (!context.mounted) return;
    if (result.product == null) {
      AppNotification.info(
        'SKU filled',
        'No saved product uses ${result.code}. Complete the name and price, then save.',
      );
    }
  }

  Future<void> _manageFields(BuildContext context) async {
    await AppFocus.dismissKeyboard();
    if (!context.mounted) return;
    await Get.toNamed<void>(AppRoutes.productSettings);
    controller.refreshFieldSettings();
  }
}

class _FormSectionHeading extends StatelessWidget {
  const _FormSectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.listName),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _KeepStockRow extends StatelessWidget {
  const _KeepStockRow({
    required this.trackStock,
    required this.showQty,
    required this.quantity,
    required this.unit,
    required this.validateQty,
    required this.onChanged,
  });

  final bool trackStock;
  final bool showQty;
  final TextEditingController quantity;
  final String unit;
  final String? Function(String?) validateQty;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Keep stock for this item',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            Switch.adaptive(value: trackStock, onChanged: onChanged),
          ],
        ),
        if (showQty) ...[
          const SizedBox(height: 4),
          AppTextField(
            controller: quantity,
            label: 'Quantity',
            hint: unit.isEmpty ? '0' : '0 $unit',
            validator: validateQty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
          ),
        ],
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final ItemType value;
  final ValueChanged<ItemType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ItemType>(
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: const [
          ButtonSegment(
            value: ItemType.product,
            label: Text('Product'),
            icon: Icon(Icons.inventory_2_outlined, size: 18),
          ),
          ButtonSegment(
            value: ItemType.service,
            label: Text('Service'),
            icon: Icon(Icons.design_services_outlined, size: 18),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

class _InvoiceLinePreview extends StatelessWidget {
  const _InvoiceLinePreview({
    required this.name,
    required this.price,
    required this.currency,
    required this.unit,
    required this.type,
  });

  final String name;
  final String price;
  final String currency;
  final String unit;
  final ItemType type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = name.isEmpty
        ? (type == ItemType.product ? 'Your product' : 'Your service')
        : name;
    final displayPrice = price.isEmpty ? '0.00' : price;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            type == ItemType.product
                ? Icons.inventory_2_outlined
                : Icons.design_services_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice preview',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.listName,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              '$currency$displayPrice / $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.listName.copyWith(
                color: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveUtils.formColumns(context);
        final width = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
