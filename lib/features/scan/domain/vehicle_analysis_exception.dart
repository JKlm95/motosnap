/// Błąd analizy AI po stronie Cloud Function / sieci (komunikat do UI).
final class VehicleAnalysisException implements Exception {
  const VehicleAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
