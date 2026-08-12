import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/unit_settings_controller.dart';

class UnitSettingsScreen extends GetView<UnitSettingsController> {
  const UnitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Set default unit'),
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available units', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 3),
                    Text(
                      'Tap a unit to make it your default',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Obx(() {
              // Read both reactive values while Obx is building. Reading
              // selectedDefault only inside ListView's lazy itemBuilder does
              // not register it as an Obx dependency, so a tap would persist
              // correctly without repainting the selected tile.
              final units = controller.units.toList(growable: false);
              final selectedDefault = controller.selectedDefault.value;
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisExtent: 56,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return _UnitTile(
                    unit: unit,
                    selected: selectedDefault == unit,
                    onSelect: () => controller.setDefault(unit),
                    onActions: () => _showActions(
                      context,
                      unit: unit,
                      selected: selectedDefault == unit,
                    ),
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

  Future<void> _showActions(
    BuildContext context, {
    required String unit,
    required bool selected,
  }) async {
    final action = await showModalBottomSheet<_UnitAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(unit, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(
              'Choose what you want to do with this unit.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              enabled: !selected,
              leading: Icon(
                selected ? Icons.check_circle_rounded : Icons.check_rounded,
                color: selected ? AppColors.success : AppColors.primary,
              ),
              title: Text(selected ? 'Current default' : 'Set as default'),
              subtitle: const Text('Preselect for newly created items'),
              onTap: selected
                  ? null
                  : () => Navigator.pop(sheetContext, _UnitAction.setDefault),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit unit'),
              subtitle: const Text('Rename this unit everywhere it is offered'),
              onTap: () => Navigator.pop(sheetContext, _UnitAction.edit),
            ),
            ListTile(
              textColor: AppColors.error,
              iconColor: AppColors.error,
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete unit'),
              subtitle: const Text('Existing records remain unchanged'),
              onTap: () => Navigator.pop(sheetContext, _UnitAction.delete),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _UnitAction.setDefault:
        await controller.setDefault(unit);
      case _UnitAction.edit:
        await _showEditor(context, unit: unit);
      case _UnitAction.delete:
        await _confirmDelete(context, unit);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
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
  Widget build(BuildContext context) => AppDialog(
    icon: Icons.straighten_rounded,
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
    required this.onActions,
  });

  final String unit;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary : Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    ),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .18)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.straighten_rounded,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 15,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actions for $unit',
              onPressed: onActions,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum _UnitAction { setDefault, edit, delete }
