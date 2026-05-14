import 'dart:ui';

import 'package:flutter/material.dart';

/// Szkło: blur + półprzezroczyste tło + subtelna obwódka i cień.
///
/// Gdy [blurSigma] == 0, pomija [BackdropFilter] (tańszy fallback, wyższy kontrast).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    super.key,
    this.blurSigma = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
    this.borderWidth = 1,
  });

  final Widget child;
  final double blurSigma;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = scheme.surface.withValues(alpha: isDark ? 0.42 : 0.52);
    final borderColor = scheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.10,
    );

    final decoration = BoxDecoration(
      borderRadius: borderRadius,
      color: blurSigma <= 0 ? scheme.surfaceContainerHigh : fill,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: isDark ? 0.35 : 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );

    final inner = Padding(padding: padding, child: child);

    if (blurSigma <= 0) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(decoration: decoration, child: inner),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(decoration: decoration, child: inner),
      ),
    );
  }
}
