import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Facade — implementacja w [AutomotiveAppTheme].
abstract final class AppTheme {
  static ThemeData light() => AutomotiveAppTheme.light();

  static ThemeData dark() => AutomotiveAppTheme.dark();
}
