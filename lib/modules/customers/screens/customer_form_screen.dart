import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_country_picker.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/services/gst_indian_states.dart';
import '../controllers/customer_form_controller.dart';

const _pageCream = Color(0xFFFAF9F7);

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkBackground : _pageCream;
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Scaffold(
        backgroundColor: page,
        appBar: AppBar(
          backgroundColor: page,
          leading: const AppBackButton(),
          title: AppBarTitle(
            controller.isEditing ? 'Edit customer' : 'Add Customer',
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
                      8,
                      ResponsiveUtils.horizontalPadding(context),
                      24,
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
                              const _CoreDetailsHeader(),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: controller.name,
                                label: 'Customer / Shop Name *',
                                hint: 'e.g. Ramesh Patel or Acme Traders',
                                prefixIcon: Icons.storefront_outlined,
                                validator: controller.validateName,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 12),
                              _PhoneField(controller: controller),
                              const SizedBox(height: 18),
                              _GstAddressCard(controller: controller),
                              if (!controller.isEditing &&
                                  !controller.isInvoiceFlow) ...[
                                const SizedBox(height: 14),
                                _CreateInvoiceToggle(controller: controller),
                              ],
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [page.withValues(alpha: 0), page, page],
                stops: const [0, 0.28, 1],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                20,
                ResponsiveUtils.horizontalPadding(context),
                12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => AppConstrainedAction(
                      child: AppButton(
                        label: controller.isEditing
                            ? 'Save changes'
                            : controller.isInvoiceFlow
                            ? 'Save & use customer'
                            : 'Save Customer',
                        icon: controller.isInvoiceFlow
                            ? null
                            : Icons.person_add_alt_1_rounded,
                        trailingIcon: controller.isInvoiceFlow
                            ? Icons.arrow_forward_rounded
                            : null,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.save,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Instant offline save • Stays on this device',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
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

class _CoreDetailsHeader extends StatelessWidget {
  const _CoreDetailsHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'CORE DETAILS',
            style: AppTextStyles.small.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'FAST BILLING',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final CustomerFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget field({Widget? suffixIcon}) => AppTextField(
        controller: controller.mobile,
        label: 'Phone Number *',
        hint: 'Mobile number',
        prefix: AppCountryPrefix(
          country: controller.country.value,
          onTap: () => _pickCountry(context),
        ),
        suffixIcon: suffixIcon,
        keyboardType: TextInputType.phone,
        validator: controller.validateMobile,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(controller.country.value.maxLength),
        ],
      );

      if (controller.isEditing) return field();
      return field(
        suffixIcon: IconButton(
          tooltip: l10n('Import from phone contacts'),
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
      );
    });
  }

  Future<void> _pickCountry(BuildContext context) async {
    final selected = await showAppCountryPicker(
      context: context,
      value: controller.country.value,
    );
    if (selected != null) controller.selectCountry(selected);
  }
}

class _GstAddressCard extends StatelessWidget {
  const _GstAddressCard({required this.controller});

  final CustomerFormController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'GSTIN & Billing Address',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'B2B Ready',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Optional for B2B tax invoicing',
              style: AppTextStyles.small.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          children: [
            AppTextField(
              controller: controller.gstin,
              label: 'GSTIN',
              hint: '15-character GSTIN',
              prefixIcon: Icons.receipt_long_outlined,
              validator: controller.validateGstin,
              onChanged: controller.onGstinChanged,
              textCapitalization: TextCapitalization.characters,
              suffixIcon: Obx(
                () => controller.gstinLooksValid.value
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Looks valid',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(15),
                FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'GSTIN is optional for B2B tax invoices.',
              style: AppTextStyles.small.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller.companyName,
              label: 'Trade / Legal Business Name',
              prefixIcon: Icons.apartment_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller.address,
              label: 'Billing Address',
              prefixIcon: Icons.home_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            _PinAndStateRow(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _PinAndStateRow extends StatelessWidget {
  const _PinAndStateRow({required this.controller});

  final CustomerFormController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 360;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: AppTextField(
                controller: controller.pinCode,
                label: 'PIN code',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ),
            SizedBox(
              width: width,
              child: Obx(() {
                final current =
                    controller.gstState.value?.name ??
                    controller.state.text.trim();
                final options = <AppDropdownOption<String>>[
                  const AppDropdownOption(value: '', label: 'Select state'),
                  if (current.isNotEmpty &&
                      GstIndianStates.match(current) == null)
                    AppDropdownOption(value: current, label: current),
                  for (final state in GstIndianStates.all)
                    AppDropdownOption(value: state.name, label: state.label),
                ];
                return AppDropdownField<String>(
                  label: 'State',
                  value: current,
                  searchable: true,
                  searchHint: 'Search state',
                  emptyLabel: 'No matching state',
                  sheetTitle: 'Select state',
                  sheetHeightFactor: 0.75,
                  prefixIcon: Icons.map_outlined,
                  options: options,
                  onChanged: controller.selectGstStateName,
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _CreateInvoiceToggle extends StatelessWidget {
  const _CreateInvoiceToggle({required this.controller});

  final CustomerFormController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final checked = controller.createInvoiceAfterSave.value;
      return Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: controller.createInvoiceAfterSave.toggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (value) =>
                      controller.createInvoiceAfterSave.value = value ?? false,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Save and create new invoice immediately',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
