import 'package:flutter/material.dart';

import '../../data/services/account_phone.dart';
import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_dropdown_field.dart';

Future<AccountCountry?> showAppCountryPicker({
  required BuildContext context,
  required AccountCountry value,
}) {
  return showAppDropdownSheet<AccountCountry>(
    context: context,
    title: 'Choose country',
    value: value,
    searchable: true,
    heightFactor: 0.75,
    searchHint: 'Search country',
    emptyLabel: 'No matching country',
    options: [
      for (final country in AccountCountry.all)
        AppDropdownOption(value: country, label: country.pickerLabel),
    ],
  );
}

/// Flag + dial-code control used on account OTP and party phone fields.
class AppCountryPrefix extends StatelessWidget {
  const AppCountryPrefix({
    required this.country,
    required this.onTap,
    super.key,
  });

  final AccountCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              country.e164Prefix,
              style: AppTextStyles.listName.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            Container(
              width: 1,
              height: 18,
              margin: const EdgeInsets.only(left: 6, right: 4),
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
