import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// Karta w stylu „glass” — używać oszczędnie (np. wyróżnienie, nie całe długie listy).
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.blurSigma = 12,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final Widget child;
  final double blurSigma;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }
}
