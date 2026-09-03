import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../localization/app_localization.dart';
import '../themes/app_text_styles.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.sheetTitle,
    this.prefixIcon,
    this.enabled = true,
    this.searchable = false,
    this.sheetHeightFactor,
    super.key,
  });

  final String label;
  final T value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? sheetTitle;
  final IconData? prefixIcon;
  final bool enabled;
  final bool searchable;
  final double? sheetHeightFactor;

  AppDropdownOption<T> get _selected => options.firstWhere(
    (option) => option.value == value,
    orElse: () => options.first,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizer.text(label),
      value: AppLocalizer.text(_selected.label),
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => _showOptions(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isFocused: false,
          isEmpty: false,
          isHovering: false,
          decoration: InputDecoration(
            enabled: enabled,
            labelText: AppLocalizer.text(label),
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            AppLocalizer.text(_selected.label),
            style: enabled
                ? null
                : AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showAppDropdownSheet<T>(
      context: context,
      title: AppLocalizer.text(sheetTitle ?? 'Select $label'),
      value: value,
      options: options,
      searchable: searchable,
      heightFactor: sheetHeightFactor,
    );
    if (selected != null) onChanged(selected);
  }
}

Future<T?> showAppDropdownSheet<T>({
  required BuildContext context,
  required String title,
  required T value,
  required List<AppDropdownOption<T>> options,
  bool searchable = false,
  String searchHint = 'Search categories',
  String emptyLabel = 'No matching category',
  double? heightFactor,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final requestedHeight = heightFactor == null
      ? null
      : MediaQuery.sizeOf(context).height * heightFactor;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _DropdownSheet<T>(
      title: title,
      value: value,
      options: options,
      searchable: searchable,
      searchHint: searchHint,
      emptyLabel: emptyLabel,
      requestedHeight: requestedHeight,
    ),
  );
}

class _DropdownSheet<T> extends StatefulWidget {
  const _DropdownSheet({
    required this.title,
    required this.value,
    required this.options,
    required this.searchable,
    this.searchHint = 'Search categories',
    this.emptyLabel = 'No matching category',
    this.requestedHeight,
  });

  final String title;
  final T value;
  final List<AppDropdownOption<T>> options;
  final bool searchable;
  final String searchHint;
  final String emptyLabel;
  final double? requestedHeight;

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where(
          (option) => option.label.toLowerCase().contains(query.toLowerCase()),
        )
        .toList(growable: false);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        mainAxisSize: widget.requestedHeight == null
            ? MainAxisSize.min
            : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppTextStyles.sectionTitle),
          if (widget.searchable) ...[
            const SizedBox(height: 14),
            TextField(
              autofocus: false,
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: InputDecoration(
                hintText: AppLocalizer.text(widget.searchHint),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Flexible(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.emptyLabel,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final option = filtered[index];
                      return _DropdownOptionTile<T>(
                        option: option,
                        selected: option.value == widget.value,
                        onTap: () => Navigator.pop(context, option.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
    if (widget.requestedHeight == null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: content,
      );
    }
    return SizedBox(height: widget.requestedHeight, child: content);
  }
}

class _DropdownOptionTile<T> extends StatelessWidget {
  const _DropdownOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppDropdownOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primaryLight : AppColors.surfaceSoft,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 21,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : null,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey(true),
                      color: AppColors.primary,
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      key: ValueKey(false),
                      color: AppColors.border,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
