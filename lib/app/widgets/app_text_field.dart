import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final IconData? prefixIcon;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIconConstraints: const BoxConstraints(minWidth: 50),
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 9, right: 7),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(prefixIcon, color: AppColors.primary, size: 17),
                ),
              ),
      ),
    );
  }
}
