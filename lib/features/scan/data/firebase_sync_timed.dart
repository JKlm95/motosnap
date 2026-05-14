import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Limity czasu dla ręcznej synchronizacji (Ustawienia → Synchronizuj teraz).
const Duration kFirebaseSyncStorageUploadTimeout = Duration(seconds: 30);
const Duration kFirebaseSyncFirestoreWriteTimeout = Duration(seconds: 15);
const Duration kFirebaseSyncFirestoreReadTimeout = Duration(seconds: 15);

/// Etykiety faz — [FirebaseSyncTimeoutException.phase] i logi developerskie.
abstract final class FirebaseSyncPhase {
  static const storageUpload = 'storage_upload';
  static const firestoreReadExisting = 'firestore_read_existing';
  static const firestoreWrite = 'firestore_write';
  static const firestoreReadAfterWrite = 'firestore_read_after_write';
}

/// Wartości [VehicleScan.syncLastError] — bez surowego tekstu Firebase w UI/Hive.
abstract final class FirebaseSyncStoredErrors {
  static const storageTimeout = 'SYNC_STORAGE_TIMEOUT';
  static const firestoreReadTimeout = 'SYNC_FIRESTORE_READ_TIMEOUT';
  static const firestoreWriteTimeout = 'SYNC_FIRESTORE_WRITE_TIMEOUT';
  static const missingLocalFile = 'SYNC_MISSING_LOCAL_FILE';
  static const storageFailed = 'SYNC_STORAGE_FAILED';
  static const firestoreFailed = 'SYNC_FIRESTORE_FAILED';
  static const mergeInvariant = 'SYNC_MERGE_INVARIANT';
  static const unknown = 'SYNC_UNKNOWN';
}

final class FirebaseSyncTimeoutException implements Exception {
  FirebaseSyncTimeoutException(this.phase, this.limit);
  final String phase;
  final Duration limit;

  @override
  String toString() =>
      'FirebaseSyncTimeoutException(phase=$phase, limit=${limit.inSeconds}s)';
}

final class SyncLocalFileMissing implements Exception {
  SyncLocalFileMissing(this.path);
  final String path;

  @override
  String toString() => 'SyncLocalFileMissing($path)';
}

final class FirebaseSyncMergeException implements Exception {
  FirebaseSyncMergeException(this.detail);
  final String detail;

  @override
  String toString() => 'FirebaseSyncMergeException($detail)';
}

Future<T> firebaseSyncTimed<T>(
  Future<T> future,
  Duration timeout,
  String phase,
) async {
  try {
    return await future.timeout(timeout);
  } on TimeoutException catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        'Firebase sync TIMEOUT phase=$phase limit=${timeout.inMilliseconds}ms: $e\n$st',
      );
    }
    throw FirebaseSyncTimeoutException(phase, timeout);
  }
}

String firebaseSyncStoredErrorCode(Object error) {
  if (error is FirebaseSyncTimeoutException) {
    return switch (error.phase) {
      FirebaseSyncPhase.storageUpload =>
        FirebaseSyncStoredErrors.storageTimeout,
      FirebaseSyncPhase.firestoreReadExisting ||
      FirebaseSyncPhase.firestoreReadAfterWrite =>
        FirebaseSyncStoredErrors.firestoreReadTimeout,
      FirebaseSyncPhase.firestoreWrite =>
        FirebaseSyncStoredErrors.firestoreWriteTimeout,
      _ => FirebaseSyncStoredErrors.unknown,
    };
  }
  if (error is SyncLocalFileMissing) {
    return FirebaseSyncStoredErrors.missingLocalFile;
  }
  if (error is FirebaseSyncMergeException) {
    return FirebaseSyncStoredErrors.mergeInvariant;
  }
  if (error is FirebaseException) {
    final p = error.plugin;
    if (p == 'firebase_storage') {
      return FirebaseSyncStoredErrors.storageFailed;
    }
    if (p == 'cloud_firestore') {
      return FirebaseSyncStoredErrors.firestoreFailed;
    }
    return FirebaseSyncStoredErrors.unknown;
  }
  return FirebaseSyncStoredErrors.unknown;
}
