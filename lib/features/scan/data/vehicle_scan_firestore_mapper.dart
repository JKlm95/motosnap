import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/scan_location.dart';
import '../domain/vehicle_info.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';
import 'vehicle_scan_remote_merger.dart';

/// Mapowanie dokumentu `users/{uid}/scans/{scanId}` ↔ lokalny [VehicleScan].
abstract final class VehicleScanFirestoreMapper {
  /// Brak pliku na dysku — UI korzysta z [VehicleScan.remoteImageUrl].
  static const String remoteOnlyLocalImagePath = '';

  static VehicleScan createFromRemoteDocument({
    required String scanId,
    required Map<String, dynamic> remote,
  }) {
    final url = _remoteImageUrl(remote);
    final created =
        _parseDateTime(remote['created_at']) ?? DateTime.now().toUtc();
    final updated = _parseDateTime(remote['updated_at']) ?? created;

    return VehicleScan(
      id: scanId,
      localImagePath: remoteOnlyLocalImagePath,
      remoteImageUrl: url,
      createdAt: created,
      updatedAt: updated,
      status: _parseStatus(remote['status'] as String?),
      location: _parseLocation(remote),
      vehicleInfo: _parseVehicleInfo(remote['vehicle_info']),
      userCorrection: VehicleScanRemoteMerger.parseUserCorrection(
        remote['user_correction'],
      ),
      recognizedAt: _parseDateTime(remote['recognized_at']),
      isPublic: remote['is_public'] as bool? ?? false,
      recognitionError: remote['recognition_error'] as String?,
      pendingSync: url == null || url.isEmpty,
      syncLastError: null,
    );
  }

  static VehicleScan mergePull({
    required VehicleScan local,
    required Map<String, dynamic> remote,
  }) {
    final url = _remoteImageUrl(remote) ?? local.remoteImageUrl ?? '';
    return VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
      local: local,
      remote: remote,
      remoteImageUrl: url,
    );
  }

  /// Czy po pull warto zapisać rekord w Hive (pola widoczne w UI / sync).
  static bool hasSyncRelevantChanges(VehicleScan before, VehicleScan after) {
    if (before.status != after.status) {
      return true;
    }
    if (before.pendingSync != after.pendingSync) {
      return true;
    }
    if (before.remoteImageUrl != after.remoteImageUrl) {
      return true;
    }
    if (before.recognitionError != after.recognitionError) {
      return true;
    }
    if (before.recognizedAt != after.recognizedAt) {
      return true;
    }
    if (before.isPublic != after.isPublic) {
      return true;
    }
    if (!_vehicleInfoEquivalent(before.vehicleInfo, after.vehicleInfo)) {
      return true;
    }
    if (before.userCorrection?.correctedAt !=
        after.userCorrection?.correctedAt) {
      return true;
    }
    if (before.userCorrection?.brand != after.userCorrection?.brand) {
      return true;
    }
    return false;
  }

  static String? _remoteImageUrl(Map<String, dynamic> remote) {
    final raw = remote['remote_image_url'] as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  static ScanLocation _parseLocation(Map<String, dynamic> remote) {
    final exact = remote['exact_location'];
    if (exact is Map) {
      final m = Map<String, dynamic>.from(exact);
      final lat = (m['latitude'] as num?)?.toDouble();
      final lng = (m['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final approx = remote['public_location_approximation'];
        if (approx is Map) {
          final a = Map<String, dynamic>.from(approx);
          return ScanLocation(
            latitude: lat,
            longitude: lng,
            city: a['city'] as String?,
            country: a['country'] as String?,
            displayName: a['display_name'] as String?,
          );
        }
        return ScanLocation(latitude: lat, longitude: lng);
      }
    }
    return const ScanLocation(latitude: 0, longitude: 0);
  }

  static VehicleInfo? _parseVehicleInfo(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    return VehicleInfo.fromAiResponseJson(Map<String, dynamic>.from(raw));
  }

  static VehicleScanStatus _parseStatus(String? raw) {
    if (raw == null) {
      return VehicleScanStatus.waitingForRecognition;
    }
    return VehicleScanStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => VehicleScanStatus.waitingForRecognition,
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is Timestamp) {
      return v.toDate().toUtc();
    }
    if (v is String) {
      return DateTime.tryParse(v)?.toUtc();
    }
    return null;
  }

  static bool _vehicleInfoEquivalent(VehicleInfo? a, VehicleInfo? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.vehicleType == b.vehicleType &&
        a.brand == b.brand &&
        a.model == b.model &&
        a.generation == b.generation;
  }
}
