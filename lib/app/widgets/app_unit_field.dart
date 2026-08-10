import 'package:flutter/material.dart';

import '../../data/services/unit_service.dart';
import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_notification.dart';

class AppUnitField extends StatelessWidget {
  const AppUnitField({
    required this.value,
    required this.unitService,
    required this.onChanged,
    this.label = 'Unit *',
    super.key,
  });

  final String value;
  final UnitService unitService;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    value: value,
    child: InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.straighten_rounded),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(value),
      ),
    ),
  );

  Future<void> _pick(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) =>
          _UnitSheet(selected: value, unitService: unitService),
    );
    if (selected != null) onChanged(selected);
  }
}

class _UnitSheet extends StatefulWidget {
  const _UnitSheet({required this.selected, required this.unitService});
  final String selected;
  final UnitService unitService;

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  late List<String> units = widget.unitService.units;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .7,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Choose unit', style: AppTextStyles.sectionTitle),
              ),
              TextButton.icon(
                onPressed: _createUnit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create unit'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select a common unit or save one you use regularly.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisExtent: 56,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: units.length,
              itemBuilder: (_, index) {
                final unit = units[index];
                final selected = unit == widget.selected;
                return Material(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, unit),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              unit,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? AppColors.primary : null,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _createUnit() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create unit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Unit name',
            hintText: 'e.g. bundle, plate, session',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save unit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (created == null || created.trim().isEmpty) return;
    try {
      final unit = await widget.unitService.create(created);
      if (!mounted) return;
      setState(() => units = widget.unitService.units);
      Navigator.pop(context, unit);
    } on ArgumentError {
      AppNotification.warning(
        'Unit required',
        'Enter a unit name to continue.',
      );
    }
  }
}
