import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// Opcjonalna plakietka ze szkłem — **nie** używać w wierszach przewijanych list (koszt blur).
/// Domyślnie blur wyłączony (bezpieczny overlay / nagłówek).
class GlassStatusBadge extends StatelessWidget {
  const GlassStatusBadge({
    required this.child,
    super.key,
    this.blurSigma = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Widget child;
  final double blurSigma;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      blurSigma: blurSigma,
      borderRadius: BorderRadius.circular(999),
      padding: padding,
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600),
        child: child,
      ),
    );
  }
}
