import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/models/product_attribute_model.dart';
import '../controllers/product_settings_controller.dart';

class ProductSettingsScreen extends GetView<ProductSettingsController> {
  const ProductSettingsScreen({super.key});

  static const _systemFont = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final screenTheme = base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: _systemFont),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _systemFont),
    );
    return Theme(
      data: screenTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text(
            'Product settings',
            style: TextStyle(
              fontFamily: _systemFont,
              fontWeight: FontWeight.w700,
              letterSpacing: -.3,
            ),
          ),
        ),
        body: ResponsiveContent(
          tabletMaxWidth: 720,
          child: Obx(() => _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final enabledCount = controller.enabledFields.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _SettingsHero(
          category: controller.category.value.label,
          enabledCount: enabledCount,
          onCategoryTap: () => _chooseCategory(context),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconTile(
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
                background: AppColors.primaryLight,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show details on invoices',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Only completed values appear in a compact line.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: controller.showOnInvoice.value,
                onChanged: controller.setShowOnInvoice,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Product fields',
          subtitle: '$enabledCount enabled · tap a field to change it',
          action: TextButton.icon(
            onPressed: () => _addCustomField(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Custom'),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (
                var index = 0;
                index < ProductFieldPresets.fields.length;
                index++
              ) ...[
                _FieldRow(
                  field: ProductFieldPresets.fields[index],
                  enabled: controller.enabledFields.contains(
                    ProductFieldPresets.fields[index].key,
                  ),
                  onChanged: (value) => controller.toggleField(
                    ProductFieldPresets.fields[index].key,
                    value,
                  ),
                ),
                if (index != ProductFieldPresets.fields.length - 1)
                  const Divider(height: 1, indent: 58, endIndent: 16),
              ],
            ],
          ),
        ),
        if (controller.customFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionHeader(
            title: 'Custom fields',
            subtitle: 'Fields created specifically for your business',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < controller.customFields.length;
                  index++
                ) ...[
                  _CustomFieldRow(
                    field: controller.customFields[index],
                    enabled: controller.enabledFields.contains(
                      controller.customFields[index].key,
                    ),
                    onChanged: (value) => controller.toggleField(
                      controller.customFields[index].key,
                      value,
                    ),
                    onDelete: () => controller.deleteCustomField(
                      controller.customFields[index],
                    ),
                  ),
                  if (index != controller.customFields.length - 1)
                    const Divider(height: 1, indent: 58, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseCategory(BuildContext context) async {
    final selected = await showAppDropdownSheet<BusinessCategory>(
      context: context,
      title: 'Choose your business category',
      value: controller.category.value,
      searchable: true,
      heightFactor: .75,
      options: BusinessCategory.values
          .map((value) => AppDropdownOption(value: value, label: value.label))
          .toList(growable: false),
    );
    if (selected == null ||
        selected == controller.category.value ||
        !context.mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        icon: Icons.sync_alt_rounded,
        title: const Text('Change business category?'),
        content: const Text(
          'Recommended product fields will be updated. Your existing product information will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.changeCategory(selected);
  }

  Future<void> _addCustomField(BuildContext context) async {
    final input = TextEditingController();
    var type = ProductCustomFieldType.text;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          icon: Icons.add_box_outlined,
          title: const Text('Add custom field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: input,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Field name *',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ProductCustomFieldType>(
                segments: const [
                  ButtonSegment(
                    value: ProductCustomFieldType.text,
                    label: Text('Text'),
                  ),
                  ButtonSegment(
                    value: ProductCustomFieldType.number,
                    label: Text('Number'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) =>
                    setState(() => type = value.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await controller.addCustomField(
                  input.text,
                  type,
                );
                if (result == null && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (result != null) {
                  setState(() => error = result);
                }
              },
              child: const Text('Add field'),
            ),
          ],
        ),
      ),
    );
    // showDialog completes when the route starts popping, while its TextField
    // can remain mounted during the reverse transition. Let that transition
    // finish before releasing the controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.category,
    required this.enabledCount,
    required this.onCategoryTap,
  });

  final String category;
  final int enabledCount;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF713267), Color(0xFFB24D69)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: .18),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -42,
          top: -55,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shape your product form',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Keep only the details your business needs.',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$enabledCount on',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: onCategoryTap,
                borderRadius: BorderRadius.circular(17),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
                  child: Row(
                    children: [
                      const _IconTile(
                        icon: Icons.storefront_outlined,
                        color: AppColors.secondary,
                        background: AppColors.secondaryLight,
                        size: 38,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BUSINESS CATEGORY',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .65,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.enabled,
    required this.onChanged,
  });

  final ProductFieldDefinition field;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: enabled,
    label: field.label,
    child: InkWell(
      onTap: () => onChanged(!enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _SelectionMark(enabled: enabled),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                field.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
                  color: enabled
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              enabled ? 'Shown' : 'Hidden',
              style: TextStyle(
                color: enabled ? AppColors.primary : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CustomFieldRow extends StatelessWidget {
  const _CustomFieldRow({
    required this.field,
    required this.enabled,
    required this.onChanged,
    required this.onDelete,
  });

  final ProductCustomField field;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!enabled),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 7, 8),
      child: Row(
        children: [
          _SelectionMark(enabled: enabled),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${field.type.name} field',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete ${field.label}',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    ),
  );
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: enabled ? AppColors.primaryLight : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: enabled ? AppColors.primary : AppColors.border),
    ),
    child: Icon(
      enabled ? Icons.check_rounded : Icons.remove_rounded,
      size: 17,
      color: enabled ? AppColors.primary : AppColors.textTertiary,
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}
