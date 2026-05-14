import 'vehicle_info.dart';

/// Analiza AI zdjęcia pojazdu — wyłącznie przez Cloud Function (brak klucza Gemini w aplikacji).
abstract class VehicleAnalysisService {
  /// No-op w MVP (brak automatycznego uruchamiania AI po zapisie lokalnym).
  Future<void> scheduleAnalysis(String scanId);

  /// Wywołuje callable `analyzeVehicleScan` i aktualizuje lokalny skan w repozytorium.
  ///
  /// Zwraca [VehicleInfo] przy statusie `recognized`. Przy `failed` rzuca
  /// [VehicleAnalysisException] po zapisaniu błędu lokalnie.
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  });
}
