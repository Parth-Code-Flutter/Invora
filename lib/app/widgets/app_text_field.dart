import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../localization/app_localization.dart';
import 'app_field_label.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.requiredField = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
    this.focusBorderColor,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool requiredField;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final Color? focusBorderColor;

  @override
  Widget build(BuildContext context) {
    final focusColor = focusBorderColor;
    return AppLabeledField(
      label: label,
      requiredField: requiredField,
      helperText: helperText,
      child: TextFormField(
        controller: controller,
        validator: validator == null
            ? null
            : (value) {
                final error = validator!(value);
                return error == null ? null : AppLocalizer.text(error);
              },
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        autocorrect: !obscureText,
        enableSuggestions: !obscureText,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: autofillHints,
        textAlignVertical: maxLines > 1
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizer.text(hint),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          alignLabelWithHint: maxLines > 1,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          prefixIconConstraints: AppSpacing.inputIconConstraints,
          prefixIcon:
              prefix ??
              (prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        prefixIcon,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    )),
          suffixIcon: suffixIcon,
          suffixIconConstraints: AppSpacing.inputIconConstraints,
          focusedBorder: focusColor == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: BorderSide(color: focusColor, width: 2),
                ),
        ),
      ),
    );
  }
}
