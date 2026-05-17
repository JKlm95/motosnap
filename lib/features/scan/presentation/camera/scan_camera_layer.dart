import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scan_camera_controller.dart';
import 'scan_camera_preview.dart';
import '../widgets/scan_camera_overlay.dart';

/// Warstwa kamery — preview + HUD. Nie zależy od [ScanCubit].
class ScanCameraLayer extends StatelessWidget {
  const ScanCameraLayer({
    required this.controller,
    required this.hudVisible,
    required this.tabActive,
    required this.onTapFocus,
    super.key,
  });

  final ScanCameraController controller;
  final ValueListenable<bool> hudVisible;
  final bool tabActive;
  final ValueChanged<Offset> onTapFocus;

  @override
  Widget build(BuildContext context) {
    final preview = RepaintBoundary(
      child: ScanCameraPreview(controller: controller, onTapFocus: onTapFocus),
    );

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        if (kDebugMode)
          ScanRebuildProbe(label: 'camera_preview', child: preview)
        else
          preview,
        ValueListenableBuilder<bool>(
          valueListenable: hudVisible,
          builder: (context, visible, _) {
            final active = visible && tabActive;
            if (!active) {
              return const SizedBox.shrink();
            }
            final overlay = RepaintBoundary(
              child: ScanCameraOverlay(active: active),
            );
            if (kDebugMode) {
              return ScanRebuildProbe(label: 'camera_overlay', child: overlay);
            }
            return overlay;
          },
        ),
      ],
    );

    return stack;
  }
}
