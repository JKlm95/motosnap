import 'package:flutter/material.dart';

import '../../features/scan/presentation/widgets/scan_image_display.dart';

/// Spójny kadr 4:5 (cinematic portrait) dla miniaturek w historii i listach.
abstract final class CinematicThumbnail {
  /// width / height — pionowy kadr motoryzacyjny.
  static const double aspectRatio = 4 / 5;

  static double widthForList(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return (screenW * 0.27).clamp(96.0, 118.0);
  }

  static Widget frame({
    required BuildContext context,
    required String localImagePath,
    String? remoteImageUrl,
    Object? heroTag,
    double? width,
    BorderRadius? borderRadius,
    List<Widget> overlays = const [],
  }) {
    final w = width ?? widthForList(context);
    return SizedBox(
      width: w,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ScanImageDisplay(
                heroTag: heroTag,
                localImagePath: localImagePath,
                remoteImageUrl: remoteImageUrl,
                fit: BoxFit.cover,
              ),
              ...overlays,
            ],
          ),
        ),
      ),
    );
  }
}
