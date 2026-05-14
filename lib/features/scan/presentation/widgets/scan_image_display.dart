import 'dart:io';

import 'package:flutter/material.dart';

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
      child: _ScanImageCore(
        localImagePath: localImagePath,
        remoteImageUrl: remoteImageUrl,
        fit: fit,
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
          size: 48,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(localImagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: fit, gaplessPlayback: true);
    }
    final url = remoteImageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          final scheme = Theme.of(context).colorScheme;
          return ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, broken: true),
      );
    }
    return _placeholder(context);
  }
}
