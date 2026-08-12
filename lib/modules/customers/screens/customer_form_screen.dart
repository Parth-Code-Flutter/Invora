import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../controllers/customer_form_controller.dart';

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(controller.isEditing ? 'Edit customer' : 'New customer'),
        ),
        body: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: controller.formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.horizontalPadding(context),
                      8,
                      ResponsiveUtils.horizontalPadding(context),
                      32,
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
                              _FormIntro(
                                invoiceFlow: controller.isInvoiceFlow,
                                editing: controller.isEditing,
                              ),
                              const SizedBox(height: 24),
                              const _SectionHeading(
                                title: 'Customer essentials',
                                badge: 'NAME REQUIRED',
                              ),
                              const SizedBox(height: 12),
                              AppCard(
                                padding: const EdgeInsets.all(16),
                                child: _ResponsiveFields(
                                  children: [
                                    AppTextField(
                                      controller: controller.name,
                                      label: 'Customer name *',
                                      hint: 'Who are you billing?',
                                      prefixIcon: Icons.person_outline_rounded,
                                      validator: controller.validateName,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    _MobileField(controller: controller),
                                    AppTextField(
                                      controller: controller.email,
                                      label: 'Email address',
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
                              const SizedBox(height: 20),
                              const _SectionHeading(
                                title: 'Invoice details',
                                badge: 'OPTIONAL',
                              ),
                              const SizedBox(height: 10),
                              _OptionalCustomerSection(
                                icon: Icons.business_outlined,
                                title: 'Business & tax',
                                subtitle: 'Company name and GSTIN',
                                child: _ResponsiveFields(
                                  children: [
                                    AppTextField(
                                      controller: controller.companyName,
                                      label: 'Company name',
                                      prefixIcon: Icons.apartment_rounded,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    AppTextField(
                                      controller: controller.gstin,
                                      label: 'GSTIN',
                                      prefixIcon: Icons.receipt_long_outlined,
                                      validator: controller.validateGstin,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(15),
                                        FilteringTextInputFormatter.allow(
                                          RegExp('[0-9a-zA-Z]'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _OptionalCustomerSection(
                                icon: Icons.location_on_outlined,
                                title: 'Billing address',
                                subtitle: 'Address printed on invoices',
                                child: Column(
                                  children: [
                                    AppTextField(
                                      controller: controller.address,
                                      label: 'Street address',
                                      prefixIcon: Icons.home_outlined,
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
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _OptionalCustomerSection(
                                icon: Icons.notes_rounded,
                                title: 'Private notes',
                                subtitle: 'Visible only inside Creovo Invoice',
                                child: AppTextField(
                                  controller: controller.notes,
                                  label: 'Notes',
                                  prefixIcon: Icons.edit_note_rounded,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 15,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stored privately on this device',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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
              () => AppButton(
                label: controller.isEditing
                    ? 'Save changes'
                    : controller.isInvoiceFlow
                    ? 'Save & use customer'
                    : 'Save customer',
                icon: controller.isInvoiceFlow ? null : Icons.check_rounded,
                trailingIcon: controller.isInvoiceFlow
                    ? Icons.arrow_forward_rounded
                    : null,
                isLoading: controller.isSaving.value,
                onPressed: controller.save,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({required this.controller});

  final CustomerFormController controller;

  @override
  Widget build(BuildContext context) {
    Widget field({Widget? suffixIcon}) => AppTextField(
      controller: controller.mobile,
      label: 'Mobile number *',
      prefixIcon: Icons.phone_outlined,
      suffixIcon: suffixIcon,
      keyboardType: TextInputType.phone,
      validator: controller.validateMobile,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
    );

    // Contact import is create-only. Avoid an Obx in edit mode because that
    // branch has no observable dependency and GetX correctly rejects it.
    if (controller.isEditing) return field();
    return Obx(
      () => field(
        suffixIcon: IconButton(
          tooltip: 'Import from phone contacts',
          onPressed: controller.isImportingContact.value
              ? null
              : controller.importPhoneContact,
          icon: controller.isImportingContact.value
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.contacts_rounded, color: AppColors.secondary),
        ),
      ),
    );
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.invoiceFlow, required this.editing});
  final bool invoiceFlow;
  final bool editing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        editing
            ? 'Keep customer details accurate'
            : invoiceFlow
            ? 'Add them, then keep invoicing'
            : 'Make the next invoice faster',
        style: AppTextStyles.pageTitle.copyWith(
          fontSize: ResponsiveUtils.fontSize(context, 27),
          height: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        invoiceFlow && !editing
            ? 'Add their name and mobile number, then continue building the invoice.'
            : 'Save billing information once and reuse it on every invoice.',
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.badge});
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          badge,
          style: AppTextStyles.small.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
    ],
  );
}

class _OptionalCustomerSection extends StatelessWidget {
  const _OptionalCustomerSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
      ),
      children: [child],
    ),
  );
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
