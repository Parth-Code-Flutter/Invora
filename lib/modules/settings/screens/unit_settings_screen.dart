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
            child: Obx(() {
              // Read both reactive values while Obx is building. Reading
              // selectedDefault only inside ListView's lazy itemBuilder does
              // not register it as an Obx dependency, so a tap would persist
              // correctly without repainting the selected tile.
              final units = controller.units.toList(growable: false);
              final selectedDefault = controller.selectedDefault.value;
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: units.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return _UnitTile(
                    unit: unit,
                    selected: selectedDefault == unit,
                    onSelect: () => controller.setDefault(unit),
                    onEdit: () => _showEditor(context, unit: unit),
                    onDelete: () => _confirmDelete(context, unit),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
  );

  Future<void> _showEditor(BuildContext context, {String? unit}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _UnitEditorDialog(current: unit, controller: controller),
    );
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

class _UnitEditorDialog extends StatefulWidget {
  const _UnitEditorDialog({required this.controller, this.current});

  final UnitSettingsController controller;
  final String? current;

  @override
  State<_UnitEditorDialog> createState() => _UnitEditorDialogState();
}

class _UnitEditorDialogState extends State<_UnitEditorDialog> {
  late final TextEditingController input = TextEditingController(
    text: widget.current ?? '',
  );
  String? error;
  bool saving = false;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    final result = widget.current == null
        ? await widget.controller.create(input.text)
        : await widget.controller.rename(widget.current!, input.text);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        saving = false;
        error = result;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'Add a unit' : 'Rename unit'),
    content: TextField(
      controller: input,
      autofocus: true,
      enabled: !saving,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Unit name',
        hintText: 'e.g. bundle',
        errorText: error,
      ),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        child: saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.current == null ? 'Add unit' : 'Save'),
      ),
    ],
  );
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
