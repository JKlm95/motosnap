import 'vehicle_info.dart';

/// Analiza AI zdjęcia pojazdu — wyłącznie przez Cloud Function (brak klucza Gemini w aplikacji).
abstract class VehicleAnalysisService {
  /// Hook po zapisie lokalnym (MVP: no-op). Automatyczne rozpoznanie po udanym syncu jest uruchamiane osobno (warstwa aplikacji, nie ten hook).
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
