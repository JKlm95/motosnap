import 'package:flutter/material.dart';

/// Czasy animacji — spójne z [AppMotion], osobna warstwa theme.
abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve snappy = Curves.easeInOut;
}
