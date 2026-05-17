import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/media/camera_capture_service.dart';
import '../../../../core/permissions/scan_permissions_service.dart';
import '../../domain/scan_processing_coordinator.dart';
import '../../domain/scan_repository.dart';
import 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    required ScanRepository scanRepository,
    required CameraCaptureService cameraCapture,
    required ScanPermissionsService permissions,
    ScanProcessingCoordinator? processingCoordinator,
  }) : _repository = scanRepository,
       _camera = cameraCapture,
       _permissions = permissions,
       _processing = processingCoordinator,
       super(const ScanState());

  final ScanRepository _repository;
  final CameraCaptureService _camera;
  final ScanPermissionsService _permissions;
  final ScanProcessingCoordinator? _processing;

  /// Zapis skanu z już wykonanego zdjęcia (embedded camera / galeria).
  Future<void> saveScanFromPhoto(
    XFile capturedPhoto,
    String uiLanguageCode,
  ) async {
    final s = AppStrings.fromLanguageCode(uiLanguageCode);
    emit(const ScanState(phase: ScanFlowPhase.requestingPermissions));
    try {
      await _permissions.ensureWhenInUseLocation();
    } on ScanPermissionException catch (e) {
      final msg = switch (e.denied) {
        ScanPermissionDeniedKind.locationWhenInUse => s.errorLocationPermission,
        ScanPermissionDeniedKind.camera => s.errorCameraPermission,
      };
      emit(ScanState(phase: ScanFlowPhase.error, errorMessage: msg));
      return;
    }

    await _persistCapture(capturedPhoto, uiLanguageCode, s);
  }

  /// Fallback — systemowy aparat przez image_picker.
  Future<void> captureAndSaveScan(String uiLanguageCode) async {
    final s = AppStrings.fromLanguageCode(uiLanguageCode);
    emit(const ScanState(phase: ScanFlowPhase.requestingPermissions));
    try {
      await _permissions.ensureCameraAndWhenInUseLocation();
    } on ScanPermissionException catch (e) {
      final msg = switch (e.denied) {
        ScanPermissionDeniedKind.locationWhenInUse => s.errorLocationPermission,
        ScanPermissionDeniedKind.camera => s.errorCameraPermission,
      };
      emit(ScanState(phase: ScanFlowPhase.error, errorMessage: msg));
      return;
    }

    emit(const ScanState(phase: ScanFlowPhase.capturing));
    final file = await _camera.capturePhoto();
    if (file == null) {
      emit(
        ScanState(phase: ScanFlowPhase.idle, errorMessage: s.photoCancelled),
      );
      return;
    }

    await _persistCapture(file, uiLanguageCode, s);
  }

  Future<void> importFromGallery(String uiLanguageCode) async {
    final file = await _camera.pickFromGallery();
    if (file == null) {
      return;
    }
    await saveScanFromPhoto(file, uiLanguageCode);
  }

  Future<void> _persistCapture(
    XFile capturedPhoto,
    String uiLanguageCode,
    AppStrings s,
  ) async {
    emit(const ScanState(phase: ScanFlowPhase.saving));
    try {
      final scan = await _repository.createScan(capturedPhoto: capturedPhoto);
      _processing?.enqueue(scan.id, uiLanguageCode);
      emit(
        ScanState(
          phase: ScanFlowPhase.success,
          savedScan: scan,
          backgroundQueued: _processing != null,
        ),
      );
    } on Object catch (e) {
      emit(
        ScanState(phase: ScanFlowPhase.error, errorMessage: _mapError(s, e)),
      );
    }
  }

  void clearTransient() {
    emit(const ScanState());
  }

  String _mapError(AppStrings s, Object e) {
    final text = e.toString();
    if (text.contains('LocationServiceDisabled')) {
      return s.errorLocationServiceDisabled;
    }
    if (text.contains('LocationPermissionDenied')) {
      return s.errorLocationPermission;
    }
    return s.errorScanSaveGeneric;
  }
}
