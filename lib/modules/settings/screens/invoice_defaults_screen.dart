import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/invoice_defaults_controller.dart';

class InvoiceDefaultsScreen extends GetView<InvoiceDefaultsController> {
  const InvoiceDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Invoice defaults'),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Save the choices you use most. They apply only to new invoices and estimates; existing records stay unchanged.',
                    style: AppTextStyles.secondaryBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Dates & tax', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 14),
                  AppDropdownField<int>(
                    label: 'Default payment due',
                    sheetTitle: 'Choose default due period',
                    prefixIcon: Icons.event_available_outlined,
                    value: controller.usesCustomDueDays
                        ? -1
                        : controller.dueDays.value,
                    options: const [
                      AppDropdownOption(value: 0, label: 'Due immediately'),
                      AppDropdownOption(value: 7, label: '7 days'),
                      AppDropdownOption(value: 15, label: '15 days'),
                      AppDropdownOption(value: 30, label: '30 days'),
                      AppDropdownOption(value: -1, label: 'Custom period'),
                    ],
                    onChanged: controller.setDueChoice,
                  ),
                  if (controller.usesCustomDueDays) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.customDueDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom days *',
                        hintText: '1–365',
                        suffixText: 'days',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppDropdownField<TaxType>(
                    label: 'Default tax mode',
                    sheetTitle: 'Choose default tax mode',
                    prefixIcon: Icons.account_balance_outlined,
                    value: controller.taxType.value,
                    options: const [
                      AppDropdownOption(value: TaxType.none, label: 'No tax'),
                      AppDropdownOption(
                        value: TaxType.cgstSgst,
                        label: 'CGST + SGST',
                      ),
                      AppDropdownOption(value: TaxType.igst, label: 'IGST'),
                    ],
                    onChanged: (value) => controller.taxType.value = value,
                  ),
                  const SizedBox(height: 12),
                  AppDropdownField<int>(
                    label: 'Default GST rate',
                    sheetTitle: 'Choose default GST rate',
                    prefixIcon: Icons.percent_rounded,
                    value: controller.gstRateBasisPoints.value,
                    options: TaxUtils.gstRateBasisPoints
                        .map(
                          (value) => AppDropdownOption(
                            value: value,
                            label: TaxUtils.formatBasisPoints(value),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        controller.gstRateBasisPoints.value = value,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The GST rate preselects custom invoice items. Saved catalog items keep their own rate.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Payment', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 14),
                  AppDropdownField<String>(
                    label: 'Default payment method',
                    sheetTitle: 'Choose default payment method',
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    value: controller.paymentMethod.value,
                    options: InvoiceDefaultsController.paymentMethods
                        .map(
                          (value) =>
                              AppDropdownOption(value: value, label: value),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        controller.paymentMethod.value = value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Document text', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.notes,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Default notes',
                    hintText: 'e.g. Thank you for your business.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.terms,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Default terms & conditions',
                    hintText: 'e.g. Payment is due within the selected period.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => AppButton(
              onPressed: controller.isSaving.value ? null : controller.save,
              label: 'Save defaults',
              isLoading: controller.isSaving.value,
              icon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    ),
  );
}
