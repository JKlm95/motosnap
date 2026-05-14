/// Status synchronizacji skanu z backendem (Firebase) — do podpięcia w kolejnych krokach.
enum ScanSyncStatus { pending, uploaded, failed }

/// Model skanu pojazdu (JSON snake_case — pod przyszłe API / Firestore).
///
/// Docelowo można tu wprowadzić Freezed + json_serializable po ustabilizowaniu
/// `build_runner` dla Twojej wersji SDK (Dart 3.10.x potrafi blokować codegen
/// przez „build hooks” w transitive dependencies).
class VehicleScan {
  const VehicleScan({
    required this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.syncStatus = ScanSyncStatus.pending,
  });

  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final ScanSyncStatus syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt.toIso8601String(),
      'sync_status': switch (syncStatus) {
        ScanSyncStatus.pending => 'pending',
        ScanSyncStatus.uploaded => 'uploaded',
        ScanSyncStatus.failed => 'failed',
      },
    };
  }

  factory VehicleScan.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['sync_status'] as String? ?? 'pending';
    final status = ScanSyncStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => ScanSyncStatus.pending,
    );
    return VehicleScan(
      id: json['id'] as String,
      imagePath: json['image_path'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      syncStatus: status,
    );
  }

  VehicleScan copyWith({
    String? id,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
    ScanSyncStatus? syncStatus,
  }) {
    return VehicleScan(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
