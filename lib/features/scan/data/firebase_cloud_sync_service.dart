import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/remote/cloud_scan_sync_service.dart';
import '../../../core/remote/sync_summary.dart';
import '../domain/pending_scan_sync.dart';
import '../domain/scan_repository.dart';
import '../domain/user_correction_remote_sink.dart';
import '../domain/user_vehicle_correction.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';
import 'firebase_sync_timed.dart';
import 'vehicle_scan_remote_merger.dart';

/// Konservatywna integracja z Firebase: automatyczny upload po zapisie lokalnym
/// jest wyłączony — użytkownik uruchamia sync ręcznie z ustawień.
final class FirebaseCloudSyncService
    implements CloudScanSyncService, PendingScanSync, UserCorrectionRemoteSink {
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
    final uploadedScanIds = <String>[];

    for (final scan in pending) {
      try {
        await _uploadSingleScan(localRepository, uid, scan);
        uploaded++;
        uploadedScanIds.add(scan.id);
      } on Object catch (e, st) {
        failed++;
        if (kDebugMode) {
          debugPrint(
            'FirebaseCloudSyncService.syncAllPending scan=${scan.id} FAILED: $e\n$st',
          );
        }
        final code = firebaseSyncStoredErrorCode(e);
        try {
          await localRepository.updateScan(
            scan.copyWith(
              syncLastError: code,
              pendingSync: true,
              updateSyncLastError: true,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        } on Object catch (persistErr, persistSt) {
          if (kDebugMode) {
            debugPrint(
              'FirebaseCloudSyncService: could not persist sync error for '
              'scan=${scan.id}: $persistErr\n$persistSt',
            );
          }
        }
      }
    }
    return SyncSummary(
      uploaded: uploaded,
      failed: failed,
      uploadedScanIds: List<String>.unmodifiable(uploadedScanIds),
    );
  }

  @override
  Future<void> pushUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final uid = user.uid;
    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .doc(scanId);
    final snap = await doc.get();
    if (!snap.exists) {
      return;
    }
    await doc.set(<String, dynamic>{
      'user_correction': _userCorrectionToFirestore(correction),
      'updated_at': FieldValue.serverTimestamp(),
      'schema_version': 4,
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _userCorrectionToFirestore(UserVehicleCorrection c) {
    return <String, dynamic>{
      'vehicle_type': c.vehicleType.name,
      'brand': c.brand,
      'model': c.model,
      'generation': c.generation,
      'production_years': c.productionYears,
      'possible_engines': c.possibleEngines,
      'short_description': c.shortDescription,
      'corrected_at': Timestamp.fromDate(c.correctedAt),
      'source': c.source,
    };
  }

  Future<void> _uploadSingleScan(
    ScanRepository localRepository,
    String uid,
    VehicleScan scan,
  ) async {
    final file = File(scan.localImagePath);
    if (!await file.exists()) {
      throw SyncLocalFileMissing(scan.localImagePath);
    }

    final storagePath = 'users/$uid/scans/${scan.id}/original.jpg';
    final ref = _storage.ref().child(storagePath);

    final downloadUrl = await firebaseSyncTimed(
      Future(() async {
        await ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: <String, String>{
              'scan_id': scan.id,
              'owner_uid': uid,
            },
          ),
        );
        return ref.getDownloadURL();
      }),
      kFirebaseSyncStorageUploadTimeout,
      FirebaseSyncPhase.storageUpload,
    );

    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .doc(scan.id);

    final existing = await firebaseSyncTimed(
      doc.get(),
      kFirebaseSyncFirestoreReadTimeout,
      FirebaseSyncPhase.firestoreReadExisting,
    );
    final docExists = existing.exists;

    final payload = _clientScanMergePayload(
      scan: scan,
      downloadUrl: downloadUrl,
      docExists: docExists,
    );

    await firebaseSyncTimed(
      doc.set(payload, SetOptions(merge: true)),
      kFirebaseSyncFirestoreWriteTimeout,
      FirebaseSyncPhase.firestoreWrite,
    );

    final mergedSnap = await firebaseSyncTimed(
      doc.get(),
      kFirebaseSyncFirestoreReadTimeout,
      FirebaseSyncPhase.firestoreReadAfterWrite,
    );
    if (!mergedSnap.exists) {
      throw FirebaseSyncMergeException('missing_doc_after_write');
    }
    final remoteData = mergedSnap.data();
    if (remoteData == null) {
      throw FirebaseSyncMergeException('empty_doc_after_write');
    }

    final merged = VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
      local: scan,
      remote: Map<String, dynamic>.from(remoteData),
      remoteImageUrl: downloadUrl,
    );

    await localRepository.updateScan(merged);
  }

  /// Pola AI i statusu końcowego nie są tu ustawiane przy istniejącym dokumencie — zapobiega
  /// przypadkowemu nadpisaniu wyniku z Cloud Function lokalnym stanem „oczekiwanie”.
  Map<String, dynamic> _clientScanMergePayload({
    required VehicleScan scan,
    required String downloadUrl,
    required bool docExists,
  }) {
    final publicApprox = <String, dynamic>{
      'city': scan.location.city,
      'country': scan.location.country,
      'display_name': scan.location.displayName,
    };

    final exact = <String, dynamic>{
      'latitude': scan.location.latitude,
      'longitude': scan.location.longitude,
    };

    final payload = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
      'remote_image_url': downloadUrl,
      'is_public': scan.isPublic,
      'exact_location': exact,
      'public_location_approximation': publicApprox,
      'schema_version': 4,
    };

    if (scan.userCorrection != null) {
      payload['user_correction'] = _userCorrectionToFirestore(
        scan.userCorrection!,
      );
    }

    if (!docExists) {
      payload['created_at'] = Timestamp.fromDate(scan.createdAt);
      payload['status'] = VehicleScanStatus.waitingForRecognition.name;
    }

    return payload;
  }
}
