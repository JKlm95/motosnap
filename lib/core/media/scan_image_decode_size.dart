import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Rozmiar dekodowania obrazów listowych (mniej RAM niż pełna rozdzielczość).
abstract final class ScanImageDecodeSize {
  static const double thumbnailAspect = 5 / 4; // height / width

  static int decodeWidth(BuildContext context, double logicalWidth) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return math.max(1, (logicalWidth * dpr).round());
  }

  static int decodeHeight(int decodeWidth) {
    return math.max(1, (decodeWidth * thumbnailAspect).round());
  }
}
