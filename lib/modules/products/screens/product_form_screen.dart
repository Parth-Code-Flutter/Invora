import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
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

IconData _attributeIcon(String key) => switch (key) {
  'color' => Icons.palette_outlined,
  'size' || 'dimensions' => Icons.straighten_rounded,
  'brand' => Icons.workspace_premium_outlined,
  'material' => Icons.layers_outlined,
  'shape' => Icons.category_outlined,
  'expiryDate' || 'manufacturingDate' => Icons.event_outlined,
  'serialNumber' || 'sku' || 'batchNumber' => Icons.tag_rounded,
  _ => Icons.label_outline_rounded,
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
            () => Text(controller.isEditing.value ? 'Edit item' : 'Add item'),
          ),
          actions: [
            IconButton(
              tooltip: 'Scan barcode',
              onPressed: () => _scanIntoForm(context, controller),
              icon: const Icon(Icons.qr_code_scanner_rounded),
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
                      ResponsiveUtils.height(context, 8),
                      ResponsiveUtils.horizontalPadding(context),
                      ResponsiveUtils.height(context, 32),
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: ResponsiveUtils.contentMaxWidth(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _IntroPanel(
                                isEditing: controller.isEditing.value,
                              ),
                              const SizedBox(height: 18),
                              Obx(
                                () => _TypeSelector(
                                  value: controller.type.value,
                                  onChanged: controller.selectType,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Text(
                                    'Essentials',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '2 required',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (controller.fieldEnabled('unit') ||
                                  controller.fieldEnabled('hsnSac') ||
                                  controller.fieldEnabled('tax'))
                                AppCard(
                                  child: Column(
                                    children: [
                                      _ResponsiveFields(
                                        children: [
                                          AppTextField(
                                            controller: controller.name,
                                            label: 'Item name *',
                                            hint: 'e.g. Brand consultation',
                                            prefixIcon: Icons.sell_outlined,
                                            validator: controller.validateName,
                                            textCapitalization:
                                                TextCapitalization.words,
                                          ),
                                          Obx(
                                            () => AppTextField(
                                              controller: controller.salePrice,
                                              label:
                                                  'Sale price (${controller.currencySymbol.value}) *',
                                              hint: '0.00',
                                              prefixIcon:
                                                  Icons.currency_rupee_rounded,
                                              validator:
                                                  controller.validatePrice,
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
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Obx(
                                        () =>
                                            controller.fieldEnabled(
                                              'description',
                                            )
                                            ? AppTextField(
                                                controller:
                                                    controller.description,
                                                label: 'Invoice description',
                                                hint:
                                                    'What should the customer know?',
                                                prefixIcon: Icons.notes_rounded,
                                                maxLines: 2,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              Obx(() {
                                final fields = controller.attributeDefinitions
                                    .where(
                                      (field) =>
                                          controller.fieldEnabled(field.key),
                                    )
                                    .toList(growable: false);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Product details',
                                                style:
                                                    AppTextStyles.sectionTitle,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _manageFields(context),
                                              icon: const Icon(
                                                Icons.tune_rounded,
                                                size: 17,
                                              ),
                                              label: const Text(
                                                'Manage fields',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${controller.productSettings.category.label} recommendations · all optional',
                                          style: AppTextStyles.small.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (fields.isEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSoft,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Text(
                                              'No optional product fields are enabled. Use Manage fields to add what you need.',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 14),
                                          ...fields.map(
                                            (field) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: AppTextField(
                                                controller:
                                                    controller
                                                        .attributeControllers[field
                                                        .key]!,
                                                label: field.label,
                                                hint: _attributeHint(field.key),
                                                prefixIcon: _attributeIcon(
                                                  field.key,
                                                ),
                                                keyboardType: field.number
                                                    ? const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      )
                                                    : TextInputType.text,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),
                              ListenableBuilder(
                                listenable: Listenable.merge([
                                  controller.name,
                                  controller.salePrice,
                                ]),
                                builder: (context, _) => Obx(
                                  () => _InvoiceLinePreview(
                                    name: controller.name.text.trim(),
                                    price: controller.salePrice.text.trim(),
                                    currency: controller.currencySymbol.value,
                                    unit: controller.selectedUnit.value,
                                    type: controller.type.value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppCard(
                                padding: EdgeInsets.zero,
                                child: ExpansionTile(
                                  shape: const Border(),
                                  collapsedShape: const Border(),
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 5,
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    18,
                                    4,
                                    18,
                                    18,
                                  ),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryLight,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: AppColors.secondary,
                                      size: 21,
                                    ),
                                  ),
                                  title: Text(
                                    'More invoice details',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  subtitle: Text(
                                    'Only the details enabled in Product Settings',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  children: [
                                    _ResponsiveFields(
                                      children: [
                                        if (controller.fieldEnabled('unit'))
                                          Obx(
                                            () => AppUnitField(
                                              value:
                                                  controller.selectedUnit.value,
                                              unitService:
                                                  controller.unitService,
                                              recommendedUnits: controller
                                                  .productSettings
                                                  .preferredUnits,
                                              onChanged: (value) =>
                                                  controller
                                                          .selectedUnit
                                                          .value =
                                                      value,
                                            ),
                                          ),
                                        if (controller.fieldEnabled('hsnSac'))
                                          AppTextField(
                                            controller: controller.hsnSac,
                                            label: 'HSN/SAC',
                                            prefixIcon: Icons.tag_rounded,
                                          ),
                                      ],
                                    ),
                                    Obx(
                                      () =>
                                          controller.fieldEnabled('tax') &&
                                              controller.gstEnabled.value
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 18),
                                                Text(
                                                  'GST rate',
                                                  style:
                                                      AppTextStyles.cardTitle,
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    ...ProductFormController
                                                        .taxRates
                                                        .map(
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
                                                                controller
                                                                    .selectTax(
                                                                      rate,
                                                                    ),
                                                          ),
                                                        ),
                                                    ChoiceChip(
                                                      label: const Text(
                                                        'Custom',
                                                      ),
                                                      selected: controller
                                                          .isCustomTax
                                                          .value,
                                                      onSelected: (_) =>
                                                          controller.selectTax(
                                                            null,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Obx(
                                      () =>
                                          controller.fieldEnabled('tax') &&
                                              controller.gstEnabled.value &&
                                              controller.isCustomTax.value
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: AppTextField(
                                                controller: controller.taxRate,
                                                label:
                                                    'Custom tax percentage *',
                                                hint: 'e.g. 18',
                                                validator:
                                                    controller.validateTax,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Obx(
              () => AppButton(
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

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .12),
            AppColors.secondary.withValues(alpha: .08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Refine this catalog item' : 'Build it once',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Changes apply when you use this item on future invoices.'
                      : 'Save the essentials now and reuse them on every invoice.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final ItemType value;
  final ValueChanged<ItemType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeOption(
            label: 'Product',
            detail: 'A physical item',
            icon: Icons.inventory_2_outlined,
            selected: value == ItemType.product,
            onTap: () => onChanged(ItemType.product),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeOption(
            label: 'Service',
            detail: 'Time or expertise',
            icon: Icons.design_services_outlined,
            selected: value == ItemType.service,
            onTap: () => onChanged(ItemType.service),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                    ? AppColors.primary.withValues(alpha: .16)
                    : AppColors.primaryLight)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : icon,
                      size: 19,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              type == ItemType.product
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice preview',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              '$currency$displayPrice / $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle.copyWith(
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
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
