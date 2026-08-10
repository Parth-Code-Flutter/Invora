import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/unit_settings_controller.dart';

class UnitSettingsScreen extends GetView<UnitSettingsController> {
  const UnitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Set default unit'),
      actions: [
        IconButton(
          tooltip: 'Add unit',
          onPressed: () => _showEditor(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your default is preselected whenever you create a new item. Existing invoices and saved products stay unchanged.',
                    style: AppTextStyles.secondaryBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available units',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(
              () => ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: controller.units.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final unit = controller.units[index];
                  final selected = controller.selectedDefault.value == unit;
                  return _UnitTile(
                    unit: unit,
                    selected: selected,
                    onSelect: () => controller.setDefault(unit),
                    onEdit: () => _showEditor(context, unit: unit),
                    onDelete: () => _confirmDelete(context, unit),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showEditor(BuildContext context, {String? unit}) async {
    final input = TextEditingController(text: unit ?? '');
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(unit == null ? 'Add a unit' : 'Rename unit'),
          content: TextField(
            controller: input,
            autofocus: true,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: 'Unit name',
              hintText: 'e.g. bundle',
              errorText: error,
            ),
            onSubmitted: (_) => _saveUnit(
              dialogContext,
              unit,
              input.text,
              (value) => setState(() => error = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveUnit(
                dialogContext,
                unit,
                input.text,
                (value) => setState(() => error = value),
              ),
              child: Text(unit == null ? 'Add unit' : 'Save'),
            ),
          ],
        ),
      ),
    );
    input.dispose();
  }

  Future<void> _saveUnit(
    BuildContext context,
    String? current,
    String value,
    ValueChanged<String?> showError,
  ) async {
    final result = current == null
        ? await controller.create(value)
        : await controller.rename(current, value);
    if (result != null) {
      showError(result);
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> _confirmDelete(BuildContext context, String unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unit?'),
        content: Text(
          'Remove “$unit” from future unit choices? Existing records using it will not change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await controller.delete(unit);
    if (error != null) Get.snackbar('Cannot delete unit', error);
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final String unit;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primaryLight : Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    ),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.straighten_rounded,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit, style: AppTextStyles.cardTitle),
                  if (selected)
                    Text(
                      'Default unit',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Rename $unit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Delete $unit',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
