/// Analiza AI zdjęcia pojazdu — tylko kontrakt na przyszłą integrację (np. Cloud Functions + model).
abstract class VehicleAnalysisService {
  Future<void> scheduleAnalysis(String scanId);
}
