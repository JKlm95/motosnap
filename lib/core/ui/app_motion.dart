import 'package:flutter/material.dart';

/// Wspólne czasy i krzywe animacji — lekkie, bez ciężkich efektów na słabszych Androidach.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  /// Dekodowanie / pierwsza klatka sieci — krótki fade, bez „skoku” obrazka.
  static const Duration imageFade = Duration(milliseconds: 160);

  static const Curve emphasizedDecelerate = Curves.easeOutCubic;
  static const Curve standard = Curves.easeOut;
  static const Curve snappy = Curves.easeInOut;
}
