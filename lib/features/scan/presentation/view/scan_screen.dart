import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';
import '../widgets/premium_capture_button.dart';
import '../widgets/scan_camera_overlay.dart';

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

          final showOverlay =
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
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(s.scanTabTitle),
              backgroundColor: Colors.transparent,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.phase == ScanFlowPhase.success &&
                    state.savedScan != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      kToolbarHeight + 8,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: _SuccessCard(
                      s: s,
                      scan: state.savedScan!,
                      backgroundQueued: state.backgroundQueued,
                    ),
                  )
                else if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      kToolbarHeight + 8,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: _ErrorCard(
                      message: state.errorMessage!,
                      dismissLabel: s.ok,
                      onDismiss: () =>
                          context.read<ScanCubit>().clearTransient(),
                    ),
                  ),
                if (flowHint() != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      8,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: Text(
                      flowHint()!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      state.phase == ScanFlowPhase.success ||
                              state.errorMessage != null
                          ? AppSpacing.sm
                          : kToolbarHeight + 4,
                      AppSpacing.sm,
                      bottomPad + AppSpacing.md,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.header),
                      child: ColoredBox(
                        color: AppColors.surfaceElevated,
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.2),
                                  radius: 1.1,
                                  colors: [
                                    AppColors.surfaceHighlight.withValues(
                                      alpha: 0.5,
                                    ),
                                    AppColors.surface,
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 48,
                              color: AppColors.textMuted.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            if (showOverlay) const ScanCameraOverlay(),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: AppSpacing.xl,
                              child: PremiumCaptureButton(
                                busy: busy,
                                label: s.scanButton,
                                onPressed: busy
                                    ? null
                                    : () {
                                        AppHaptics.lightImpact();
                                        context
                                            .read<ScanCubit>()
                                            .captureAndSaveScan(lang);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.phase == ScanFlowPhase.success)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      0,
                      AppSpacing.screenH,
                      bottomPad > 0 ? 4 : AppSpacing.md,
                    ),
                    child: OutlinedButton(
                      onPressed: () =>
                          context.read<ScanCubit>().clearTransient(),
                      child: Text(s.nextScan),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      0,
                      AppSpacing.screenH,
                      bottomPad > 0 ? 0 : AppSpacing.md,
                    ),
                    child: Text(
                      s.scanIntro,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          if (!recognized &&
              !failed &&
              backgroundQueued &&
              !scan.pendingSync &&
              scan.status == VehicleScanStatus.waitingForRecognition)
            Text(
              s.scanRecognitionRunningInBackground,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (!recognized && !failed && scan.pendingSync)
            Text(
              s.scanAiPendingHint,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (!recognized &&
              !failed &&
              !scan.pendingSync &&
              scan.status == VehicleScanStatus.waitingForRecognition)
            Text(
              s.scanAiPendingCloudHint,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (failed)
            Text(
              s.scanAiRetryFromDetailsHint,
              style: Theme.of(context).textTheme.bodySmall,
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
      color: AppColors.error,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.errorForeground),
            ),
            const SizedBox(height: AppSpacing.sm),
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
