import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/ui/app_motion.dart';
import '../../domain/vehicle_info.dart';
import '../widgets/confidence_viz.dart';

/// Kaskadowe ujawnienie pól po udanym AI (krótkie, bez sztucznego czekania).
class ScanDetailVehicleRevealCard extends StatefulWidget {
  const ScanDetailVehicleRevealCard({
    required this.s,
    required this.info,
    required this.revealToken,
    super.key,
  });

  final AppStrings s;
  final VehicleInfo info;
  final int revealToken;

  @override
  State<ScanDetailVehicleRevealCard> createState() =>
      _ScanDetailVehicleRevealCardState();
}

class _ScanDetailVehicleRevealCardState
    extends State<ScanDetailVehicleRevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.revealToken > 0) {
      _c.forward(from: 0);
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ScanDetailVehicleRevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealToken != oldWidget.revealToken && widget.revealToken > 0) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _fadeSlide({required Interval interval, required Widget child}) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = interval.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final info = widget.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fadeSlide(
              interval: const Interval(
                0,
                0.22,
                curve: AppMotion.emphasizedDecelerate,
              ),
              child: _row(
                context,
                s.fieldType,
                s.vehicleType(info.vehicleType),
              ),
            ),
            _fadeSlide(
              interval: const Interval(0.12, 0.38, curve: Curves.easeOutCubic),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(context, s.fieldBrand, info.brand ?? s.emDash),
                  _row(context, s.fieldModel, info.model ?? s.emDash),
                  _row(context, s.fieldGeneration, info.generation ?? s.emDash),
                ],
              ),
            ),
            _fadeSlide(
              interval: const Interval(
                0.28,
                0.52,
                curve: AppMotion.emphasizedDecelerate,
              ),
              child: _row(
                context,
                s.fieldProductionYears,
                info.productionYears ?? s.emDash,
              ),
            ),
            if (info.possibleEngines.isNotEmpty)
              _fadeSlide(
                interval: const Interval(
                  0.4,
                  0.62,
                  curve: AppMotion.emphasizedDecelerate,
                ),
                child: _row(
                  context,
                  s.fieldEnginesHint,
                  info.possibleEngines.join(', '),
                ),
              ),
            if (info.confidence != null)
              _fadeSlide(
                interval: const Interval(
                  0.48,
                  0.78,
                  curve: AppMotion.emphasizedDecelerate,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ConfidenceViz(s: s, confidence: info.confidence!),
                ),
              ),
            if (info.confidence == null)
              _fadeSlide(
                interval: const Interval(
                  0.48,
                  0.78,
                  curve: AppMotion.emphasizedDecelerate,
                ),
                child: _row(context, s.fieldConfidence, s.emDash),
              ),
            if (info.shortDescription != null &&
                info.shortDescription!.isNotEmpty)
              _fadeSlide(
                interval: const Interval(
                  0.65,
                  1,
                  curve: AppMotion.emphasizedDecelerate,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    info.shortDescription!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
