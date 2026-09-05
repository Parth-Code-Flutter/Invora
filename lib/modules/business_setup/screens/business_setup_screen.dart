import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/business_icons.dart';
import '../../../app/localization/app_localization.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/business_category_model.dart';
import '../controllers/business_setup_controller.dart';

abstract final class _ProfileUi {
  static const page = Color(0xFFFAF9F7);
  static const ink = Color(0xFF1C1917);
  static const stone = Color(0xFF44403C);
  static const body = Color(0xFF78716C);
  static const muted = Color(0xFFA8A29E);
  static const line = Color(0xFFE7E5E4);
  static const hairline = Color(0xFFF5F5F4);
  static const fieldFill = Color(0x66FAFAF9);
  static const roseFill = Color(0xFFFFF1F2);
  static const roseBorder = Color(0x99FECDD3);
  static const roseText = Color(0xFFBE123C);
  static const liveFill = Color(0xFFECFDF5);
  static const liveBorder = Color(0x99A7F3D0);
  static const liveText = Color(0xFF047857);
  static const liveDot = Color(0xFF10B981);
  static const whatsapp = Color(0xFF059669);
  static const identityFill = Color(0xFFFFF7ED);
  static const identityBorder = Color(0x80FED7AA);
  static const contactFill = Color(0xFFFAF5FF);
  static const contactBorder = Color(0x80E9D5FF);
  static const gstFill = Color(0xFFFDF2F8);
  static const gstBorder = Color(0x80FBCFE8);
  static const requiredStar = Color(0xFFF43F5E);
  static const logoStart = Color(0xFFF43F5E);
  static const logoEnd = Color(0xFFFB7185);
}

class BusinessSetupScreen extends GetView<BusinessSetupController> {
  const BusinessSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkBackground : _ProfileUi.page;
    return UnsavedChangesScope(
      hasChanges: () => controller.hasUnsavedChanges,
      child: Theme(
        data: Theme.of(context).copyWith(scaffoldBackgroundColor: page),
        child: Scaffold(
          backgroundColor: page,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Obx(() {
              if (controller.isLoading.value) {
                return Material(color: page, child: const SizedBox(height: 66));
              }
              return _ProfileAppBar(
                isEditing: controller.isEditing,
                page: page,
                onPreview: () => _showBillPreview(context),
              );
            }),
          ),
          body: Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : AppFormCanvas(
                    child: Form(
                      key: controller.formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          _ReactivePreview(controller: controller),
                          const SizedBox(height: 16),
                          _IdentityCard(controller: controller),
                          const SizedBox(height: 16),
                          _ContactCard(controller: controller),
                          const SizedBox(height: 16),
                          _OptionalTaxCard(controller: controller),
                        ],
                      ),
                    ),
                  ),
          ),
          bottomNavigationBar: Obx(() {
            if (controller.isLoading.value) return const SizedBox.shrink();
            return _ProfileBottomBar(
              isEditing: controller.isEditing,
              isSaving: controller.isSaving.value,
              onSave: controller.save,
            );
          }),
        ),
      ),
    );
  }

  void _showBillPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preview bill',
              style: AppTextStyles.sectionTitle.copyWith(
                color: _ProfileUi.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ReactivePreview(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({
    required this.isEditing,
    required this.page,
    required this.onPreview,
  });

  final bool isEditing;
  final Color page;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: page.withValues(alpha: .9),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0x80E7E5E4),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isEditing) ...[
                const _BackCircle(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isEditing ? 'Edit Business Profile' : 'Business Profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _ProfileUi.ink,
                        fontSize: 17,
                        height: 21.25 / 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.425,
                      ),
                    ),
                    Text(
                      'Receipt & Invoice Branding',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : _ProfileUi.body,
                        fontSize: 11,
                        height: 16.5 / 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PreviewBillButton(onPressed: onPreview),
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
          elevation: 0,
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
              child: const _AssetIcon(BusinessIcons.back, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBillButton extends StatelessWidget {
  const _PreviewBillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ProfileUi.roseFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 5, 13, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _ProfileUi.roseBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _AssetIcon(BusinessIcons.preview, size: 12),
              const SizedBox(width: 6),
              Text(
                'Preview bill',
                style: AppTextStyles.small.copyWith(
                  color: _ProfileUi.roseText,
                  fontSize: 11,
                  height: 16.5 / 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactivePreview extends StatelessWidget {
  const _ReactivePreview({required this.controller});

  final BusinessSetupController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.businessName,
        controller.mobile,
        controller.invoicePrefix,
        controller.startingInvoiceNumber,
      ]),
      builder: (context, _) => Obx(
        () => _LivePreviewSection(
          name: controller.businessName.text.trim(),
          category: controller.businessCategory.value.label,
          mobile: controller.mobile.text,
          logoPath: controller.logoPath.value,
          invoiceNumber: _previewInvoiceNumber(
            controller.invoicePrefix.text,
            controller.startingInvoiceNumber.text,
          ),
        ),
      ),
    );
  }
}

class _LivePreviewSection extends StatelessWidget {
  const _LivePreviewSection({
    required this.name,
    required this.category,
    required this.mobile,
    required this.logoPath,
    required this.invoiceNumber,
  });

  final String name;
  final String category;
  final String mobile;
  final String? logoPath;
  final String invoiceNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'LIVE BILL PREVIEW',
                style: AppTextStyles.small.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : _ProfileUi.body,
                  fontSize: 10,
                  height: 15 / 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(9, 2.5, 9, 2.75),
                decoration: BoxDecoration(
                  color: _ProfileUi.liveFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _ProfileUi.liveBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _ProfileUi.liveDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updates live',
                      style: AppTextStyles.small.copyWith(
                        color: _ProfileUi.liveText,
                        fontSize: 9.5,
                        height: 14.25 / 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Thermal & PDF ready',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(
                  color: _ProfileUi.muted,
                  fontSize: 10.5,
                  height: 15.75 / 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _LiveBillCard(
          name: name,
          category: category,
          mobile: mobile,
          logoPath: logoPath,
          invoiceNumber: invoiceNumber,
        ),
      ],
    );
  }
}

