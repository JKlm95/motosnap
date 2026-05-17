import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Logika flash/torch bez migania przy starcie (testowalna bez fizycznej kamery).
abstract final class ScanCameraFlash {
  static const FlashMode defaultMode = FlashMode.off;

  /// Wykrywa wsparcie flash bez włączania latarki (tylko `FlashMode.off`).
  static Future<bool> detectSupport(
    Future<void> Function(FlashMode mode) setFlashMode,
  ) async {
    try {
      await setFlashMode(FlashMode.off);
      return true;
    } on Object {
      return false;
    }
  }

  static FlashMode toggled(FlashMode current) =>
      current == FlashMode.off ? FlashMode.torch : FlashMode.off;

  static Future<void> forceOff({
    required String reason,
    required Future<void> Function(FlashMode mode) setFlashMode,
    void Function(FlashMode mode)? onLogicalMode,
  }) async {
    try {
      await setFlashMode(FlashMode.off);
      onLogicalMode?.call(FlashMode.off);
      if (kDebugMode) {
        debugPrint('[Camera] force torch off: $reason');
      }
    } on Object {
      // Urządzenie bez flash — ignoruj.
    }
  }
}
