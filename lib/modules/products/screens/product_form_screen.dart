import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/product_form_controller.dart';

class ProductFormScreen extends GetView<ProductFormController> {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Get.arguments == null ? 'Add item' : 'Edit item'),
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
                          children: [
                            AppCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item type',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 14),
                                  Obx(
                                    () => SizedBox(
                                      width: double.infinity,
                                      child: SegmentedButton<ItemType>(
                                        segments: const [
                                          ButtonSegment(
                                            value: ItemType.product,
                                            label: Text('Product'),
                                            icon: Icon(
                                              Icons.inventory_2_outlined,
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: ItemType.service,
                                            label: Text('Service'),
                                            icon: Icon(
                                              Icons.design_services_outlined,
                                            ),
                                          ),
                                        ],
                                        selected: {controller.type.value},
                                        onSelectionChanged: (selection) =>
                                            controller.selectType(
                                              selection.first,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ResponsiveFields(
                                    children: [
                                      AppTextField(
                                        controller: controller.name,
                                        label: 'Name *',
                                        validator: controller.validateName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                      Obx(
                                        () => AppTextField(
                                          controller: controller.salePrice,
                                          label:
                                              'Sale price (${controller.currencySymbol.value}) *',
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  AppTextField(
                                    controller: controller.description,
                                    label: 'Description',
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unit and tax',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 16),
                                  _ResponsiveFields(
                                    children: [
                                      Obx(
                                        () => AppDropdownField<String>(
                                          label: 'Unit *',
                                          sheetTitle: 'Choose item unit',
                                          prefixIcon: Icons.straighten_rounded,
                                          value: controller.selectedUnit.value,
                                          options: ProductFormController.units
                                              .map(
                                                (unit) => AppDropdownOption(
                                                  value: unit,
                                                  label: unit == 'custom'
                                                      ? 'Custom unit'
                                                      : unit,
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) =>
                                              controller.selectedUnit.value =
                                                  value,
                                        ),
                                      ),
                                      AppTextField(
                                        controller: controller.hsnSac,
                                        label: 'HSN/SAC',
                                      ),
                                    ],
                                  ),
                                  Obx(
                                    () =>
                                        controller.selectedUnit.value ==
                                            'custom'
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: AppTextField(
                                              controller: controller.customUnit,
                                              label: 'Custom unit *',
                                              validator:
                                                  controller.validateCustomUnit,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Obx(
                                    () => controller.gstEnabled.value
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 18),
                                              Text(
                                                'GST rate',
                                                style: AppTextStyles.cardTitle,
                                              ),
                                              const SizedBox(height: 8),
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
                                                          controller.selectTax(
                                                            rate,
                                                          ),
                                                    ),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text('Custom'),
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
                                        controller.gstEnabled.value &&
                                            controller.isCustomTax.value
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: AppTextField(
                                              controller: controller.taxRate,
                                              label: 'Custom tax percentage *',
                                              validator: controller.validateTax,
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
                            const SizedBox(height: 24),
                            Obx(
                              () => AppButton(
                                label: controller.isEditing
                                    ? 'Save changes'
                                    : 'Add item',
                                icon: Icons.check_rounded,
                                isLoading: controller.isSaving.value,
                                onPressed: controller.save,
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
