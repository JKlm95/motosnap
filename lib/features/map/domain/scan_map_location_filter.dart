import '../../scan/domain/scan_location.dart';
import '../../scan/domain/vehicle_scan.dart';

/// Maksymalna liczba markerów na mapie (MVP).
const int kScanMapMaxMarkers = 500;

/// Czy lokalizacja nadaje się do markera na prywatnej mapie.
bool hasMapEligibleLocation(ScanLocation location) {
  final lat = location.latitude;
  final lng = location.longitude;
  if (!lat.isFinite || !lng.isFinite) {
    return false;
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return false;
  }
  // Brak GPS / placeholder z backendu lub legacy.
  if (lat == 0 && lng == 0) {
    return false;
  }
  return true;
}

/// Skany z poprawnym GPS, najnowsze pierwsze, limit [kScanMapMaxMarkers].
List<VehicleScan> scansWithMapEligibleLocation(List<VehicleScan> scans) {
  final eligible =
      scans.where((s) => hasMapEligibleLocation(s.location)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (eligible.length <= kScanMapMaxMarkers) {
    return eligible;
  }
  return eligible.sublist(0, kScanMapMaxMarkers);
}
