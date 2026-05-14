import '../../features/scan/domain/scan_location.dart';

/// Uzupełnia współrzędne o metadane z reverse geocoding (best-effort).
abstract class LocationMetadataEnricher {
  Future<ScanLocation> enrich(ScanLocation draft);
}
