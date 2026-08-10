import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../controllers/product_form_controller.dart';

class ProductFormScreen extends GetView<ProductFormController> {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              controller.isEditing
                                  ? 'Update catalog item'
                                  : 'Create a reusable item',
                              style: AppTextStyles.pageTitle,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Only a name and price are required. Add invoice details when useful.',
                              style: AppTextStyles.secondaryBody.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<ItemType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: ItemType.product,
                                        label: Text('Product'),
                                        icon: Icon(Icons.inventory_2_outlined),
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
                                        controller.selectType(selection.first),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
                            _ResponsiveFields(
                              children: [
                                AppTextField(
                                  controller: controller.name,
                                  label: 'Item name *',
                                  hint: 'e.g. Brand consultation',
                                  prefixIcon: Icons.sell_outlined,
                                  validator: controller.validateName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                Obx(
                                  () => AppTextField(
                                    controller: controller.salePrice,
                                    label:
                                        'Sale price (${controller.currencySymbol.value}) *',
                                    hint: '0.00',
                                    prefixIcon: Icons.currency_rupee_rounded,
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
                              hint: 'Optional text shown on the invoice',
                              prefixIcon: Icons.notes_rounded,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
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
                                  'Invoice details',
                                  style: AppTextStyles.cardTitle,
                                ),
                                subtitle: Text(
                                  'Unit, tax and HSN/SAC · optional',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                children: [
                                  _ResponsiveFields(
                                    children: [
                                      Obx(
                                        () => AppUnitField(
                                          value: controller.selectedUnit.value,
                                          unitService: controller.unitService,
                                          onChanged: (value) =>
                                              controller.selectedUnit.value =
                                                  value,
                                        ),
                                      ),
                                      AppTextField(
                                        controller: controller.hsnSac,
                                        label: 'HSN/SAC',
                                        prefixIcon: Icons.tag_rounded,
                                      ),
                                    ],
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
                                              hint: 'e.g. 18',
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
              label: controller.isEditing
                  ? 'Save changes'
                  : 'Save ${controller.type.value == ItemType.product ? 'product' : 'service'}',
              icon: Icons.check_rounded,
              isLoading: controller.isSaving.value,
              onPressed: controller.save,
            ),
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
