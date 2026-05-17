import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const LinearGradient scaffold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0D0F), AppColors.background],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xE6000000)],
    stops: [0.35, 1.0],
  );

  static const LinearGradient detailHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0A0A0B)],
    stops: [0.45, 1.0],
  );

  static Gradient primaryGlow(Color base) => RadialGradient(
    colors: [base.withValues(alpha: 0.35), base.withValues(alpha: 0)],
  );
}
