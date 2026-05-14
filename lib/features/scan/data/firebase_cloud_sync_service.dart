import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/remote/cloud_scan_sync_service.dart';
import '../../../core/remote/sync_summary.dart';
import '../domain/pending_scan_sync.dart';
import '../domain/scan_repository.dart';
import '../domain/vehicle_scan.dart';

/// Konservatywna integracja z Firebase: automatyczny upload po zapisie lokalnym
/// jest wyłączony — użytkownik uruchamia sync ręcznie z ustawień.
final class FirebaseCloudSyncService
    implements CloudScanSyncService, PendingScanSync {
  FirebaseCloudSyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<void> enqueueForUpload(VehicleScan scan) async {
    // Świadomie puste: brak automatycznego uploadu w tej iteracji MVP.
  }

  /// Wgrywa wszystkie lokalne skany z `pendingSync == true` dla zalogowanego użytkownika.
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }
    final uid = user.uid;
    final all = await localRepository.getRecentScans(1 << 20);
    final pending = all.where((s) => s.pendingSync).toList();
    var uploaded = 0;
    var failed = 0;

    for (final scan in pending) {
      try {
        await _uploadSingleScan(localRepository, uid, scan);
        uploaded++;
      } on Object catch (e) {
        failed++;
        await localRepository.updateScan(
          scan.copyWith(
            syncLastError: e.toString(),
            updateSyncLastError: true,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
    }
    return SyncSummary(uploaded: uploaded, failed: failed);
  }

  Future<void> _uploadSingleScan(
    ScanRepository localRepository,
    String uid,
    VehicleScan scan,
  ) async {
    final file = File(scan.localImagePath);
    if (!await file.exists()) {
      throw Exception('Brak pliku lokalnego: ${scan.localImagePath}');
    }

    final storagePath = 'users/$uid/scans/${scan.id}/original.jpg';
    final ref = _storage.ref().child(storagePath);
    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: <String, String>{'scan_id': scan.id, 'owner_uid': uid},
      ),
    );
    final downloadUrl = await ref.getDownloadURL();

    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .doc(scan.id);

    final publicApprox = <String, dynamic>{
      'city': scan.location.city,
      'country': scan.location.country,
      'display_name': scan.location.displayName,
    };

    final exact = <String, dynamic>{
      'latitude': scan.location.latitude,
      'longitude': scan.location.longitude,
    };

    await doc.set(<String, dynamic>{
      'created_at': Timestamp.fromDate(scan.createdAt),
      'updated_at': Timestamp.fromDate(scan.updatedAt),
      'status': scan.status.name,
      'is_public': scan.isPublic,
      'remote_image_url': downloadUrl,
      'exact_location': exact,
      'public_location_approximation': publicApprox,
      'vehicle_info': scan.vehicleInfo?.toJson(),
      'recognition_error': scan.recognitionError,
      'schema_version': 3,
    }, SetOptions(merge: true));

    await localRepository.updateScan(
      scan.copyWith(
        remoteImageUrl: downloadUrl,
        pendingSync: false,
        syncLastError: null,
        updateSyncLastError: true,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
