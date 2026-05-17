import 'package:flutter/material.dart';

/// Paleta MotoSnap — dark automotive premium (Ferrari / Porsche / AMG / Tesla vibe).
abstract final class AppColors {
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF151618);
  static const Color surfaceElevated = Color(0xFF1D1F22);
  static const Color surfaceHighlight = Color(0xFF25282C);

  static const Color primaryRed = Color(0xFFE10600);
  static const Color secondaryRed = Color(0xFFFF3B30);
  static const Color primaryRedDim = Color(0xFFB80500);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  static const Color divider = Color(0xFF2B2D31);
  static const Color outline = Color(0xFF3F4248);

  /// Ciemna zieleń premium (success) — nie neon.
  static const Color success = Color(0xFF1B4332);
  static const Color successForeground = Color(0xFF95D5B2);
  static const Color warning = Color(0xFF78350F);
  static const Color warningForeground = Color(0xFFFCD34D);
  static const Color error = Color(0xFF7F1D1D);
  static const Color errorForeground = Color(0xFFFCA5A5);

  static const Color shutterCenter = Color(0xFFF4F4F5);
  static const Color shutterRing = Color(0xFFE10600);

  /// Jasny motyw — uproszczony, spójny z tokenami (ustawienia).
  static const Color lightBackground = Color(0xFFF4F4F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
}
