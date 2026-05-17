import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_vehicle_correction.dart';
import '../domain/vehicle_info.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';

/// Scalanie dokumentu Firestore z lokalnym skanem po uploadzie (źródło prawdy dla pól AI).
final class VehicleScanRemoteMerger {
  const VehicleScanRemoteMerger._();

  static VehicleScan mergeAfterFirestoreFetch({
    required VehicleScan local,
    required Map<String, dynamic> remote,
    required String remoteImageUrl,
  }) {
    final remoteStatus = _parseStatus(remote['status'] as String?);
    final mergedStatus = _mergeStatus(
      remote: remoteStatus,
      local: local.status,
    );

    final remoteVehicleRaw = remote['vehicle_info'];
    final VehicleInfo? mergedVehicleInfo;
    if (remoteVehicleRaw is Map) {
      mergedVehicleInfo = VehicleInfo.fromAiResponseJson(
        Map<String, dynamic>.from(remoteVehicleRaw),
      );
    } else {
      mergedVehicleInfo = local.vehicleInfo;
    }

    final remoteRecognized = _parseDateTime(remote['recognized_at']);
    final mergedRecognized = remoteRecognized ?? local.recognizedAt;

    final String? mergedRecognitionError;
    if (remote.containsKey('recognition_error')) {
      mergedRecognitionError = remote['recognition_error'] as String?;
    } else {
      mergedRecognitionError = local.recognitionError;
    }

    final remoteUserCorrection = parseUserCorrection(remote['user_correction']);
    final mergedUserCorrection = _mergeUserCorrection(
      local: local.userCorrection,
      remote: remoteUserCorrection,
    );

    final remoteIsPublic = remote['is_public'] as bool? ?? local.isPublic;

    return VehicleScan(
      id: local.id,
      localImagePath: local.localImagePath,
      remoteImageUrl: remoteImageUrl,
      createdAt: local.createdAt,
      updatedAt: DateTime.now().toUtc(),
      status: mergedStatus,
      location: local.location,
      vehicleInfo: mergedVehicleInfo,
      userCorrection: mergedUserCorrection,
      recognizedAt: mergedRecognized,
      isPublic: remoteIsPublic,
      recognitionError: mergedRecognitionError,
      pendingSync: false,
      syncLastError: null,
    );
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

  /// Nie degraduj lokalnego stanu „po AI” do `waiting`, jeśli chmura jeszcze nie ma statusu końcowego.
  static VehicleScanStatus _mergeStatus({
    required VehicleScanStatus remote,
    required VehicleScanStatus local,
  }) {
    bool terminal(VehicleScanStatus s) =>
        s == VehicleScanStatus.recognized || s == VehicleScanStatus.failed;

    if (terminal(remote)) {
      return remote;
    }
    if (terminal(local)) {
      return local;
    }
    return remote;
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

  static UserVehicleCorrection? parseUserCorrection(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final ct = m['corrected_at'];
    DateTime correctedAt;
    if (ct is Timestamp) {
      correctedAt = ct.toDate().toUtc();
    } else if (ct is String) {
      correctedAt = DateTime.parse(ct).toUtc();
    } else {
      correctedAt = DateTime.now().toUtc();
    }
    return UserVehicleCorrection.fromJson(<String, dynamic>{
      ...m,
      'corrected_at': correctedAt.toIso8601String(),
    });
  }

  static UserVehicleCorrection? _mergeUserCorrection({
    required UserVehicleCorrection? local,
    required UserVehicleCorrection? remote,
  }) {
    if (local == null) {
      return remote;
    }
    if (remote == null) {
      return local;
    }
    return local.correctedAt.isAfter(remote.correctedAt) ? local : remote;
  }
}
