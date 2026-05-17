import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typografia dashboard / cockpit — Inter + Rajdhani.
abstract final class AppTextStyles {
  static TextTheme darkTextTheme() {
    final inter = GoogleFonts.interTextTheme();
    final rajdhani = GoogleFonts.rajdhani();

    TextStyle interStyle(
      TextStyle? base, {
      FontWeight? weight,
      double? size,
      double? height,
      double? spacing,
      Color? color,
    }) {
      return GoogleFonts.inter(
        textStyle: base,
        fontWeight: weight ?? base?.fontWeight,
        fontSize: size ?? base?.fontSize,
        height: height ?? base?.height,
        letterSpacing: spacing ?? base?.letterSpacing,
        color: color ?? base?.color ?? AppColors.textPrimary,
      );
    }

    TextStyle rajdhaniStyle({
      required double size,
      FontWeight weight = FontWeight.w600,
      Color? color,
      double? spacing,
    }) {
      return rajdhani.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: spacing ?? 0.5,
        height: 1.1,
      );
    }

    return TextTheme(
      displayLarge: rajdhaniStyle(size: 36, weight: FontWeight.w700),
      displayMedium: rajdhaniStyle(size: 30, weight: FontWeight.w600),
      headlineLarge: rajdhaniStyle(size: 26, weight: FontWeight.w600),
      headlineMedium: rajdhaniStyle(size: 22, weight: FontWeight.w600),
      headlineSmall: interStyle(
        inter.titleLarge,
        weight: FontWeight.w600,
        size: 18,
      ),
      titleLarge: interStyle(
        inter.titleLarge,
        weight: FontWeight.w600,
        size: 17,
      ),
      titleMedium: interStyle(
        inter.titleMedium,
        weight: FontWeight.w600,
        size: 15,
      ),
      titleSmall: interStyle(
        inter.titleSmall,
        weight: FontWeight.w600,
        size: 13,
      ),
      bodyLarge: interStyle(
        inter.bodyLarge,
        size: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: interStyle(
        inter.bodyMedium,
        size: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: interStyle(
        inter.bodySmall,
        size: 12,
        color: AppColors.textSecondary,
      ),
      labelLarge: interStyle(
        inter.labelLarge,
        weight: FontWeight.w600,
        size: 13,
      ),
      labelMedium: interStyle(
        inter.labelMedium,
        weight: FontWeight.w600,
        size: 11,
        color: AppColors.textMuted,
      ),
      labelSmall: interStyle(
        inter.labelSmall,
        weight: FontWeight.w600,
        size: 10,
        color: AppColors.textMuted,
      ),
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }

  static TextTheme lightTextTheme() {
    final base = darkTextTheme();
    return base.apply(
      bodyColor: const Color(0xFF18181B),
      displayColor: const Color(0xFF18181B),
    );
  }

  /// Etykieta telemetry (confidence, status techniczny).
  static TextStyle telemetry(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color:
          color ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
  }

  static TextStyle badge(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
  }
}
