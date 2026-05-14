import '../domain/vehicle_analysis_service.dart';

class NoOpVehicleAnalysisService implements VehicleAnalysisService {
  @override
  Future<void> scheduleAnalysis(String scanId) async {}
}
