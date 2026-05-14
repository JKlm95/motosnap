import 'package:flutter/material.dart';

/// Lekki shimmer (jeden gradient w animacji) — używać oszczędnie, np. skeleton.
class MotoShimmer extends StatefulWidget {
  const MotoShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<MotoShimmer> createState() => _MotoShimmerState();
}

class _MotoShimmerState extends State<MotoShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ?? scheme.surfaceContainerHigh;
    final hi =
        widget.highlightColor ??
        scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.09);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1.0 + t * 2.0, 0),
                end: Alignment(0.2 + t * 2.0, 0),
                colors: [base, hi, base],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
