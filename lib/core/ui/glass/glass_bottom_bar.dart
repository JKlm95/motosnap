import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// Poziomy „pasek” szkła (np. nawigacja) — ten sam styl co [GlassSurface], zaokrąglony pill.
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    required this.child,
    super.key,
    this.blurSigma = 16,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });

  final Widget child;
  final double blurSigma;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      blurSigma: blurSigma,
      borderRadius: borderRadius ?? BorderRadius.circular(999),
      padding: padding,
      child: child,
    );
  }
}
