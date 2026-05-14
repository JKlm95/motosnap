import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/scan_permissions_service.dart';
import '../../../../core/media/camera_capture_service.dart';
import '../../domain/scan_repository.dart';
import 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    required ScanRepository scanRepository,
    required CameraCaptureService cameraCapture,
    required ScanPermissionsService permissions,
  }) : _repository = scanRepository,
       _camera = cameraCapture,
       _permissions = permissions,
       super(const ScanState());

  final ScanRepository _repository;
  final CameraCaptureService _camera;
  final ScanPermissionsService _permissions;

  Future<void> captureAndSaveScan() async {
    emit(const ScanState(phase: ScanFlowPhase.requestingPermissions));
    try {
      await _permissions.ensureCameraAndWhenInUseLocation();
    } on ScanPermissionException catch (e) {
      emit(ScanState(phase: ScanFlowPhase.error, errorMessage: e.message));
      return;
    }

    emit(const ScanState(phase: ScanFlowPhase.capturing));
    final file = await _camera.capturePhoto();
    if (file == null) {
      emit(
        const ScanState(
          phase: ScanFlowPhase.idle,
          errorMessage: 'Anulowano zdjęcie.',
        ),
      );
      return;
    }

    emit(const ScanState(phase: ScanFlowPhase.saving));
    try {
      final scan = await _repository.createScan(capturedPhoto: file);
      emit(ScanState(phase: ScanFlowPhase.success, savedScan: scan));
    } on Object catch (e) {
      emit(ScanState(phase: ScanFlowPhase.error, errorMessage: _mapError(e)));
    }
  }

  void clearTransient() {
    emit(const ScanState());
  }

  String _mapError(Object e) {
    final text = e.toString();
    if (text.contains('LocationServiceDisabled')) {
      return 'Włącz usługi lokalizacji — GPS jest wymagany.';
    }
    if (text.contains('LocationPermissionDenied')) {
      return 'Zezwól na lokalizację — GPS jest wymagany.';
    }
    return 'Nie udało się zapisać skanu. Spróbuj ponownie.';
  }
}
