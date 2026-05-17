import '../../scan/domain/vehicle_info.dart';
import '../../scan/domain/vehicle_scan.dart';
import '../../scan/domain/vehicle_scan_status.dart';
import '../../scan/domain/vehicle_type.dart';
import 'scan_map_location_filter.dart';

/// Lekki model prezentacji markera na prywatnej mapie.
class ScanMapItem {
  const ScanMapItem({
    required this.scanId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.title,
    this.vehicleType,
    this.localImagePath = '',
    this.remoteImageUrl,
  });

  final String scanId;
  final double latitude;
  final double longitude;
  final VehicleScanStatus status;
  final DateTime createdAt;
  final String? title;
  final VehicleType? vehicleType;
  final String localImagePath;
  final String? remoteImageUrl;

  factory ScanMapItem.fromScan(VehicleScan scan) {
    final info = scan.effectiveVehicleInfo;
    return ScanMapItem(
      scanId: scan.id,
      latitude: scan.location.latitude,
      longitude: scan.location.longitude,
      status: scan.status,
      createdAt: scan.createdAt,
      title: _titleFromInfo(info),
      vehicleType: info?.vehicleType,
      localImagePath: scan.localImagePath,
      remoteImageUrl: scan.remoteImageUrl,
    );
  }

  static String? _titleFromInfo(VehicleInfo? info) {
    if (info == null) {
      return null;
    }
    final brand = info.brand?.trim();
    final model = info.model?.trim();
    if (brand != null &&
        brand.isNotEmpty &&
        model != null &&
        model.isNotEmpty) {
      return '$brand $model';
    }
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }
    if (model != null && model.isNotEmpty) {
      return model;
    }
    return null;
  }
}

List<ScanMapItem> scanMapItemsFromScans(List<VehicleScan> scans) {
  return scansWithMapEligibleLocation(
    scans,
  ).map(ScanMapItem.fromScan).toList(growable: false);
}
