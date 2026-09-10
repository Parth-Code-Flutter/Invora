import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/business_icons.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_country_picker.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/services/gst_indian_states.dart';
import '../controllers/customer_form_controller.dart';

abstract final class _CustomerUi {
  static const page = AppColors.background;
  static const ink = Color(0xFF1C1917);
  static const body = Color(0xFF78716C);
  static const muted = Color(0xFFA8A29E);
  static const line = Color(0xFFE7E5E4);
  static const roseFill = Color(0xFFFFF1F2);
  static const roseText = Color(0xFFBE123C);
  static const coral = Color(0xFFF43F5E);
  static const gstWellFill = Color(0xFFFAF5FF);
  static const gstWellBorder = Color(0x80E9D5FF);
  static const b2bFill = Color(0xFFECFDF5);
  static const b2bText = Color(0xFF047857);
  static const cardRadius = 16.0;
  static const appBarHeight = 64.0;
}

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkBackground : _CustomerUi.page;
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Scaffold(
        backgroundColor: page,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(_CustomerUi.appBarHeight),
          child: _CustomerAppBar(
            title: controller.isEditing ? 'Edit customer' : 'Add Customer',
            page: page,
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
                      12,
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CustomerCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _CoreDetailsHeader(),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: controller.name,
                                      label: 'Customer / Shop Name *',
                                      hint: 'e.g. Ramesh Patel or Acme Traders',
                                      prefixIconWidget: const _FieldGlyph(
                                        BusinessIcons.store,
                                      ),
                                      validator: controller.validateName,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    const SizedBox(height: 12),
                                    _PhoneField(controller: controller),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _GstAddressCard(controller: controller),
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
                12,
                ResponsiveUtils.horizontalPadding(context),
                12,
              ),
              child: AppConstrainedAction(
                maxWidth: ResponsiveUtils.formMaxWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!controller.isEditing && !controller.isInvoiceFlow) ...[
                      _CreateInvoiceToggle(controller: controller),
                      const SizedBox(height: 12),
                    ],
                    Obx(
                      () => AppButton(
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
                        radius: 16,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.save,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Instant offline save • Stays on this device',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : _CustomerUi.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerAppBar extends StatelessWidget {
  const _CustomerAppBar({required this.title, required this.page});

  final String title;
  final Color page;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: page,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _CustomerUi.appBarHeight,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0x80E7E5E4),
              ),
            ),
          ),
          child: Row(
            children: [
              const _BackCircle(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : _CustomerUi.ink,
                    fontSize: 20,
                    height: 24 / 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
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

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Tooltip(
        message: MaterialLocalizations.of(context).backButtonTooltip,
        child: Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => AppFocus.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0x99E7E5E4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const _FieldGlyph(BusinessIcons.back, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(_CustomerUi.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : _CustomerUi.line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
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
            color: _CustomerUi.coral,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'CORE DETAILS',
            style: AppTextStyles.small.copyWith(
              color: isDark ? AppColors.darkTextSecondary : _CustomerUi.body,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _CustomerUi.roseFill,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'FAST BILLING',
            style: AppTextStyles.small.copyWith(
              color: _CustomerUi.roseText,
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
        hint: '98765 43210',
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
              : const _FieldGlyph(BusinessIcons.contacts, size: 16),
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

class _GstAddressCard extends StatefulWidget {
  const _GstAddressCard({required this.controller});

  final CustomerFormController controller;

  @override
  State<_GstAddressCard> createState() => _GstAddressCardState();
}

class _GstAddressCardState extends State<_GstAddressCard> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _CustomerCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(_CustomerUi.cardRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : _CustomerUi.gstWellFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : _CustomerUi.gstWellBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const _FieldGlyph(BusinessIcons.gst, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GSTIN & Billing Address',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : _CustomerUi.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Optional for B2B tax invoicing',
                          style: AppTextStyles.small.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : _CustomerUi.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : _CustomerUi.b2bFill,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'B2B Ready',
                      style: AppTextStyles.small.copyWith(
                        color: _CustomerUi.b2bText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : _CustomerUi.body,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: widget.controller.gstin,
                    label: 'GSTIN (Goods and Services Tax ID)',
                    hint: '24AAAAA0000A1Z5',
                    prefixIconWidget: const _FieldGlyph(
                      BusinessIcons.gst,
                      size: 16,
                    ),
                    validator: widget.controller.validateGstin,
                    onChanged: widget.controller.onGstinChanged,
                    textCapitalization: TextCapitalization.characters,
                    suffixIcon: Obx(
                      () => widget.controller.gstinLooksValid.value
                          ? const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Center(child: _LooksValidChip()),
                            )
                          : const SizedBox.shrink(),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : _CustomerUi.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'GSTIN is optional for B2B tax invoices.',
                          style: AppTextStyles.small.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : _CustomerUi.muted,
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: widget.controller.companyName,
                    label: 'Trade / Legal Business Name',
                    hint: 'Registered business name',
                    prefixIconWidget: const _FieldGlyph(BusinessIcons.identity),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: widget.controller.address,
                    label: 'Billing Address',
                    hint: 'Shop/Office no., building, street, area...',
                    prefixIcon: Icons.home_outlined,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _PinAndStateRow(controller: widget.controller),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LooksValidChip extends StatelessWidget {
  const _LooksValidChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Looks valid',
            style: AppTextStyles.small.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
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
                label: 'Pincode',
                hint: '380015',
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
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.createInvoiceAfterSave.toggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _CoralCheck(checked: checked),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Save and create new invoice immediately',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : _CustomerUi.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 20 / 13.5,
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

class _CoralCheck extends StatelessWidget {
  const _CoralCheck({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked
            ? _CustomerUi.coral
            : isDark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked
              ? _CustomerUi.coral
              : isDark
              ? AppColors.darkBorder
              : _CustomerUi.line,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _FieldGlyph extends StatelessWidget {
  const _FieldGlyph(this.asset, {this.size = 16});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        width: size,
        height: size,
      ),
    );
  }
}
