import 'package:flutter/material.dart';

import '../../../../core/ui/app_motion.dart';
import '../../domain/vehicle_scan_status.dart';

/// Status skanu z lekką animacją (bez blur — bezpieczne w listach).
class ScanStatusBadge extends StatelessWidget {
  const ScanStatusBadge({
    required this.status,
    required this.label,
    this.dense = false,
    super.key,
  });

  final VehicleScanStatus status;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = switch (status) {
      VehicleScanStatus.waitingForRecognition => scheme.secondaryContainer,
      VehicleScanStatus.recognized => scheme.primaryContainer,
      VehicleScanStatus.failed => scheme.errorContainer,
      VehicleScanStatus.draft => scheme.surfaceContainerHigh,
    };
    final fg = switch (status) {
      VehicleScanStatus.failed => scheme.onErrorContainer,
      _ => scheme.onSurface,
    };

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusLeading(status: status, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLeading extends StatelessWidget {
  const _StatusLeading({required this.status, required this.color});

  final VehicleScanStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      VehicleScanStatus.waitingForRecognition => _PulsingDot(color: color),
      VehicleScanStatus.recognized => _RecognizedCheck(color: color),
      VehicleScanStatus.failed => Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: color,
      ),
      VehicleScanStatus.draft => Icon(
        Icons.edit_note_rounded,
        size: 16,
        color: color,
      ),
    };
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.45,
          end: 1,
        ).animate(CurvedAnimation(parent: _c, curve: AppMotion.snappy)),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class _RecognizedCheck extends StatefulWidget {
  const _RecognizedCheck({required this.color});

  final Color color;

  @override
  State<_RecognizedCheck> createState() => _RecognizedCheckState();
}

class _RecognizedCheckState extends State<_RecognizedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: AppMotion.emphasizedDecelerate,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.65, end: 1.0).animate(_scale),
      child: Icon(Icons.check_rounded, size: 16, color: widget.color),
    );
  }
}

/// Mała plakietka „poprawione przez użytkownika” (bez animacji agresywnych).
class UserCorrectedBadge extends StatelessWidget {
  const UserCorrectedBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
