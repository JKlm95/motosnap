import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Stan sesji embedded camera (preview w zakładce Skan).
enum ScanCameraLifecycle {
  uninitialized,
  initializing,
  ready,
  paused,
  permissionDenied,
  unavailable,
  error,
}

class ScanCameraState extends Equatable {
  const ScanCameraState({
    this.lifecycle = ScanCameraLifecycle.uninitialized,
    this.controller,
    this.errorMessage,
    this.flashMode = FlashMode.off,
    this.supportsFlash = false,
    this.showShutterFlash = false,
    this.focusPoint,
  });

  final ScanCameraLifecycle lifecycle;
  final CameraController? controller;
  final String? errorMessage;
  final FlashMode flashMode;
  final bool supportsFlash;
  final bool showShutterFlash;

  /// Normalized (0–1) punkt ostrości z ostatniego tapnięcia — do HUD.
  final Offset? focusPoint;

  bool get isReady =>
      lifecycle == ScanCameraLifecycle.ready &&
      controller?.value.isInitialized == true;

  ScanCameraState copyWith({
    ScanCameraLifecycle? lifecycle,
    CameraController? controller,
    bool clearController = false,
    String? errorMessage,
    bool clearError = false,
    FlashMode? flashMode,
    bool? supportsFlash,
    bool? showShutterFlash,
    Offset? focusPoint,
    bool clearFocusPoint = false,
  }) {
    return ScanCameraState(
      lifecycle: lifecycle ?? this.lifecycle,
      controller: clearController ? null : (controller ?? this.controller),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      flashMode: flashMode ?? this.flashMode,
      supportsFlash: supportsFlash ?? this.supportsFlash,
      showShutterFlash: showShutterFlash ?? this.showShutterFlash,
      focusPoint: clearFocusPoint ? null : (focusPoint ?? this.focusPoint),
    );
  }

  @override
  List<Object?> get props => [
    lifecycle,
    controller,
    errorMessage,
    flashMode,
    supportsFlash,
    showShutterFlash,
    focusPoint,
  ];
}
