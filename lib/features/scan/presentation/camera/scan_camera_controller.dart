import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'scan_camera_flash.dart';
import 'scan_camera_state.dart';

/// Zarządza embedded [CameraController]: init, pause/resume, capture, focus, flash.
class ScanCameraController extends ChangeNotifier with WidgetsBindingObserver {
  ScanCameraController();

  bool _attached = false;

  ScanCameraState _state = const ScanCameraState();
  ScanCameraState get state => _state;

  bool _tabActive = true;
  bool _disposed = false;
  int _initGeneration = 0;
  Timer? _focusClearTimer;

  void attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureInitialized());
  }

  void setTabActive(bool active) {
    if (_tabActive == active) {
      return;
    }
    _tabActive = active;
    if (active) {
      unawaited(_ensureInitialized());
    } else {
      unawaited(_pausePreview());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        if (_tabActive) {
          unawaited(_resumePreview());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_pausePreview());
    }
  }

  Future<void> _ensureInitialized() async {
    if (_disposed || !_tabActive) {
      return;
    }

    final existing = _state.controller;
    if (_state.lifecycle == ScanCameraLifecycle.paused &&
        existing != null &&
        existing.value.isInitialized) {
      await _resumePreview();
      return;
    }

    if (_state.lifecycle == ScanCameraLifecycle.ready &&
        existing?.value.isInitialized == true) {
      await _forceTorchOff('tab-active');
      return;
    }

    if (_state.lifecycle == ScanCameraLifecycle.initializing) {
      return;
    }

    final gen = ++_initGeneration;
    _setState(
      _state.copyWith(
        lifecycle: ScanCameraLifecycle.initializing,
        clearError: true,
        flashMode: ScanCameraFlash.defaultMode,
      ),
    );

    final cameraStatus = await Permission.camera.request();
    if (_disposed || gen != _initGeneration) {
      return;
    }
    if (!cameraStatus.isGranted) {
      _setState(
        _state.copyWith(
          lifecycle: ScanCameraLifecycle.permissionDenied,
          clearController: true,
        ),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      if (_disposed || gen != _initGeneration) {
        return;
      }
      if (cameras.isEmpty) {
        _setState(
          _state.copyWith(
            lifecycle: ScanCameraLifecycle.unavailable,
            clearController: true,
          ),
        );
        return;
      }

      final lens = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _state.controller?.dispose();

      final controller = CameraController(
        lens,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (_disposed || gen != _initGeneration) {
        await controller.dispose();
        return;
      }

      await _forceTorchOff('init', controller: controller);

      final supportsFlash = await ScanCameraFlash.detectSupport(
        controller.setFlashMode,
      );

      _setState(
        ScanCameraState(
          lifecycle: ScanCameraLifecycle.ready,
          controller: controller,
          flashMode: ScanCameraFlash.defaultMode,
          supportsFlash: supportsFlash,
        ),
      );
    } on CameraException catch (e) {
      if (_disposed || gen != _initGeneration) {
        return;
      }
      _setState(
        _state.copyWith(
          lifecycle: ScanCameraLifecycle.error,
          errorMessage: e.description ?? e.code,
          clearController: true,
        ),
      );
    } on Object catch (e) {
      if (_disposed || gen != _initGeneration) {
        return;
      }
      _setState(
        _state.copyWith(
          lifecycle: ScanCameraLifecycle.error,
          errorMessage: e.toString(),
          clearController: true,
        ),
      );
    }
  }

  Future<void> _forceTorchOff(String reason, {CameraController? controller}) {
    final c = controller ?? _state.controller;
    if (c == null || !c.value.isInitialized) {
      return Future<void>.value();
    }
    return ScanCameraFlash.forceOff(
      reason: reason,
      setFlashMode: c.setFlashMode,
      onLogicalMode: controller == null
          ? (mode) {
              if (!_disposed && _state.flashMode != mode) {
                _setState(_state.copyWith(flashMode: mode));
              }
            }
          : null,
    );
  }

  Future<void> _pausePreview() async {
    await _forceTorchOff('pause');
    final c = _state.controller;
    if (c == null || !c.value.isInitialized) {
      return;
    }
    try {
      await c.pausePreview();
      if (!_disposed) {
        _setState(
          _state.copyWith(
            lifecycle: ScanCameraLifecycle.paused,
            flashMode: ScanCameraFlash.defaultMode,
          ),
        );
      }
    } on Object {
      // ignore — device może już zwolnić kamerę
    }
  }

  Future<void> _resumePreview() async {
    if (!_tabActive || _disposed) {
      return;
    }
    final c = _state.controller;
    if (c != null && c.value.isInitialized) {
      try {
        await c.resumePreview();
        await _forceTorchOff('resume');
        if (!_disposed) {
          _setState(
            _state.copyWith(
              lifecycle: ScanCameraLifecycle.ready,
              flashMode: ScanCameraFlash.defaultMode,
            ),
          );
        }
        return;
      } on Object {
        await c.dispose();
      }
    }
    await _ensureInitialized();
  }

  Future<void> retryAfterPermission() => _ensureInitialized();

  Future<void> setFocusPoint(Offset normalized) async {
    final c = _state.controller;
    if (c == null || !c.value.isInitialized) {
      return;
    }
    try {
      await c.setFocusPoint(normalized);
      await c.setExposurePoint(normalized);
      _setState(_state.copyWith(focusPoint: normalized));
      _focusClearTimer?.cancel();
      _focusClearTimer = Timer(const Duration(milliseconds: 900), () {
        if (!_disposed) {
          _setState(_state.copyWith(clearFocusPoint: true));
        }
      });
    } on Object {
      // niektóre urządzenia nie wspierają — ignoruj
    }
  }

  Future<void> toggleFlash() async {
    if (!_tabActive ||
        _state.lifecycle != ScanCameraLifecycle.ready ||
        _disposed) {
      return;
    }
    final c = _state.controller;
    if (c == null || !_state.supportsFlash) {
      return;
    }
    final next = ScanCameraFlash.toggled(_state.flashMode);
    try {
      await c.setFlashMode(next);
      _setState(_state.copyWith(flashMode: next));
    } on Object {
      // ignore
    }
  }

  Future<XFile?> takePicture() async {
    if (_disposed || !_tabActive) {
      return null;
    }
    final c = _state.controller;
    if (_state.lifecycle != ScanCameraLifecycle.ready ||
        c == null ||
        !c.value.isInitialized ||
        c.value.isTakingPicture) {
      return null;
    }
    _setState(_state.copyWith(showShutterFlash: true));
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!_disposed) {
        _setState(_state.copyWith(showShutterFlash: false));
      }
    });
    try {
      return await c.takePicture();
    } on Object {
      return null;
    }
  }

  void _setState(ScanCameraState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _initGeneration++;
    _focusClearTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_forceTorchOff('dispose'));
    _state.controller?.dispose();
    super.dispose();
  }
}
