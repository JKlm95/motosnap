import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/remote/cloud_scan_sync_service.dart';
import '../../../core/remote/sync_summary.dart';
import '../../../core/sync/sync_restore_debug.dart';
import '../domain/pending_scan_sync.dart';
import '../domain/scan_repository.dart';
import '../domain/user_correction_remote_sink.dart';
import '../domain/user_vehicle_correction.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';
import 'firebase_sync_timed.dart';
import 'cloud_scan_collection_fetch.dart';
import 'cloud_scan_remote_pull.dart';
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

  /// Upload lokalnych `pendingSync` + pull zmian z Firestore dla zalogowanego użytkownika.
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }
    final uid = user.uid;
    final all = await localRepository.getRecentScans(1 << 20);
    final pending = all.where((s) => s.pendingSync).toList();

    if (kDebugMode) {
      debugPrint(
        '[Sync] start uid=$uid local=${all.length} pendingUpload=${pending.length}',
      );
    }

    var uploaded = 0;
    var failed = 0;
    final uploadedScanIds = <String>[];

    for (final scan in pending) {
      try {
        await _uploadSingleScan(localRepository, uid, scan);
        uploaded++;
        uploadedScanIds.add(scan.id);
        if (kDebugMode) {
          debugPrint('[Sync] upload ok scan=${scan.id}');
        }
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

    final pull = await _pullRemoteChanges(localRepository, uid);
    failed += pull.pullReadFailures;

    if (kDebugMode) {
      debugPrint(
        '[Sync] done uploaded=$uploaded failed=$failed '
        'downloaded=${pull.downloaded} updated=${pull.updated} '
        'pullSkipped=${pull.skipped} pullReadFailures=${pull.pullReadFailures}',
      );
    }

    return SyncSummary(
      uploaded: uploaded,
      failed: failed,
      uploadedScanIds: List<String>.unmodifiable(uploadedScanIds),
      downloaded: pull.downloaded,
      updated: pull.updated,
      downloadedScanIds: List<String>.unmodifiable(pull.downloadedScanIds),
      updatedScanIds: List<String>.unmodifiable(pull.updatedScanIds),
    );
  }

  Future<
    ({
      int downloaded,
      int updated,
      List<String> downloadedScanIds,
      List<String> updatedScanIds,
      int skipped,
      int pullReadFailures,
    })
  >
  _pullRemoteChanges(ScanRepository localRepository, String uid) async {
    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans');

    final locals = await localRepository.getRecentScans(1 << 20);
    final localById = {for (final s in locals) s.id: s};
    final coldStart = locals.isEmpty;

    SyncRestoreDebug.logPullContext(
      auth: _auth,
      firestore: _firestore,
      uid: uid,
      localScanCount: locals.length,
      coldStart: coldStart,
    );

    if (kDebugMode) {
      debugPrint(
        '[Sync] pull local scans=${locals.length} coldStart=$coldStart',
      );
    }

    final remoteById = <String, CloudScanRemoteDoc>{};
    var pullReadFailures = 0;
    var collectionParseSkipped = 0;

    // Główna ścieżka restore: lista kolekcji (reinstall / pusta Hive).
    try {
      final listed = await CloudScanCollectionFetch.fetchWithQueryFallback(
        collection: collection,
        executeQuery: (label, query) => firebaseSyncTimed(
          query.get(const GetOptions(source: Source.server)),
          kFirebaseSyncFirestoreReadTimeout,
          FirebaseSyncPhase.firestoreReadPull,
        ),
      );
      collectionParseSkipped = listed.parseSkipped;
      for (final doc in listed.docs) {
        remoteById[doc.id] = doc;
      }
      if (kDebugMode) {
        debugPrint(
          '[Sync] pull collection OK query=${listed.queryLabel} '
          'cloudDocs=${listed.docs.length} parseSkipped=$collectionParseSkipped',
        );
      }
    } on FirebaseException catch (e, st) {
      pullReadFailures++;
      SyncRestoreDebug.logFirebaseException(
        context: 'pull collection (all query variants failed)',
        e: e,
        stackTrace: st,
      );
      if (coldStart) {
        rethrow;
      }
    } on CloudScanCollectionFetchException catch (e, st) {
      pullReadFailures++;
      if (kDebugMode) {
        debugPrint('[Sync] pull collection FAILED: $e\n$st');
        final fe = e.lastFirebaseException;
        if (fe != null) {
          debugPrint(
            '[Sync] pull collection last Firebase code=${fe.code} '
            'message=${fe.message}',
          );
        }
      }
      if (coldStart) {
        rethrow;
      }
    } on Object catch (e, st) {
      pullReadFailures++;
      if (kDebugMode) {
        debugPrint('[Sync] pull collection FAILED: $e\n$st');
      }
      if (coldStart) {
        rethrow;
      }
    }

    // Uzupełnienie: lokalne scanId bez wpisu z listy (np. pending upload bez pełnej listy).
    if (!coldStart) {
      for (final scan in locals) {
        if (remoteById.containsKey(scan.id)) {
          continue;
        }
        try {
          final snap = await _fetchScanDocument(collection.doc(scan.id));
          if (!snap.exists) {
            if (kDebugMode) {
              debugPrint(
                '[Sync] pull skip ${scan.id}: brak dokumentu w chmurze',
              );
            }
            continue;
          }
          final data = snap.data();
          if (data == null) {
            continue;
          }
          remoteById[scan.id] = (
            id: scan.id,
            data: Map<String, dynamic>.from(data),
          );
        } on Object catch (e, st) {
          pullReadFailures++;
          SyncRestoreDebug.logPhaseFailure(
            phase: SyncRestoreFailurePhase.perScanRead,
            scanId: scan.id,
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    final remoteDocs = remoteById.values.toList(growable: false);
    if (kDebugMode) {
      debugPrint(
        '[Sync] pull merge local=${locals.length} '
        'cloudDocs=${remoteDocs.length} pullReadFailures=$pullReadFailures',
      );
    }

    final applied = await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: localRepository,
      localById: localById,
      remoteDocs: remoteDocs,
    );

    return (
      downloaded: applied.downloaded,
      updated: applied.updated,
      downloadedScanIds: applied.downloadedScanIds,
      updatedScanIds: applied.updatedScanIds,
      skipped: applied.skipped + collectionParseSkipped,
      pullReadFailures: pullReadFailures,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchScanDocument(
    DocumentReference<Map<String, dynamic>> doc,
  ) async {
    try {
      return await firebaseSyncTimed(
        doc.get(const GetOptions(source: Source.server)),
        kFirebaseSyncFirestoreReadTimeout,
        FirebaseSyncPhase.firestoreReadPull,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'failed-precondition') {
        if (kDebugMode) {
          debugPrint('[Sync] pull ${doc.id} server fetch fallback to default');
        }
        return firebaseSyncTimed(
          doc.get(),
          kFirebaseSyncFirestoreReadTimeout,
          FirebaseSyncPhase.firestoreReadPull,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }
    final scan = await localRepository.getScan(scanId);
    if (scan == null) {
      return;
    }
    final alreadySynced =
        !scan.pendingSync &&
        scan.remoteImageUrl != null &&
        scan.remoteImageUrl!.isNotEmpty;
    if (alreadySynced) {
      return;
    }
    if (!scan.pendingSync) {
      return;
    }
    try {
      await _uploadSingleScan(localRepository, user.uid, scan);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'FirebaseCloudSyncService.syncPendingScan scan=$scanId FAILED: $e\n$st',
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
            'scan=$scanId: $persistErr\n$persistSt',
          );
        }
      }
      rethrow;
    }
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
