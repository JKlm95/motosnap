import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Subtelna ramka focus + scan line (premium AI scanner, bez gamingu).
class ScanCameraOverlay extends StatefulWidget {
  const ScanCameraOverlay({super.key});

  @override
  State<ScanCameraOverlay> createState() => _ScanCameraOverlayState();
}

class _ScanCameraOverlayState extends State<ScanCameraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final inset = w * 0.08;
          final frameW = w - inset * 2;
          final frameH = h * 0.52;
          final top = (h - frameH) * 0.42;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: inset,
                top: top,
                width: frameW,
                height: frameH,
                child: CustomPaint(painter: _FocusFramePainter()),
              ),
              Positioned(
                left: inset + 12,
                width: frameW - 24,
                top: top,
                height: frameH,
                child: AnimatedBuilder(
                  animation: _line,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(0, -1 + 2 * _line.value),
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primaryRed.withValues(alpha: 0.85),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FocusFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const stroke = 1.4;
    final paint = Paint()
      ..color = AppColors.primaryRed.withValues(alpha: 0.75)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset o, {required bool top, required bool left}) {
      final dx = left ? 1 : -1;
      final dy = top ? 1 : -1;
      canvas.drawLine(o, o + Offset(len * dx, 0), paint);
      canvas.drawLine(o, o + Offset(0, len * dy), paint);
    }

    corner(const Offset(0, 0), top: true, left: true);
    corner(Offset(size.width, 0), top: true, left: false);
    corner(Offset(0, size.height), top: false, left: true);
    corner(Offset(size.width, size.height), top: false, left: false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
