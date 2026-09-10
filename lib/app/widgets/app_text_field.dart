import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../localization/app_localization.dart';
import '../themes/app_text_styles.dart';
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
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.prefixIconWidget,
    this.prefix,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.errorText,
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
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? prefixIconWidget;
  final Widget? prefix;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? suffixText;
  final String? errorText;
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
    final resolvedMaxLines = obscureText ? 1 : maxLines;
    final resolvedMinLines = obscureText
        ? 1
        : (minLines ?? (resolvedMaxLines > 1 ? resolvedMaxLines : 1));
    final multiline = resolvedMinLines > 1 || resolvedMaxLines > 1;
    final iconConstraints = multiline
        ? AppSpacing.multilineInputIconConstraints
        : AppSpacing.inputIconConstraints;
    final icon = prefixIconWidget != null
        ? Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 4,
              top: multiline ? 10 : 0,
            ),
            child: prefixIconWidget,
          )
        : prefixIcon == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 4,
              top: multiline ? 10 : 0,
            ),
            child: Icon(prefixIcon, color: AppColors.primary, size: 18),
          );
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
        minLines: resolvedMinLines,
        maxLines: resolvedMaxLines,
        maxLength: maxLength,
        obscureText: obscureText,
        autocorrect: !obscureText,
        enableSuggestions: !obscureText,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: autofillHints,
        textAlignVertical: AppTextStyles.inputAlign(
          maxLines: resolvedMaxLines,
          minLines: resolvedMinLines,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint == null || hint!.trim().isEmpty
              ? null
              : AppLocalizer.text(hint),
          hintStyle: AppTextStyles.hintFor(context),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          alignLabelWithHint: multiline,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          prefixIconConstraints: iconConstraints,
          prefixIcon: prefix ?? icon,
          prefixText: prefixText,
          suffixIcon: suffixIcon,
          suffixText: suffixText,
          suffixIconConstraints: iconConstraints,
          errorText: errorText,
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
