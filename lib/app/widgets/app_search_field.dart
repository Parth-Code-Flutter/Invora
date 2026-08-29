import 'package:flutter/material.dart';

import '../localization/app_localization.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    required this.onChanged,
    this.controller,
    this.onClear,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: AppLocalizer.text(hint),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppLocalizer.text(hint),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: AppLocalizer.text('Clear search'),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? null
              : const Color(0xFFF1F5F9),
        ),
      ),
    );
  }
}
