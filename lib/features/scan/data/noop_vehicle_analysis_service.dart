import '../domain/vehicle_analysis_exception.dart';
import '../domain/vehicle_analysis_service.dart';
import '../domain/vehicle_info.dart';

class NoOpVehicleAnalysisService implements VehicleAnalysisService {
  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    throw const VehicleAnalysisException(
      'Analiza AI wymaga Firebase oraz wdrożonych Cloud Functions.',
    );
  }
}
