import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
        fontFamily: AppTextStyles.fontFamily,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.pageTitle.copyWith(
          color: colorScheme.onSurface,
        ),
        toolbarHeight: 64,
        leadingWidth: 52,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 1,
        shadowColor: const Color(0x160F172A),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0x99E5E8F1),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceMuted;
            }
            return AppColors.secondary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textTertiary;
            }
            return Colors.white;
          }),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: .12),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.button),
          iconSize: const WidgetStatePropertyAll(19),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.secondary,
          backgroundColor: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceSoft,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.secondary,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.minTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: .6)
                : AppColors.border.withValues(alpha: .7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceMuted,
        selectedColor: AppColors.secondary,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.secondary
                : isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceSoft,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : colorScheme.onSurface,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.bottomSheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        titleTextStyle: AppTextStyles.sectionTitle.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.textPrimary,
        contentTextStyle: AppTextStyles.secondaryBody.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.caption),
      ),
    );
  }
}
