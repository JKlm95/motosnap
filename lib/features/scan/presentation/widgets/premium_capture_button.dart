import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_effects.dart';

/// Premium camera shutter — biały środek, czerwony pierścień, delikatny glow.
class PremiumCaptureButton extends StatefulWidget {
  const PremiumCaptureButton({
    required this.busy,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool busy;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<PremiumCaptureButton> createState() => _PremiumCaptureButtonState();
}

class _PremiumCaptureButtonState extends State<PremiumCaptureButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = (widget.busy || _pressed) ? 0.94 : 1.0;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: scale,
          duration: AppDurations.fast,
          curve: AppDurations.snappy,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTapDown: widget.busy
                  ? null
                  : (_) => setState(() => _pressed = true),
              onTapCancel: widget.busy
                  ? null
                  : () => setState(() => _pressed = false),
              onTap: widget.busy
                  ? null
                  : () {
                      setState(() => _pressed = false);
                      widget.onPressed?.call();
                    },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.shutterRing,
                    width: _pressed ? 5 : 4,
                  ),
                  boxShadow: AppEffects.shutterGlow(pressed: _pressed),
                ),
                child: Center(
                  child: widget.busy
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryRed,
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.shutterCenter,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
