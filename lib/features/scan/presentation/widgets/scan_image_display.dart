import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/ui/app_motion.dart';
import '../../../../core/ui/shimmer/moto_shimmer.dart';

/// Zdjęcie skanu: plik lokalny, potem sieć (`remoteImageUrl`), na końcu placeholder.
///
/// Opcjonalny [heroTag] — ten sam co w historii i szczegółach dla [Hero].
class ScanImageDisplay extends StatelessWidget {
  const ScanImageDisplay({
    required this.localImagePath,
    this.remoteImageUrl,
    this.heroTag,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String localImagePath;
  final String? remoteImageUrl;

  /// Gdy nie-null, widget owija [Hero] (ten sam tag w liście i na ekranie szczegółów).
  final Object? heroTag;
  final BoxFit fit;

  /// Stabilny tag Hero dla danego [scanId].
  static String heroTagFor(String scanId) => 'motosnap-scan-photo-$scanId';

  @override
  Widget build(BuildContext context) {
    final core = RepaintBoundary(
      child: Semantics(
        label: 'Zdjęcie skanu',
        image: true,
        child: _ScanImageCore(
          localImagePath: localImagePath,
          remoteImageUrl: remoteImageUrl,
          fit: fit,
        ),
      ),
    );
    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: core),
      );
    }
    return core;
  }
}

class _ScanImageCore extends StatelessWidget {
  const _ScanImageCore({
    required this.localImagePath,
    required this.remoteImageUrl,
    required this.fit,
  });

  final String localImagePath;
  final String? remoteImageUrl;
  final BoxFit fit;

  Widget _placeholder(BuildContext context, {bool broken = false}) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          broken
              ? Icons.broken_image_outlined
              : Icons.image_not_supported_outlined,
          size: 40,
          color: scheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _fadeFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) {
      return child;
    }
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: AppMotion.imageFade,
      curve: AppMotion.emphasizedDecelerate,
      child: child,
    );
  }

  Widget _networkLoading(BuildContext context, ImageChunkEvent? chunk) {
    final scheme = Theme.of(context).colorScheme;
    double? value;
    if (chunk != null &&
        chunk.expectedTotalBytes != null &&
        chunk.expectedTotalBytes! > 0) {
      value = chunk.cumulativeBytesLoaded / chunk.expectedTotalBytes!;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        MotoShimmer(child: ColoredBox(color: scheme.surfaceContainerHigh)),
        Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(
            minHeight: 2,
            value: value,
            backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
            color: scheme.primary.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(localImagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return _fadeFrame(context, child, frame, wasSynchronouslyLoaded);
        },
      );
    }
    final url = remoteImageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return _fadeFrame(context, child, frame, wasSynchronouslyLoaded);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _networkLoading(context, loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, broken: true),
      );
    }
    return _placeholder(context);
  }
}
