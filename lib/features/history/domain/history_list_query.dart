import '../../scan/domain/vehicle_scan.dart';
import '../../scan/domain/vehicle_scan_status.dart';

/// Filtry listy historii (tylko po stronie klienta).
enum HistoryFilter { all, recognized, waiting, corrected, public }

/// Sortowanie listy historii.
enum HistorySort { newest, oldest, confidence, brand }

bool historyScanMatchesFilter(VehicleScan scan, HistoryFilter filter) {
  return switch (filter) {
    HistoryFilter.all => true,
    HistoryFilter.recognized => scan.status == VehicleScanStatus.recognized,
    HistoryFilter.waiting =>
      scan.status == VehicleScanStatus.waitingForRecognition,
    // „Poprawione” = zapisana korekta użytkownika (kontrakt w TECHNICAL.md).
    HistoryFilter.corrected => scan.userCorrection != null,
    HistoryFilter.public => scan.isPublic,
  };
}

/// Zwraca nową listę: filtr + sort.
List<VehicleScan> applyHistoryFilterSort(
  List<VehicleScan> scans,
  HistoryFilter filter,
  HistorySort sort,
) {
  final filtered = scans
      .where((s) => historyScanMatchesFilter(s, filter))
      .toList();

  int compareByCreatedDesc(VehicleScan a, VehicleScan b) =>
      b.createdAt.compareTo(a.createdAt);

  int compareByCreatedAsc(VehicleScan a, VehicleScan b) =>
      a.createdAt.compareTo(b.createdAt);

  double? confidenceOf(VehicleScan s) => s.effectiveVehicleInfo?.confidence;

  String brandKey(VehicleScan s) {
    final b = s.effectiveVehicleInfo?.brand?.trim().toLowerCase() ?? '';
    if (b.isEmpty) {
      return '\uffff';
    }
    return b;
  }

  switch (sort) {
    case HistorySort.newest:
      filtered.sort(compareByCreatedDesc);
    case HistorySort.oldest:
      filtered.sort(compareByCreatedAsc);
    case HistorySort.confidence:
      filtered.sort((a, b) {
        final ca = confidenceOf(a);
        final cb = confidenceOf(b);
        if (ca == null && cb == null) {
          return compareByCreatedDesc(a, b);
        }
        if (ca == null) {
          return 1;
        }
        if (cb == null) {
          return -1;
        }
        final c = cb.compareTo(ca);
        if (c != 0) {
          return c;
        }
        return compareByCreatedDesc(a, b);
      });
    case HistorySort.brand:
      filtered.sort((a, b) {
        final c = brandKey(a).compareTo(brandKey(b));
        if (c != 0) {
          return c;
        }
        return compareByCreatedDesc(a, b);
      });
  }
  return filtered;
}

/// Czy skan ma obraz w chmurze i nie czeka na upload (spójnie ze szczegółami).
bool isHistoryScanSyncedToCloud(VehicleScan scan) {
  return !scan.pendingSync &&
      (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty);
}
