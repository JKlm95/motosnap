import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Motywy Material — dark automotive jako główny produktowy.
abstract final class AutomotiveAppTheme {
  static ThemeData dark() {
    const brightness = Brightness.dark;
    final scheme = const ColorScheme(
      brightness: brightness,
      primary: AppColors.primaryRed,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryRedDim,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.secondaryRed,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.surfaceHighlight,
      onSecondaryContainer: AppColors.textSecondary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      error: AppColors.error,
      onError: AppColors.errorForeground,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.errorForeground,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black87,
    );

    final textTheme = AppTextStyles.darkTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryRed.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.primaryRed : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primaryRed.withValues(alpha: 0.2),
        labelStyle: textTheme.labelMedium,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryRed,
        linearTrackColor: AppColors.divider,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );
  }

  static ThemeData light() {
    final dark = AutomotiveAppTheme.dark();
    return dark.copyWith(
      brightness: Brightness.light,
      colorScheme: dark.colorScheme.copyWith(
        brightness: Brightness.light,
        surface: AppColors.lightBackground,
        onSurface: const Color(0xFF18181B),
        surfaceContainerHighest: AppColors.lightSurface,
        surfaceContainerHigh: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: AppTextStyles.lightTextTheme(),
    );
  }
}
