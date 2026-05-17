import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../camera/scan_camera_controller.dart';
import '../camera/scan_camera_preview.dart';
import '../camera/scan_camera_state.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';
import '../widgets/premium_capture_button.dart';
import '../widgets/scan_camera_overlay.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ScanCameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = ScanCameraController()..attach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraController.setTabActive(MainShellLayout.scanTabActiveOf(context));
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onEmbeddedCapture(BuildContext context, String lang) async {
    final cubit = context.read<ScanCubit>();
    if (cubit.state.phase == ScanFlowPhase.saving ||
        cubit.state.phase == ScanFlowPhase.requestingPermissions) {
      return;
    }

    AppHaptics.lightImpact();
    final file = await _cameraController.takePicture();
    if (!context.mounted || file == null) {
      return;
    }
    await cubit.saveScanFromPhoto(file, lang);
  }

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
              state.phase == ScanFlowPhase.saving;

          final showHud =
              state.phase != ScanFlowPhase.success &&
              state.errorMessage == null &&
              !busy;

          final flowHint = state.phase == ScanFlowPhase.saving
              ? s.scanFlowSaving
              : null;

          return Scaffold(
            backgroundColor: AppColors.background,
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: AppBar(
              title: Text(s.scanTabTitle),
              backgroundColor: Colors.transparent,
              actions: [
                if (showHud) ...[
                  ListenableBuilder(
                    listenable: _cameraController,
                    builder: (context, _) {
                      final cam = _cameraController.state;
                      if (!cam.supportsFlash) {
                        return const SizedBox.shrink();
                      }
                      final on = cam.flashMode != FlashMode.off;
                      return IconButton(
                        tooltip: on ? s.scanFlashOff : s.scanFlashOn,
                        onPressed: () {
                          AppHaptics.selection();
                          _cameraController.toggleFlash();
                        },
                        icon: Icon(
                          on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: on ? AppColors.primaryRed : null,
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<_ScanCaptureSource>(
                    tooltip: s.scanOpenGallery,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (source) async {
                      final cubit = context.read<ScanCubit>();
                      switch (source) {
                        case _ScanCaptureSource.gallery:
                          await cubit.importFromGallery(lang);
                        case _ScanCaptureSource.systemCamera:
                          await cubit.captureAndSaveScan(lang);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: _ScanCaptureSource.gallery,
                        child: Text(s.scanOpenGallery),
                      ),
                      PopupMenuItem(
                        value: _ScanCaptureSource.systemCamera,
                        child: Text(s.scanSystemCamera),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                ScanCameraPreview(
                  controller: _cameraController,
                  onTapFocus: (p) {
                    AppHaptics.lightImpact();
                    _cameraController.setFocusPoint(p);
                  },
                ),
                if (showHud) ...[
                  const ScanCameraOverlay(),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                    left: AppSpacing.screenH,
                    child: _LiveIndicator(label: s.scanLivePreview),
                  ),
                ],
                ListenableBuilder(
                  listenable: _cameraController,
                  builder: (context, _) {
                    if (_cameraController.state.lifecycle !=
                        ScanCameraLifecycle.permissionDenied) {
                      return const SizedBox.shrink();
                    }
                    return _PermissionBanner(
                      message: s.scanCameraPermissionHint,
                      onRetry: _cameraController.retryAfterPermission,
                    );
                  },
                ),
                if (flowHint != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          flowHint,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.primaryRed),
                        ),
                      ),
                    ),
                  ),
                if (state.phase == ScanFlowPhase.success &&
                    state.savedScan != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                    left: AppSpacing.screenH,
                    right: AppSpacing.screenH,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.28,
                      ),
                      child: SingleChildScrollView(
                        child: _SuccessCard(
                          s: s,
                          scan: state.savedScan!,
                          backgroundQueued: state.backgroundQueued,
                          onDismiss: () =>
                              context.read<ScanCubit>().clearTransient(),
                        ),
                      ),
                    ),
                  )
                else if (state.errorMessage != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                    left: AppSpacing.screenH,
                    right: AppSpacing.screenH,
                    child: _ErrorCard(
                      message: state.errorMessage!,
                      dismissLabel: s.ok,
                      onDismiss: () =>
                          context.read<ScanCubit>().clearTransient(),
                    ),
                  ),
                if (state.phase == ScanFlowPhase.success)
                  Positioned(
                    left: AppSpacing.screenH,
                    right: AppSpacing.screenH,
                    bottom: bottomPad + AppSpacing.md,
                    child: SafeArea(
                      top: false,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.read<ScanCubit>().clearTransient(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(s.nextScan),
                      ),
                    ),
                  )
                else
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomPad + AppSpacing.lg,
                    child: SafeArea(
                      top: false,
                      child: PremiumCaptureButton(
                        busy: busy,
                        label: s.scanButton,
                        onPressed: busy
                            ? null
                            : () => _onEmbeddedCapture(context, lang),
                      ),
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

enum _ScanCaptureSource { gallery, systemCamera }

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MainShellLayout.paddingOf(context) + 168;
    return Positioned(
      left: AppSpacing.screenH,
      right: AppSpacing.screenH,
      bottom: bottomInset,
      child: GlassCard(
        blurSigma: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(AppStrings.of(context).tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.s,
    required this.scan,
    required this.backgroundQueued,
    required this.onDismiss,
  });

  final AppStrings s;
  final VehicleScan scan;
  final bool backgroundQueued;
  final VoidCallback onDismiss;

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
      blurSigma: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
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
