import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cienie i glow — używaj oszczędnie (wydajność).
abstract final class AppEffects {
  static List<BoxShadow> cardElevation = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> navBar = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.55),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> shutterGlow({bool pressed = false}) => [
    BoxShadow(
      color: AppColors.primaryRed.withValues(alpha: pressed ? 0.55 : 0.38),
      blurRadius: pressed ? 28 : 20,
      spreadRadius: pressed ? 1 : 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static BorderSide accentBorder({double width = 1}) => BorderSide(
    color: AppColors.primaryRed.withValues(alpha: 0.65),
    width: width,
  );
}
