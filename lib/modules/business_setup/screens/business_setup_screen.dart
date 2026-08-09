import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_section_header.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/business_setup_controller.dart';

class BusinessSetupScreen extends GetView<BusinessSetupController> {
  const BusinessSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your business')),
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
                    Text(
                      'Add the details you want to appear on invoices. Only the business name is required.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Business identity',
                      child: Column(
                        children: [
                          Obx(
                            () => _ImagePickerCard(
                              label: 'Business logo',
                              path: controller.logoPath.value,
                              icon: Icons.storefront_outlined,
                              onTap: controller.pickLogo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ResponsiveFields(
                            children: [
                              AppTextField(
                                controller: controller.businessName,
                                label: 'Business name *',
                                validator: controller.requiredBusinessName,
                                textCapitalization: TextCapitalization.words,
                              ),
                              AppTextField(
                                controller: controller.ownerName,
                                label: 'Owner name',
                                textCapitalization: TextCapitalization.words,
                              ),
                              AppTextField(
                                controller: controller.mobile,
                                label: 'Mobile',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              AppTextField(
                                controller: controller.email,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: controller.validateEmail,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Business address',
                      child: Column(
                        children: [
                          AppTextField(
                            controller: controller.address,
                            label: 'Address',
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
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
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Tax and invoice settings',
                      child: Column(
                        children: [
                          Obx(
                            () => SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('GST registered'),
                              subtitle: const Text(
                                'Enable GST details on invoices',
                              ),
                              value: controller.gstRegistered.value,
                              onChanged: (value) =>
                                  controller.gstRegistered.value = value,
                            ),
                          ),
                          Obx(
                            () => _ResponsiveFields(
                              children: [
                                if (controller.gstRegistered.value)
                                  AppTextField(
                                    controller: controller.gstin,
                                    label: 'GSTIN *',
                                    validator: controller.validateGstin,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(15),
                                      FilteringTextInputFormatter.allow(
                                        RegExp('[0-9a-zA-Z]'),
                                      ),
                                    ],
                                  ),
                                AppTextField(
                                  controller: controller.pan,
                                  label: 'PAN',
                                ),
                                AppTextField(
                                  controller: controller.invoicePrefix,
                                  label: 'Invoice prefix',
                                ),
                                AppTextField(
                                  controller: controller.startingInvoiceNumber,
                                  label: 'Starting invoice number',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: controller.currencyCode.value,
                                  decoration: const InputDecoration(
                                    labelText: 'Currency',
                                  ),
                                  items: BusinessSetupController
                                      .currencies
                                      .entries
                                      .map(
                                        (entry) => DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            '${entry.key} (${entry.value})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.currencyCode.value = value;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Payment details',
                      child: Column(
                        children: [
                          _ResponsiveFields(
                            children: [
                              AppTextField(
                                controller: controller.bankName,
                                label: 'Bank name',
                              ),
                              AppTextField(
                                controller: controller.accountHolderName,
                                label: 'Account holder',
                              ),
                              AppTextField(
                                controller: controller.accountNumber,
                                label: 'Account number',
                                keyboardType: TextInputType.number,
                              ),
                              AppTextField(
                                controller: controller.ifsc,
                                label: 'IFSC',
                              ),
                              AppTextField(
                                controller: controller.upiId,
                                label: 'UPI ID',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(
                                  () => _ImagePickerCard(
                                    label: 'Payment QR',
                                    path: controller.paymentQrPath.value,
                                    icon: Icons.qr_code_rounded,
                                    onTap: controller.pickPaymentQr,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(
                                  () => _ImagePickerCard(
                                    label: 'Signature',
                                    path: controller.signaturePath.value,
                                    icon: Icons.draw_outlined,
                                    onTap: controller.pickSignature,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => AppButton(
                        label: 'Save and continue',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.save,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 16),
          child,
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

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.label,
    required this.path,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? path;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: ResponsiveUtils.height(context, 116),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.primary, size: 30),
                  const SizedBox(height: 8),
                  Text('Add $label', style: AppTextStyles.small),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(File(path!), fit: BoxFit.contain),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      color: Colors.black54,
                      child: Text(
                        'Change $label',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
