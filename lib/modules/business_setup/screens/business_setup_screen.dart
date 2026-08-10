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
      appBar: AppBar(
        title: const Text(''),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 20), child: _StepBadge()),
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
                    const _SetupHeader(),
                    const SizedBox(height: 26),
                    _SectionLabel(
                      title: 'Your identity',
                      caption: 'This appears at the top of every invoice.',
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _LogoPicker(
                        path: controller.logoPath.value,
                        onTap: controller.pickLogo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.businessName,
                      label: 'Business name *',
                      hint: 'e.g. Creovo Studio',
                      prefixIcon: Icons.storefront_outlined,
                      validator: controller.requiredBusinessName,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 26),
                    const _SectionLabel(
                      title: 'Contact details',
                      caption: 'Optional · helps customers reach you.',
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: _ResponsiveFields(
                        children: [
                          AppTextField(
                            controller: controller.ownerName,
                            label: 'Owner name',
                            prefixIcon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                          ),
                          AppTextField(
                            controller: controller.mobile,
                            label: 'Mobile number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          AppTextField(
                            controller: controller.email,
                            label: 'Email address',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: controller.validateEmail,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        leading: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('Add invoice details'),
                        subtitle: const Text(
                          'Address, GST and payment settings',
                        ),
                        children: [
                          _Section(
                            title: 'Business address',
                            child: Column(
                              children: [
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
                                            LengthLimitingTextInputFormatter(
                                              15,
                                            ),
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
                                        controller:
                                            controller.startingInvoiceNumber,
                                        label: 'Starting invoice number',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                      DropdownButtonFormField<String>(
                                        initialValue:
                                            controller.currencyCode.value,
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
                                            controller.currencyCode.value =
                                                value;
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
                        ],
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
              label: 'Save & start invoicing',
              icon: Icons.arrow_forward_rounded,
              isLoading: controller.isSaving.value,
              onPressed: controller.isLoading.value ? null : controller.save,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '1 OF 2',
      style: AppTextStyles.small.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    ),
  );
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ).createShader(bounds),
          child: Text(
            'Build your invoice identity',
            style: AppTextStyles.pageTitle.copyWith(
              color: Colors.white,
              fontSize: ResponsiveUtils.fontSize(context, 30),
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Add the essentials now. Everything else can wait until your first invoice.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(
            value: .5,
            minHeight: 5,
            backgroundColor: AppColors.primaryLight,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(title, style: AppTextStyles.cardTitle),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          caption,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
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
        height: ResponsiveUtils.height(context, 92),
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

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D16001F),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .18),
                ),
              ),
              child: path == null
                  ? const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primary,
                      size: 28,
                    )
                  : Image.file(File(path!), fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path == null
                        ? 'Add your business logo'
                        : 'Business logo added',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path == null
                        ? 'PNG or JPG · optional'
                        : 'Tap to replace the image',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                path == null ? 'Upload' : 'Change',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
