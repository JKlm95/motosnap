import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';

/// Pierścień pewności + etykieta poziomu (wysoka/średnia/niska).
class ConfidenceViz extends StatelessWidget {
  const ConfidenceViz({required this.s, required this.confidence, super.key});

  final AppStrings s;
  final double confidence;

  String _levelLabel() {
    if (confidence >= 0.75) {
      return s.confidenceHigh;
    }
    if (confidence >= 0.45) {
      return s.confidenceMedium;
    }
    return s.confidenceLow;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (confidence * 100).clamp(0, 100).round();
    final label = _levelLabel();
    final isHigh = confidence >= 0.75;

    return Semantics(
      label: '${s.fieldConfidence}: $pct%. $label',
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confidence),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _ConfidenceRingPainter(
                    value: value,
                    color: scheme.primary,
                    trackColor: scheme.onSurface.withValues(alpha: 0.12),
                    glow: isHigh && value >= 0.7,
                  ),
                  child: Center(
                    child: Text(
                      '$pct%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fieldConfidence,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceRingPainter extends CustomPainter {
  _ConfidenceRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.glow,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 5.0;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final center = rect.center;
    final radius = rect.shortestSide / 2;

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius + 2, glowPaint);
    }

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      track,
    );

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweep = math.max(0.0, math.min(1.0, value)) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.glow != glow;
  }
}
