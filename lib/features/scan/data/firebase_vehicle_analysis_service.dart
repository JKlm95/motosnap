import 'package:cloud_functions/cloud_functions.dart';

import '../domain/scan_repository.dart';
import '../domain/vehicle_analysis_exception.dart';
import '../domain/vehicle_analysis_service.dart';
import '../domain/vehicle_info.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';

/// Wywołuje `analyzeVehicleScan` (region `us-central1` — zgodnie z deployem Functions).
final class FirebaseVehicleAnalysisService implements VehicleAnalysisService {
  FirebaseVehicleAnalysisService({
    required ScanRepository scanRepository,
    FirebaseFunctions? functions,
  }) : _repository = scanRepository,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final ScanRepository _repository;
  final FirebaseFunctions _functions;

  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    final scan = await _repository.getScan(scanId);
    if (scan == null) {
      throw const VehicleAnalysisException('Nie znaleziono skanu.');
    }

    final lang = languageCode.toLowerCase().startsWith('pl') ? 'pl' : 'en';

    final callable = _functions.httpsCallable('analyzeVehicleScan');
    try {
      final result = await callable.call(<String, dynamic>{
        'scanId': scanId,
        'language': lang,
      });
      final raw = result.data;
      if (raw is! Map) {
        throw const VehicleAnalysisException(
          'Nieprawidłowa odpowiedź serwera.',
        );
      }
      final data = Map<String, dynamic>.from(raw);
      return _applyResponseAndReturn(scan, data);
    } on FirebaseFunctionsException catch (e) {
      throw VehicleAnalysisException(
        e.message ?? 'Błąd Cloud Function (${e.code}).',
      );
    }
  }

  Future<VehicleInfo> _applyResponseAndReturn(
    VehicleScan scan,
    Map<String, dynamic> data,
  ) async {
    final statusRaw = data['status'] as String?;
    final status = VehicleScanStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => VehicleScanStatus.failed,
    );

    final VehicleInfo? info;
    final infoRaw = data['vehicle_info'];
    if (infoRaw is Map) {
      info = VehicleInfo.fromAiResponseJson(Map<String, dynamic>.from(infoRaw));
    } else {
      info = null;
    }

    final err = data['recognition_error'] as String?;
    final raRaw = data['recognized_at'] as String?;
    final DateTime? recognizedAt = raRaw != null
        ? DateTime.parse(raRaw).toUtc()
        : null;

    final updated = scan.copyWith(
      status: status,
      updateStatus: true,
      vehicleInfo: info,
      updateVehicleInfo: info != null,
      recognitionError: err,
      updateRecognitionError: true,
      recognizedAt: recognizedAt,
      updateRecognizedAt: recognizedAt != null,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repository.updateScan(updated);

    if (status == VehicleScanStatus.recognized && info != null) {
      return info;
    }
    throw VehicleAnalysisException(err ?? 'Rozpoznanie nie powiodło się.');
  }
}
