import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/barcode_capture_result.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/services/product_image_service.dart';
import '../controllers/product_form_controller.dart';
import '../widgets/product_cover_thumb.dart';

String? _attributeHint(String key) => switch (key) {
  'size' => 'e.g. XL, 10 inch or 2 × 4 ft',
  'color' => 'e.g. Black',
  'material' => 'e.g. MDF, Wood or Cotton',
  'shape' => 'e.g. Round or Rectangle',
  'dimensions' => 'e.g. 10 × 6 × 6 inch',
  'weight' => 'e.g. 500 g',
  'sku' => 'Scan or type the barcode',
  _ => null,
};

List<ProductFieldDefinition> _detailFields(ProductFormController controller) {
  controller.attributeControllers.putIfAbsent('sku', TextEditingController.new);
  final fields = controller.attributeDefinitions
      .where((field) => controller.fieldEnabled(field.key))
      .toList();
  const sku = ProductFieldDefinition('sku', 'SKU / Code');
  fields.removeWhere((field) => field.key == 'sku');
  return [sku, ...fields];
}

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
                              _PhotoStudio(
                                controller: controller,
                                onAdd: () => _addPhoto(context, controller),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _KindPicker(
                                value: controller.type.value,
                                onChanged: controller.selectType,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _CatalogLabel('The item'),
                              AppCard(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  16,
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
                                    const SizedBox(height: AppSpacing.md),
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
                                      const SizedBox(height: AppSpacing.md),
                                      AppTextField(
                                        controller: controller.description,
                                        label: 'Invoice description',
                                        hint: 'What should the customer know?',
                                        maxLines: 2,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (controller.showStockCard) ...[
                                const SizedBox(height: AppSpacing.md),
                                const _CatalogLabel('Inventory'),
                                AppCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    14,
                                  ),
                                  child: _InventoryPanel(
                                    trackStock: controller.trackStock.value,
                                    showQty: controller.showQtyField,
                                    quantity: controller.openingQty,
                                    unit: controller.selectedUnit.value,
                                    validateQty: controller.validateOpeningQty,
                                    onChanged: controller.setTrackStock,
                                  ),
                                ),
                              ],
                              if (controller.fieldEnabled('hsnSac') ||
                                  (controller.fieldEnabled('tax') &&
                                      controller.gstEnabled.value)) ...[
                                const SizedBox(height: AppSpacing.md),
                                const _CatalogLabel('For invoices'),
                                AppCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    16,
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
                                          const SizedBox(height: AppSpacing.md),
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
                              const _CatalogLabel('Details'),
                              AppCard(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final fields = _detailFields(controller);
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
                                          const SizedBox(height: AppSpacing.sm),
                                          AppTextField(
                                            controller:
                                                controller
                                                    .attributeControllers[fields[i]
                                                    .key]!,
                                            label: fields[i].label,
                                            hint: _attributeHint(fields[i].key),
                                            suffixIcon: fields[i].key == 'sku'
                                                ? IconButton(
                                                    tooltip: l10n(
                                                      'Scan barcode',
                                                    ),
                                                    onPressed: () =>
                                                        _scanIntoForm(
                                                          context,
                                                          controller,
                                                        ),
                                                    icon: const Icon(
                                                      Icons
                                                          .qr_code_scanner_rounded,
                                                    ),
                                                  )
                                                : null,
                                            keyboardType: fields[i].number
                                                ? const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  )
                                                : TextInputType.text,
                                            textCapitalization:
                                                fields[i].key == 'sku'
                                                ? TextCapitalization.none
                                                : TextCapitalization.sentences,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
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
                                    imagePaths: controller.imagePaths.toList(
                                      growable: false,
                                    ),
                                  ),
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

  Future<void> _addPhoto(
    BuildContext context,
    ProductFormController controller,
  ) async {
    if (!controller.canAddImage) return;
    await AppFocus.dismissKeyboard();
    if (!context.mounted) return;
    final source = await showAppBottomSheet<ImageSource>(
      context: context,
      title: 'Add photo',
      child: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              subtitle: const Text('Use the camera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Pick a saved picture'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await controller.addImageFromSource(source);
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

class _CatalogLabel extends StatelessWidget {
  const _CatalogLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        value,
        style: AppTextStyles.small.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PhotoStudio extends StatelessWidget {
  const _PhotoStudio({required this.controller, required this.onAdd});

  final ProductFormController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final paths = controller.imagePaths.toList(growable: false);
      final canAdd = controller.canAddImage;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CatalogLabel('Photos'),
          SizedBox(
            height: 88,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _PhotoSlot(
                    path: paths.isEmpty ? null : paths[0],
                    label: 'Cover',
                    images: controller.images,
                    enabled: paths.isEmpty && canAdd,
                    onAdd: onAdd,
                    onRemove: paths.isEmpty
                        ? null
                        : () => controller.removeImageAt(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _PhotoSlot(
                    path: paths.length > 1 ? paths[1] : null,
                    images: controller.images,
                    enabled: paths.length == 1 && canAdd,
                    onAdd: onAdd,
                    onRemove: paths.length > 1
                        ? () => controller.removeImageAt(1)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _PhotoSlot(
                    path: paths.length > 2 ? paths[2] : null,
                    images: controller.images,
                    enabled: paths.length == 2 && canAdd,
                    onAdd: onAdd,
                    onRemove: paths.length > 2
                        ? () => controller.removeImageAt(2)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Optional. Up to 3 photos. The first one is the cover.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      );
    });
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.images,
    required this.onAdd,
    required this.enabled,
    this.path,
    this.label,
    this.onRemove,
  });

  final ProductImageService? images;
  final VoidCallback onAdd;
  final bool enabled;
  final String? path;
  final String? label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final file = path != null && images != null && images!.existsSync(path!)
        ? images!.resolve(path!)
        : null;
    final emptyFill = isDark ? AppColors.darkSurface : Colors.white;
    final dashColor = enabled
        ? AppColors.secondary.withValues(alpha: isDark ? .55 : .4)
        : (isDark ? AppColors.darkBorder : AppColors.border);
    return Material(
      color: file != null ? Colors.transparent : emptyFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (file != null)
            InkWell(
              onTap: () => _showPhotoPreview(
                context,
                file: file,
                label: label,
                onRemove: onRemove,
              ),
              child: Image.file(file, fit: BoxFit.cover),
            )
          else ...[
            CustomPaint(
              painter: _DashedRRectPainter(color: dashColor, radius: 12),
              child: const SizedBox.expand(),
            ),
            InkWell(
              onTap: enabled ? onAdd : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: enabled
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                    size: label == null ? 18 : 22,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      label!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (file != null && onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                tooltip: l10n('Remove photo'),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
              ),
            ),
          if (file != null && label != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _showPhotoPreview(
  BuildContext context, {
  required File file,
  String? label,
  VoidCallback? onRemove,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) {
      final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.78;
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 520),
            child: Stack(
              children: [
                SizedBox(
                  height: maxHeight,
                  width: double.infinity,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: Image.file(file, fit: BoxFit.contain)),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onRemove != null)
                        IconButton(
                          tooltip: l10n('Remove photo'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            onRemove();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      IconButton(
                        tooltip: l10n('Close'),
                        onPressed: () => Navigator.pop(dialogContext),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                if (label != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.value, required this.onChanged});

  final ItemType value;
  final ValueChanged<ItemType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KindOption(
            type: ItemType.product,
            selected: value == ItemType.product,
            icon: Icons.inventory_2_outlined,
            label: 'Product',
            onTap: () => onChanged(ItemType.product),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KindOption(
            type: ItemType.service,
            selected: value == ItemType.service,
            icon: Icons.design_services_outlined,
            label: 'Service',
            onTap: () => onChanged(ItemType.service),
          ),
        ),
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.type,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final ItemType type;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = type == ItemType.product
        ? AppColors.primary
        : AppColors.secondary;
    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? .22 : .12)
          : (isDark ? AppColors.darkSurface : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? accent
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.listName.copyWith(
                    color: selected
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warehouse_outlined,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep stock for this item',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Count this item in Stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: trackStock, onChanged: onChanged),
          ],
        ),
        if (showQty) ...[
          const SizedBox(height: 12),
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

class _InvoiceLinePreview extends StatelessWidget {
  const _InvoiceLinePreview({
    required this.name,
    required this.price,
    required this.currency,
    required this.unit,
    required this.type,
    this.imagePaths = const [],
  });

  final String name;
  final String price;
  final String currency;
  final String unit;
  final ItemType type;
  final List<String> imagePaths;

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
          ProductCoverThumb(
            imagePaths: imagePaths,
            type: type,
            size: 36,
            radius: 10,
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
