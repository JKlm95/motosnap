import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/media/camera_capture_service.dart';
import '../../domain/scan_repository.dart';
import 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    required ScanRepository scanRepository,
    required CameraCaptureService cameraCapture,
  }) : _repository = scanRepository,
       _camera = cameraCapture,
       super(const ScanState());

  final ScanRepository _repository;
  final CameraCaptureService _camera;

  Future<void> captureAndSaveScan() async {
    emit(const ScanState(status: ScanUiStatus.working));
    final file = await _camera.capturePhoto();
    if (file == null) {
      emit(
        const ScanState(
          status: ScanUiStatus.idle,
          userMessage: 'Anulowano zdjęcie.',
        ),
      );
      return;
    }
    try {
      final scan = await _repository.createScanFromCameraImage(file);
      emit(
        ScanState(
          status: ScanUiStatus.success,
          userMessage: 'Zapisano skan lokalnie.',
          lastSavedId: scan.id,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(const ScanState());
    } catch (e) {
      emit(ScanState(status: ScanUiStatus.error, userMessage: _mapError(e)));
    }
  }

  void acknowledgeMessage() {
    emit(const ScanState());
  }

  String _mapError(Object e) {
    final text = e.toString();
    if (text.contains('LocationServiceDisabled')) {
      return 'Włącz usługi lokalizacji, aby zapisać skan.';
    }
    if (text.contains('LocationPermissionDenied')) {
      return 'Zezwól na dostęp do lokalizacji — jest wymagany przy skanie.';
    }
    return 'Nie udało się zapisać skanu. Spróbuj ponownie.';
  }
}
