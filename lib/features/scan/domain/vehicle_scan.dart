import 'scan_location.dart';
import 'vehicle_info.dart';
import 'vehicle_scan_status.dart';

/// Pełny model skanu (JSON snake_case — pod późniejsze API / Firestore).
///
/// Ręczne DTO (bez Freezed) ze względu na stabilność `build_runner` w tym projekcie.
class VehicleScan {
  const VehicleScan({
    required this.id,
    required this.localImagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.location,
    this.remoteImageUrl,
    this.vehicleInfo,
    this.isPublic = false,
    this.recognitionError,
    this.pendingSync = true,
    this.syncLastError,
  });

  final String id;
  final String localImagePath;
  final String? remoteImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VehicleScanStatus status;
  final ScanLocation location;
  final VehicleInfo? vehicleInfo;
  final bool isPublic;
  final String? recognitionError;
  final bool pendingSync;

  /// Ostatni błąd synchronizacji z chmurą (nie mylić z błędem rozpoznania AI).
  final String? syncLastError;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': 3,
      'id': id,
      'local_image_path': localImagePath,
      'remote_image_url': remoteImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.name,
      'location': location.toJson(),
      'vehicle_info': vehicleInfo?.toJson(),
      'is_public': isPublic,
      'recognition_error': recognitionError,
      'pending_sync': pendingSync,
      'sync_last_error': syncLastError,
    };
  }

  factory VehicleScan.fromJson(Map<String, dynamic> json) {
    final isV2 =
        json.containsKey('local_image_path') &&
        json['location'] is Map<String, dynamic>;
    if (!isV2) {
      return _fromLegacyJson(json);
    }

    final statusRaw = json['status'] as String? ?? 'waitingForRecognition';
    final status = _parseStatus(statusRaw);

    final infoRaw = json['vehicle_info'];
    final VehicleInfo? info;
    if (infoRaw is Map<String, dynamic>) {
      info = VehicleInfo.fromJson(infoRaw);
    } else {
      info = null;
    }

    return VehicleScan(
      id: json['id'] as String,
      localImagePath: json['local_image_path'] as String,
      remoteImageUrl: json['remote_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: status,
      location: ScanLocation.fromJson(
        Map<String, dynamic>.from(json['location'] as Map),
      ),
      vehicleInfo: info,
      isPublic: json['is_public'] as bool? ?? false,
      recognitionError: json['recognition_error'] as String?,
      pendingSync: json['pending_sync'] as bool? ?? true,
      syncLastError: json['sync_last_error'] as String?,
    );
  }

  static VehicleScan _fromLegacyJson(Map<String, dynamic> json) {
    final created = DateTime.parse(
      (json['captured_at'] ?? json['created_at']) as String,
    );
    final lat =
        (json['latitude'] as num?)?.toDouble() ??
        ((json['location'] as Map?)?['latitude'] as num?)?.toDouble() ??
        0.0;
    final lng =
        (json['longitude'] as num?)?.toDouble() ??
        ((json['location'] as Map?)?['longitude'] as num?)?.toDouble() ??
        0.0;
    final path = (json['local_image_path'] ?? json['image_path']) as String;

    return VehicleScan(
      id: json['id'] as String,
      localImagePath: path,
      remoteImageUrl: null,
      createdAt: created,
      updatedAt: created,
      status: VehicleScanStatus.waitingForRecognition,
      location: ScanLocation(latitude: lat, longitude: lng),
      vehicleInfo: null,
      isPublic: false,
      recognitionError: null,
      pendingSync: true,
      syncLastError: null,
    );
  }

  static VehicleScanStatus _parseStatus(String raw) {
    return VehicleScanStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => VehicleScanStatus.waitingForRecognition,
    );
  }

  VehicleScan copyWith({
    String? id,
    String? localImagePath,
    String? remoteImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    VehicleScanStatus? status,
    ScanLocation? location,
    VehicleInfo? vehicleInfo,
    bool? isPublic,
    String? recognitionError,
    bool? pendingSync,
    String? syncLastError,
    bool updateSyncLastError = false,
  }) {
    return VehicleScan(
      id: id ?? this.id,
      localImagePath: localImagePath ?? this.localImagePath,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      location: location ?? this.location,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      isPublic: isPublic ?? this.isPublic,
      recognitionError: recognitionError ?? this.recognitionError,
      pendingSync: pendingSync ?? this.pendingSync,
      syncLastError: updateSyncLastError ? syncLastError : this.syncLastError,
    );
  }
}
