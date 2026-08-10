import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/customer_form_controller.dart';

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Get.arguments == null ? 'Add customer' : 'Edit customer'),
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
                                    'Customer basics',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 16),
                                  _ResponsiveFields(
                                    children: [
                                      AppTextField(
                                        controller: controller.name,
                                        label: 'Customer name *',
                                        validator: controller.validateName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                      AppTextField(
                                        controller: controller.companyName,
                                        label: 'Company name',
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                      AppTextField(
                                        controller: controller.mobile,
                                        label: 'Mobile',
                                        keyboardType: TextInputType.phone,
                                        validator: controller.validateMobile,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                      AppTextField(
                                        controller: controller.email,
                                        label: 'Email',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: controller.validateEmail,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(254),
                                          FilteringTextInputFormatter.deny(
                                            RegExp(r'\s'),
                                          ),
                                        ],
                                      ),
                                    ],
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
                                    'Billing address',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: controller.address,
                                    label: 'Address',
                                    maxLines: 2,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  const SizedBox(height: 12),
                                  _ResponsiveFields(
                                    children: [
                                      AppTextField(
                                        controller: controller.city,
                                        label: 'City',
                                      ),
                                      AppTextField(
                                        controller: controller.state,
                                        label: 'State',
                                      ),
                                      AppTextField(
                                        controller: controller.pinCode,
                                        label: 'PIN code',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ],
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
                                    'Tax and notes',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: controller.gstin,
                                    label: 'GSTIN',
                                    validator: controller.validateGstin,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(15),
                                      FilteringTextInputFormatter.allow(
                                        RegExp('[0-9a-zA-Z]'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  AppTextField(
                                    controller: controller.notes,
                                    label: 'Notes',
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Obx(
                              () => AppButton(
                                label: controller.isEditing
                                    ? 'Save changes'
                                    : 'Add customer',
                                icon: Icons.check_rounded,
                                isLoading: controller.isSaving.value,
                                onPressed: controller.save,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customer information is stored only on this device.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
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
        final twoColumns = ResponsiveUtils.formColumns(context) == 2;
        final width = twoColumns
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
