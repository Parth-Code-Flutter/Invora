import 'dart:io';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/business_category_model.dart';
import '../controllers/business_setup_controller.dart';

class BusinessSetupScreen extends GetView<BusinessSetupController> {
  const BusinessSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
          leading: Obx(() {
            // isEditing depends on the asynchronously loaded profile. Reading
            // isLoading keeps this header reactive when that profile arrives.
            final loading = controller.isLoading.value;
            if (loading) return const SizedBox.shrink();
            if (controller.setupStep.value > 0) {
              return IconButton(
                onPressed: controller.returnToIdentity,
                icon: const Icon(Icons.arrow_back_rounded),
              );
            }
            return controller.isEditing
                ? const AppBackButton()
                : const SizedBox.shrink();
          }),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Obx(() => _StepBadge(step: controller.setupStep.value)),
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
                      _SetupHeader(
                        step: controller.setupStep.value,
                        isEditing: controller.isEditing,
                      ),
                      const SizedBox(height: 26),
                      if (controller.setupStep.value == 0) ...[
                        _SectionLabel(
                          title: 'Your identity',
                          caption: controller.isEditing
                              ? 'Used across your invoices.'
                              : 'Required to create your first invoice.',
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
                        const SizedBox(height: 14),
                        Obx(
                          () => AppDropdownField<BusinessCategory>(
                            label: 'Business category',
                            value: controller.businessCategory.value,
                            sheetTitle: 'Choose your business category',
                            searchable: true,
                            sheetHeightFactor: .75,
                            prefixIcon: Icons.category_outlined,
                            options: BusinessCategory.values
                                .map(
                                  (value) => AppDropdownOption(
                                    value: value,
                                    label: value.label,
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) =>
                                controller.businessCategory.value = value,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This only recommends useful product fields and units. You can change it later.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
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
                                validator: controller.validateMobile,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              AppTextField(
                                controller: controller.email,
                                label: 'Email address (optional)',
                                prefixIcon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
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
                        ),
                        const SizedBox(height: 16),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                            ),
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
                            title: const Text('Customize your invoices'),
                            subtitle: const Text(
                              '3 optional sections · complete anytime',
                            ),
                            children: [
                              _OptionalDetailTile(
                                title: 'Business address',
                                subtitle: 'Address, city, state and PIN code',
                                icon: Icons.location_on_outlined,
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
                                          validator: controller.validatePinCode,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _OptionalDetailTile(
                                title: 'Tax and invoice settings',
                                subtitle: 'GST, PAN, currency and numbering',
                                icon: Icons.receipt_long_outlined,
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
                                            controller.gstRegistered.value =
                                                value,
                                      ),
                                    ),
                                    Obx(
                                      () => _ResponsiveFields(
                                        children: [
                                          if (controller.gstRegistered.value)
                                            AppTextField(
                                              controller: controller.gstin,
                                              label: 'GSTIN *',
                                              validator:
                                                  controller.validateGstin,
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
                                            validator: controller.validatePan,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                              FilteringTextInputFormatter.allow(
                                                RegExp('[0-9a-zA-Z]'),
                                              ),
                                            ],
                                          ),
                                          AppTextField(
                                            controller:
                                                controller.invoicePrefix,
                                            label: 'Invoice prefix',
                                            hint: 'INV',
                                            validator: controller
                                                .validateInvoicePrefix,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                              FilteringTextInputFormatter.allow(
                                                RegExp('[0-9a-zA-Z-]'),
                                              ),
                                            ],
                                          ),
                                          AppTextField(
                                            controller: controller
                                                .startingInvoiceNumber,
                                            label: 'Starting invoice number',
                                            hint: '1',
                                            keyboardType: TextInputType.number,
                                            validator: controller
                                                .validateStartingInvoiceNumber,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                9,
                                              ),
                                            ],
                                          ),
                                          AppDropdownField<String>(
                                            label: 'Currency',
                                            sheetTitle: 'Choose currency',
                                            prefixIcon:
                                                Icons.currency_exchange_rounded,
                                            value:
                                                controller.currencyCode.value,
                                            options: BusinessSetupController
                                                .currencies
                                                .entries
                                                .map(
                                                  (entry) => AppDropdownOption(
                                                    value: entry.key,
                                                    label:
                                                        '${entry.key} (${entry.value})',
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (value) =>
                                                controller.currencyCode.value =
                                                    value,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _OptionalDetailTile(
                                title: 'Payment details',
                                subtitle: 'Bank account, UPI, QR and signature',
                                icon: Icons.account_balance_wallet_outlined,
                                child: Column(
                                  children: [
                                    _ResponsiveFields(
                                      children: [
                                        AppTextField(
                                          controller: controller.bankName,
                                          label: 'Bank name',
                                        ),
                                        AppTextField(
                                          controller:
                                              controller.accountHolderName,
                                          label: 'Account holder',
                                        ),
                                        AppTextField(
                                          controller: controller.accountNumber,
                                          label: 'Account number',
                                          keyboardType: TextInputType.number,
                                          validator:
                                              controller.validateAccountNumber,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              18,
                                            ),
                                          ],
                                        ),
                                        AppTextField(
                                          controller: controller.ifsc,
                                          label: 'IFSC',
                                          validator: controller.validateIfsc,
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                              11,
                                            ),
                                            FilteringTextInputFormatter.allow(
                                              RegExp('[0-9a-zA-Z]'),
                                            ),
                                          ],
                                        ),
                                        AppTextField(
                                          controller: controller.upiId,
                                          label: 'UPI ID',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: controller.validateUpiId,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                              321,
                                            ),
                                            FilteringTextInputFormatter.deny(
                                              RegExp(r'\s'),
                                            ),
                                          ],
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
                                              path: controller
                                                  .paymentQrPath
                                                  .value,
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
                                              path: controller
                                                  .signaturePath
                                                  .value,
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
                label: controller.setupStep.value == 0
                    ? 'Continue'
                    : controller.isEditing
                    ? 'Save changes'
                    : 'Save & start invoicing',
                icon: controller.isEditing && controller.setupStep.value == 1
                    ? Icons.check_rounded
                    : null,
                trailingIcon:
                    controller.setupStep.value == 0 || !controller.isEditing
                    ? Icons.arrow_forward_rounded
                    : null,
                isLoading: controller.isSaving.value,
                onPressed: controller.isLoading.value
                    ? null
                    : controller.setupStep.value == 0
                    ? controller.continueToDetails
                    : controller.save,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '${step + 1} OF 2',
      style: AppTextStyles.small.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    ),
  );
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.step, required this.isEditing});
  final int step;
  final bool isEditing;

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
            isEditing
                ? step == 0
                      ? 'Edit business identity'
                      : 'Update business details'
                : step == 0
                ? 'Let’s make it yours'
                : 'How can customers reach you?',
            style: AppTextStyles.pageTitle.copyWith(
              color: Colors.white,
              fontSize: ResponsiveUtils.fontSize(context, 30),
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isEditing
              ? step == 0
                    ? 'Update the name, category, or logo shown across your invoices.'
                    : 'Review contact, tax, payment, and invoice preferences for your business.'
              : step == 0
              ? 'Add your business name and an optional logo for a polished invoice header.'
              : 'Contact, tax and payment details are optional. Add only what you need.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: step == 0 ? .5 : 1,
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

class _OptionalDetailTile extends StatelessWidget {
  const _OptionalDetailTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        title: Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        children: [child],
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
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 94,
                  height: 94,
                  padding: const EdgeInsets.all(5),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: ClipOval(
                    child: path == null
                        ? const ColoredBox(
                            color: Colors.white,
                            child: Icon(
                              Icons.storefront_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          )
                        : Image.file(File(path!), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x29765E6D),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      path == null ? Icons.add_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              path == null ? 'Add business logo' : 'Change business logo',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Optional · PNG or JPG',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
