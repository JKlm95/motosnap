import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/ui/shimmer/moto_shimmer.dart';
import 'scan_camera_controller.dart';
import 'scan_camera_state.dart';

/// Fullscreen camera preview — osobny widget, minimalne rebuildy (ListenableBuilder).
class ScanCameraPreview extends StatelessWidget {
  const ScanCameraPreview({
    required this.controller,
    required this.onTapFocus,
    super.key,
  });

  final ScanCameraController controller;
  final ValueChanged<Offset> onTapFocus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        return Stack(
          fit: StackFit.expand,
          children: [
            _PreviewBody(state: state, onTapFocus: onTapFocus),
            if (state.showShutterFlash) const ColoredBox(color: Colors.white54),
            if (state.focusPoint != null)
              _FocusReticle(point: state.focusPoint!),
          ],
        );
      },
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.state, required this.onTapFocus});

  final ScanCameraState state;
  final ValueChanged<Offset> onTapFocus;

  @override
  Widget build(BuildContext context) {
    return switch (state.lifecycle) {
      ScanCameraLifecycle.uninitialized ||
      ScanCameraLifecycle.initializing => const _CameraLoadingPlaceholder(),
      ScanCameraLifecycle.permissionDenied => const _CameraMessage(
        icon: Icons.no_photography_outlined,
      ),
      ScanCameraLifecycle.unavailable ||
      ScanCameraLifecycle.error => _CameraMessage(
        icon: Icons.videocam_off_outlined,
        subtitle: state.errorMessage,
      ),
      ScanCameraLifecycle.paused || ScanCameraLifecycle.ready => _LivePreview(
        controller: state.controller,
        ready: state.isReady,
        onTapFocus: onTapFocus,
      ),
    };
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.controller,
    required this.ready,
    required this.onTapFocus,
  });

  final CameraController? controller;
  final bool ready;
  final ValueChanged<Offset> onTapFocus;

  @override
  Widget build(BuildContext context) {
    if (!ready || controller == null) {
      return const _CameraLoadingPlaceholder();
    }

    return GestureDetector(
      onTapUp: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) {
          return;
        }
        final local = box.globalToLocal(d.globalPosition);
        final size = box.size;
        if (size.width <= 0 || size.height <= 0) {
          return;
        }
        onTapFocus(
          Offset(
            (local.dx / size.width).clamp(0, 1),
            (local.dy / size.height).clamp(0, 1),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.normal,
        curve: AppDurations.standard,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: _CoverCameraPreview(controller: controller!),
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return const _CameraLoadingPlaceholder();
        }
        final scale = constraints.maxWidth / previewSize.height;
        final scaledHeight = previewSize.width * scale;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxHeight: scaledHeight,
            child: SizedBox(
              width: constraints.maxWidth,
              height: scaledHeight,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

class _FocusReticle extends StatelessWidget {
  const _FocusReticle({required this.point});

  final Offset point;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = point.dx * constraints.maxWidth - 28;
        final top = point.dy * constraints.maxHeight - 28;
        return Positioned(
          left: left.clamp(8, constraints.maxWidth - 56),
          top: top.clamp(8, constraints.maxHeight - 56),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.25, end: 1),
            duration: AppDurations.fast,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraLoadingPlaceholder extends StatelessWidget {
  const _CameraLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: MotoShimmer(
          child: Container(
            width: 120,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, this.subtitle});

  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
