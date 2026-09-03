import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../localization/app_localization.dart';

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
    return TextFormField(
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
      decoration: InputDecoration(
        labelText: AppLocalizer.text(label),
        hintText: AppLocalizer.text(hint),
        alignLabelWithHint: maxLines > 1,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIconConstraints: prefix == null
            ? const BoxConstraints(minWidth: 50)
            : const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon:
            prefix ??
            (prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 9, right: 7),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        prefixIcon,
                        color: AppColors.primary,
                        size: 17,
                      ),
                    ),
                  )),
        suffixIcon: suffixIcon,
        floatingLabelStyle: focusColor == null
            ? null
            : TextStyle(color: focusColor, fontWeight: FontWeight.w700),
        focusedBorder: focusColor == null
            ? null
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: BorderSide(color: focusColor, width: 2),
              ),
      ),
    );
  }
}
