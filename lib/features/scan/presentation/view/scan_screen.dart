import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/ui/app_motion.dart';
import '../../../../core/ui/app_shape.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final bottomPad = MainShellLayout.paddingOf(context);

    return BlocListener<ScanCubit, ScanState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase &&
          (next.phase == ScanFlowPhase.success ||
              next.phase == ScanFlowPhase.error),
      listener: (context, state) {
        if (state.phase == ScanFlowPhase.success) {
          AppHaptics.success();
        } else if (state.phase == ScanFlowPhase.error) {
          AppHaptics.error();
        }
      },
      child: BlocBuilder<ScanCubit, ScanState>(
        builder: (context, state) {
          final busy =
              state.phase == ScanFlowPhase.requestingPermissions ||
              state.phase == ScanFlowPhase.capturing ||
              state.phase == ScanFlowPhase.saving;

          final showRadar =
              state.phase != ScanFlowPhase.success &&
              state.phase != ScanFlowPhase.error &&
              !busy;

          String? flowHint() {
            return switch (state.phase) {
              ScanFlowPhase.saving => s.scanFlowSaving,
              _ => null,
            };
          }

          return Scaffold(
            appBar: AppBar(title: Text(s.scanTabTitle)),
            body: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.scanIntro,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (flowHint() != null) ...[
                    Text(
                      flowHint()!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.phase == ScanFlowPhase.success &&
                      state.savedScan != null)
                    _SuccessCard(
                      s: s,
                      scan: state.savedScan!,
                      backgroundQueued: state.backgroundQueued,
                    )
                  else if (state.errorMessage != null)
                    _ErrorCard(
                      message: state.errorMessage!,
                      dismissLabel: s.ok,
                      onDismiss: () =>
                          context.read<ScanCubit>().clearTransient(),
                    ),
                  if (state.phase == ScanFlowPhase.success ||
                      state.errorMessage != null)
                    const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.headerImage),
                      child: ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 24,
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 56,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.22),
                              ),
                            ),
                            if (showRadar) const _RadarPulse(),
                            _ScanCaptureControl(
                              busy: busy,
                              label: s.scanButton,
                              semanticLabel: s.scanButton,
                              onCapture: () {
                                AppHaptics.lightImpact();
                                context.read<ScanCubit>().captureAndSaveScan(
                                  lang,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.phase == ScanFlowPhase.success) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<ScanCubit>().clearTransient(),
                      child: Text(s.nextScan),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 2; i++)
                  _ring(context, primary, (_c.value + i * 0.5) % 1.0),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ring(BuildContext context, Color primary, double t) {
    final scale = 0.88 + t * 0.28;
    final opacity = (1 - t) * 0.35;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: IgnorePointer(
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primary.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanCaptureControl extends StatefulWidget {
  const _ScanCaptureControl({
    required this.busy,
    required this.label,
    required this.semanticLabel,
    required this.onCapture,
  });

  final bool busy;
  final String label;
  final String semanticLabel;
  final VoidCallback onCapture;

  @override
  State<_ScanCaptureControl> createState() => _ScanCaptureControlState();
}

class _ScanCaptureControlState extends State<_ScanCaptureControl> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = (widget.busy || _pressed) ? 0.92 : 1.0;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: !widget.busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: scale,
            duration: AppMotion.fast,
            curve: AppMotion.snappy,
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
                        widget.onCapture();
                      },
                child: Ink(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.busy
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: scheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.photo_camera_rounded,
                            size: 44,
                            color: scheme.primary,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.s,
    required this.scan,
    required this.backgroundQueued,
  });

  final AppStrings s;
  final VehicleScan scan;
  final bool backgroundQueued;

  @override
  Widget build(BuildContext context) {
    final recognized =
        scan.status == VehicleScanStatus.recognized &&
        scan.effectiveVehicleInfo != null;
    final failed = scan.status == VehicleScanStatus.failed;
    final title = recognized
        ? s.scanSavedRecognized
        : failed
        ? s.scanSavedRecognitionFailed
        : backgroundQueued
        ? s.scanSavedBackgroundRecognition
        : s.scanSavedLocally;

    final String subtitle;
    if (recognized) {
      final info = scan.effectiveVehicleInfo!;
      final parts = <String>[
        s.vehicleType(info.vehicleType),
        if ((info.brand ?? '').isNotEmpty) info.brand!,
        if ((info.model ?? '').isNotEmpty) info.model!,
      ].where((e) => e.isNotEmpty).toList();
      subtitle = parts.isEmpty
          ? s.scanSavedStatusLine(s.scanStatus(scan.status))
          : parts.join(' · ');
    } else if (failed) {
      subtitle =
          (scan.recognitionError != null && scan.recognitionError!.isNotEmpty)
          ? scan.recognitionError!
          : s.scanSavedStatusLine(s.scanStatus(scan.status));
    } else if (backgroundQueued) {
      subtitle = scan.pendingSync
          ? s.scanBackgroundProcessingQueued
          : s.scanRecognitionRunningInBackground;
    } else {
      subtitle = s.scanSavedStatusLine(s.scanStatus(scan.status));
    }

    return GlassCard(
      blurSigma: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 6),
          if (!recognized &&
              !failed &&
              backgroundQueued &&
              !scan.pendingSync &&
              scan.status == VehicleScanStatus.waitingForRecognition)
            Text(
              s.scanRecognitionRunningInBackground,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else if (!recognized && !failed && scan.pendingSync)
            Text(
              s.scanAiPendingHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else if (!recognized &&
              !failed &&
              !scan.pendingSync &&
              scan.status == VehicleScanStatus.waitingForRecognition)
            Text(
              s.scanAiPendingCloudHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else if (failed)
            Text(
              s.scanAiRetryFromDetailsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String message;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDismiss,
                child: Text(dismissLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
