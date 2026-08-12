import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/business_category_model.dart';
import '../../../data/models/product_attribute_model.dart';
import '../controllers/product_settings_controller.dart';

class ProductSettingsScreen extends GetView<ProductSettingsController> {
  const ProductSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Product settings'),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 720,
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Icon(
                    Icons.storefront_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text('Business category'),
                subtitle: Text(controller.category.value.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseCategory(context),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.showOnInvoice.value,
                onChanged: controller.setShowOnInvoice,
                title: const Text('Show product details on invoice'),
                subtitle: const Text(
                  'Only non-empty values are shown compactly.',
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Product fields',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addCustomField(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Custom field'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ...ProductFieldPresets.fields.map(
                    (field) => CheckboxListTile(
                      value: controller.enabledFields.contains(field.key),
                      onChanged: (value) =>
                          controller.toggleField(field.key, value ?? false),
                      title: Text(field.label),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  ...controller.customFields.map(
                    (field) => CheckboxListTile(
                      value: controller.enabledFields.contains(field.key),
                      onChanged: (value) =>
                          controller.toggleField(field.key, value ?? false),
                      title: Text(field.label),
                      subtitle: Text('Custom ${field.type.name} field'),
                      secondary: IconButton(
                        tooltip: 'Delete custom field',
                        onPressed: () => controller.deleteCustomField(field),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _chooseCategory(BuildContext context) async {
    final selected = await showModalBottomSheet<BusinessCategory>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => RadioGroup<BusinessCategory>(
        groupValue: controller.category.value,
        onChanged: (value) => Navigator.pop(context, value),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'What type of business do you run?',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            ...BusinessCategory.values.map(
              (value) => RadioListTile<BusinessCategory>(
                value: value,
                title: Text(value.label),
              ),
            ),
          ],
        ),
      ),
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
    input.dispose();
  }
}