class _LiveBillCard extends StatelessWidget {
  const _LiveBillCard({
    required this.name,
    required this.category,
    required this.mobile,
    required this.logoPath,
    required this.invoiceNumber,
  });

  final String name;
  final String category;
  final String mobile;
  final String? logoPath;
  final String invoiceNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = name.isEmpty ? 'Your business' : name;
    final formattedMobile = _spacedMobile(mobile);
    final subtitle = formattedMobile.isEmpty
        ? category
        : '$category • +91 $formattedMobile';
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xE6E7E5E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF43F5E),
                  Color(0xFFEC4899),
                  Color(0xFF9333EA),
                ],
              ),
            ),
            child: SizedBox(height: 4, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 21, 17, 17),
            child: Row(
              children: [
                _PreviewMark(name: displayName, logoPath: logoPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.listName.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : _ProfileUi.ink,
                                fontSize: 14,
                                height: 17.5 / 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _ProfileUi.roseFill,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0x80FECDD3),
                              ),
                            ),
                            child: Text(
                              'LIVE',
                              style: AppTextStyles.small.copyWith(
                                color: _ProfileUi.roseText,
                                fontSize: 9,
                                height: 13.5 / 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : _ProfileUi.body,
                          fontSize: 11,
                          height: 16.5 / 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.only(left: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _ProfileUi.hairline),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'INVOICE',
                        style: AppTextStyles.small.copyWith(
                          color: _ProfileUi.muted,
                          fontSize: 9,
                          height: 13.5 / 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                        ),
                      ),
                      Text(
                        invoiceNumber,
                        style: AppTextStyles.small.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF292524),
                          fontSize: 11.5,
                          height: 17.25 / 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMark extends StatelessWidget {
  const _PreviewMark({required this.name, required this.logoPath});

  final String name;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final validLogo = logoPath != null && File(logoPath!).existsSync();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66FECDD3)),
        gradient: validLogo
            ? null
            : const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [_ProfileUi.logoStart, _ProfileUi.logoEnd],
              ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: validLogo
          ? Image.file(
              File(logoPath!),
              fit: BoxFit.cover,
              width: 48,
              height: 48,
            )
          : Text(
              _businessInitials(name),
              style: AppTextStyles.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
                height: 28 / 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.45,
              ),
            ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.controller});

  final BusinessSetupController controller;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      iconAsset: BusinessIcons.identity,
      iconFill: _ProfileUi.identityFill,
      iconBorder: _ProfileUi.identityBorder,
      title: 'Identity & Brand',
      trailing: 'Receipt Header',
      child: Column(
        children: [
          Obx(() {
            final logoPath = controller.logoPath.value;
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.businessName,
              builder: (context, value, _) => _StoreLogoRow(
                name: value.text.trim(),
                path: logoPath,
                onChange: controller.pickLogo,
                onRemove: logoPath == null
                    ? null
                    : () => _confirmLogoRemoval(context, controller),
              ),
            );
          }),
          const SizedBox(height: 16),
          _ProfileField(
            controller: controller.businessName,
            label: 'Business Name',
            requiredField: true,
            hint: 'Appears on top of all receipts',
            prefixAsset: BusinessIcons.store,
            validator: controller.requiredBusinessName,
            textCapitalization: TextCapitalization.words,
            autofocus: !controller.isEditing,
          ),
          const SizedBox(height: 16),
          Obx(
            () => _ProfileSelectField<BusinessCategory>(
              label: 'Store Category',
              hint: 'Customizes bill layout',
              prefixAsset: BusinessIcons.category,
              value: controller.businessCategory.value,
              sheetTitle: 'Choose your business category',
              options: BusinessCategory.values
                  .map(
                    (value) =>
                        AppDropdownOption(value: value, label: value.label),
                  )
                  .toList(growable: false),
              onChanged: (value) => controller.businessCategory.value = value,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogoRemoval(
    BuildContext context,
    BusinessSetupController controller,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove business logo?'),
        content: const Text(
          'Future invoices will use your business initials instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep logo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) controller.removeLogo();
  }
}

class _StoreLogoRow extends StatelessWidget {
  const _StoreLogoRow({
    required this.name,
    required this.path,
    required this.onChange,
    required this.onRemove,
  });

  final String name;
  final String? path;
  final VoidCallback onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLogo = path != null && File(path!).existsSync();
    final displayName = name.isEmpty ? 'Your business' : name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0x80FAFAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xCCE7E5E4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 58,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 6,
                  child: Semantics(
                    button: true,
                    label: hasLogo
                        ? 'Change business logo'
                        : 'Add business logo',
                    child: InkWell(
                      onTap: onChange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xE6E7E5E4)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: hasLogo
                            ? Image.file(
                                File(path!),
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                              )
                            : Text(
                                _businessInitials(displayName),
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: const Color(0xFFE11D48),
                                  fontSize: 20,
                                  height: 28 / 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _ProfileUi.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const _AssetIcon(BusinessIcons.camera, size: 12),
                    ),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Semantics(
                      button: true,
                      label: 'Remove logo',
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF292524),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const _AssetIcon(
                            BusinessIcons.close,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Logo',
                  style: AppTextStyles.small.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : _ProfileUi.ink,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap logo to upload or change • PNG, JPG up to 5MB',
                  style: AppTextStyles.small.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : _ProfileUi.body,
                    fontSize: 11,
                    height: 13.75 / 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.controller});

  final BusinessSetupController controller;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      iconAsset: BusinessIcons.contact,
      iconFill: _ProfileUi.contactFill,
      iconBorder: _ProfileUi.contactBorder,
      title: 'Contact on Invoices',
      trailing: 'Bill Footer & Header',
      child: Column(
        children: [
          _ProfileField(
            controller: controller.ownerName,
            label: 'Owner / Signatory Name',
            prefixAsset: BusinessIcons.owner,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _MobileField(controller: controller),
        ],
      ),
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({required this.controller});

  final BusinessSetupController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _FieldLabel(
                label: 'Invoice Mobile / WhatsApp',
                requiredField: true,
              ),
            ),
            Text(
              'WhatsApp Ready',
              style: AppTextStyles.small.copyWith(
                color: _ProfileUi.whatsapp,
                fontSize: 10,
                height: 16 / 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5.4),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : _ProfileUi.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : _ProfileUi.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 11, 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : const Color(0x80F5F5F4),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: isDark ? AppColors.darkBorder : _ProfileUi.line,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '🇮🇳',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF292524),
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const _AssetIcon(BusinessIcons.countryChevron, size: 12),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller.mobile,
                  validator: (value) {
                    final error = controller.validateMobile(value);
                    return error == null ? null : AppLocalizer.text(error);
                  },
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : _ProfileUi.ink,
                    fontSize: 13.5,
                    height: 24 / 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.fromLTRB(10, 10, 8, 10),
                    hintText: '98765 43210',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Obx(
                  () => Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: controller.isPickingContact.value
                          ? null
                          : controller.pickInvoiceContact,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xCCE7E5E4),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: controller.isPickingContact.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const _AssetIcon(
                                BusinessIcons.contacts,
                                size: 16,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Printed on customer receipts for digital WhatsApp invoice sharing',
          style: AppTextStyles.small.copyWith(
            color: isDark ? AppColors.darkTextSecondary : _ProfileUi.body,
            fontSize: 10.5,
            height: 15.75 / 10.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _OptionalTaxCard extends StatelessWidget {
  const _OptionalTaxCard({required this.controller});

  final BusinessSetupController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shadowColor: const Color(0x08000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xB3E7E5E4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          trailing: const _AssetIcon(BusinessIcons.chevron, size: 16),
          title: Row(
            children: [
              const _TintedIcon(
                asset: BusinessIcons.gst,
                fill: _ProfileUi.gstFill,
                border: _ProfileUi.gstBorder,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GSTIN, UPI QR & Bill Numbering',
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _ProfileUi.ink,
                        fontSize: 13,
                        height: 16.25 / 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Optional • Configure anytime for B2B & QR payments',
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : _ProfileUi.body,
                        fontSize: 10.5,
                        height: 15.75 / 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : _ProfileUi.hairline,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Optional',
                  style: AppTextStyles.small.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF57534E),
                    fontSize: 10,
                    height: 15 / 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _ResponsiveFields(
                    children: [
                      AppTextField(controller: controller.city, label: 'City'),
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
                          FilteringTextInputFormatter.digitsOnly,
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
                      subtitle: const Text('Enable GST details on invoices'),
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
                          validator: controller.validatePan,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.allow(
                              RegExp('[0-9a-zA-Z]'),
                            ),
                          ],
                        ),
                        AppTextField(
                          controller: controller.invoicePrefix,
                          label: 'Invoice prefix',
                          hint: 'INV',
                          validator: controller.validateInvoicePrefix,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.allow(
                              RegExp('[0-9a-zA-Z-]'),
                            ),
                          ],
                        ),
                        AppTextField(
                          controller: controller.startingInvoiceNumber,
                          label: 'Starting invoice number',
                          hint: '1',
                          keyboardType: TextInputType.number,
                          validator: controller.validateStartingInvoiceNumber,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                        ),
                        AppDropdownField<String>(
                          label: 'Currency',
                          sheetTitle: 'Choose currency',
                          prefixIcon: Icons.currency_exchange_rounded,
                          value: controller.currencyCode.value,
                          options: BusinessSetupController.currencies.entries
                              .map(
                                (entry) => AppDropdownOption(
                                  value: entry.key,
                                  label: '${entry.key} (${entry.value})',
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              controller.currencyCode.value = value,
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
                        controller: controller.accountHolderName,
                        label: 'Account holder',
                      ),
                      AppTextField(
                        controller: controller.accountNumber,
                        label: 'Account number',
                        keyboardType: TextInputType.number,
                        validator: controller.validateAccountNumber,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(18),
                        ],
                      ),
                      AppTextField(
                        controller: controller.ifsc,
                        label: 'IFSC',
                        validator: controller.validateIfsc,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          FilteringTextInputFormatter.allow(
                            RegExp('[0-9a-zA-Z]'),
                          ),
                        ],
                      ),
                      AppTextField(
                        controller: controller.upiId,
                        label: 'UPI ID',
                        keyboardType: TextInputType.emailAddress,
                        validator: controller.validateUpiId,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(321),
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
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
                            onTap: () => controller.pickSignature(context),
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
    );
  }
}

class _ProfileBottomBar extends StatelessWidget {
  const _ProfileBottomBar({
    required this.isEditing,
    required this.isSaving,
    required this.onSave,
  });

  final bool isEditing;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: (isDark ? AppColors.darkBackground : _ProfileUi.page).withValues(
        alpha: .95,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0x99E7E5E4),
              ),
            ),
          ),
          child: AppConstrainedAction(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: isEditing
                      ? 'Save & update invoices'
                      : 'Save & start invoicing',
                  leading: const _AssetIcon(BusinessIcons.check, size: 16),
                  radius: 16,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _AssetIcon(BusinessIcons.lock, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Encrypted & stored offline on this device',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.small.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : _ProfileUi.body,
                          fontSize: 10.5,
                          height: 15.75 / 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.iconAsset,
    required this.iconFill,
    required this.iconBorder,
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String iconAsset;
  final Color iconFill;
  final Color iconBorder;
  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xB3E7E5E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _ProfileUi.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  _TintedIcon(
                    asset: iconAsset,
                    fill: iconFill,
                    border: iconBorder,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.small.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _ProfileUi.ink,
                        fontSize: 13,
                        height: 19.5 / 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    trailing,
                    style: AppTextStyles.small.copyWith(
                      color: _ProfileUi.muted,
                      fontSize: 10.5,
                      height: 15.75 / 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.prefixAsset,
    this.requiredField = false,
    this.hint,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String prefixAsset;
  final bool requiredField;
  final String? hint;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _FieldLabel(label: label, requiredField: requiredField),
            ),
            if (hint != null)
              Flexible(
                child: Text(
                  hint!,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.small.copyWith(
                    color: _ProfileUi.muted,
                    fontSize: 10,
                    height: 16 / 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator == null
              ? null
              : (value) {
                  final error = validator!(value);
                  return error == null ? null : AppLocalizer.text(error);
                },
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkTextPrimary : _ProfileUi.ink,
            fontSize: 13.5,
            height: 24 / 13.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceVariant
                : _ProfileUi.fieldFill,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: _AssetIcon(prefixAsset, size: 16),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 16,
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : _ProfileUi.line,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : _ProfileUi.line,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSelectField<T> extends StatelessWidget {
  const _ProfileSelectField({
    required this.label,
    required this.hint,
    required this.prefixAsset,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.sheetTitle,
  });

  final String label;
  final String hint;
  final String prefixAsset;
  final T value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final String sheetTitle;

  AppDropdownOption<T> get _selected => options.firstWhere(
    (option) => option.value == value,
    orElse: () => options.first,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _FieldLabel(label: label)),
            Text(
              hint,
              style: AppTextStyles.small.copyWith(
                color: _ProfileUi.muted,
                fontSize: 10,
                height: 16 / 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: label,
          value: _selected.label,
          child: Material(
            color: isDark ? AppColors.darkSurfaceVariant : _ProfileUi.fieldFill,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                final selected = await showAppDropdownSheet<T>(
                  context: context,
                  title: sheetTitle,
                  value: value,
                  options: options,
                  searchable: true,
                  heightFactor: .75,
                );
                if (selected != null) onChanged(selected);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : _ProfileUi.line,
                  ),
                ),
                child: Row(
                  children: [
                    _AssetIcon(prefixAsset, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selected.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : _ProfileUi.ink,
                          fontSize: 13.5,
                          height: 24 / 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const _AssetIcon(BusinessIcons.chevron, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.requiredField = false});

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: isDark ? AppColors.darkTextSecondary : _ProfileUi.stone,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (requiredField) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTextStyles.small.copyWith(
              color: _ProfileUi.requiredStar,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TintedIcon extends StatelessWidget {
  const _TintedIcon({
    required this.asset,
    required this.fill,
    required this.border,
  });

  final String asset;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: _AssetIcon(asset, size: 14),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  const _AssetIcon(this.asset, {required this.size});

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
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
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
    final validPath = path != null && File(path!).existsSync();
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
        child: !validPath
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

String _businessInitials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'YB';
  if (words.length == 1) {
    final word = words.first;
    return word.length == 1
        ? word.toUpperCase()
        : word.substring(0, 2).toUpperCase();
  }
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String _spacedMobile(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) return digits;
  return '${digits.substring(0, 5)} ${digits.substring(5)}';
}

String _previewInvoiceNumber(String prefix, String starting) {
  final cleanPrefix = prefix.trim().isEmpty
      ? 'INV'
      : prefix.trim().toUpperCase();
  final number = int.tryParse(starting.trim()) ?? 1;
  return '#$cleanPrefix-${number.toString().padLeft(3, '0')}';
}
