import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Faza cold-start restore — do logów i mapowania błędów.
enum SyncRestoreFailurePhase {
  collectionQuery,
  documentParse,
  remoteMapping,
  hivePersist,
  perScanRead,
}

/// Debug-only kontekst pullu / restore (UID, ścieżka, projekt Firebase).
abstract final class SyncRestoreDebug {
  static const String productionProjectHint = 'motosnap-18101';
  static const String placeholderProjectId = 'motosnap-mvp';

  static void logPullContext({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String uid,
    required int localScanCount,
    required bool coldStart,
  }) {
    if (!kDebugMode) {
      return;
    }
    final user = auth.currentUser;
    final runtimeUid = user?.uid;
    final app = firestore.app;
    final runtime = app.options;
    final collectionPath = 'users/$uid/scans';

    debugPrint(
      '[Sync] restore context coldStart=$coldStart localScans=$localScanCount',
    );
    debugPrint(
      '[Sync] auth currentUser.uid=$runtimeUid '
      'email=${user?.email ?? "(null)"} '
      'matchesPullUid=${runtimeUid == uid}',
    );
    debugPrint('[Sync] firestore path=$collectionPath');
    debugPrint(
      '[Sync] firebase runtime projectId=${runtime.projectId} '
      'appId=${runtime.appId} storageBucket=${runtime.storageBucket}',
    );

    try {
      final dartOpts = DefaultFirebaseOptions.currentPlatform;
      final dartMismatch = dartOpts.projectId != runtime.projectId;
      debugPrint(
        '[Sync] firebase dart DefaultFirebaseOptions.projectId=${dartOpts.projectId} '
        'mismatchRuntime=$dartMismatch',
      );
    } on Object catch (e) {
      debugPrint('[Sync] firebase dart options unavailable: $e');
    }

    if (runtime.projectId == placeholderProjectId) {
      debugPrint(
        '[Sync] WARN runtime projectId=$placeholderProjectId (placeholder) — '
        'dane produkcyjne są pod $productionProjectHint; '
        'sprawdź flutterfire configure / google-services.json lokalnie',
      );
    } else if (runtime.projectId != productionProjectHint) {
      debugPrint(
        '[Sync] NOTE runtime projectId=${runtime.projectId} (oczekiwany prod: '
        '$productionProjectHint)',
      );
    }

    if (runtimeUid != null && runtimeUid != uid) {
      debugPrint(
        '[Sync] WARN pull uid=$uid różni się od Auth.currentUser.uid=$runtimeUid',
      );
    }
  }

  static void logFirebaseException({
    required String context,
    required FirebaseException e,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[Sync] FirebaseException context=$context '
      'plugin=${e.plugin} code=${e.code} message=${e.message}',
    );
    if (stackTrace != null) {
      debugPrint('[Sync] stack: $stackTrace');
    }
  }

  static void logPhaseFailure({
    required SyncRestoreFailurePhase phase,
    required String scanId,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }
    if (error is FirebaseException) {
      logFirebaseException(
        context: '${phase.name} scanId=$scanId',
        e: error,
        stackTrace: stackTrace,
      );
      return;
    }
    debugPrint('[Sync] ${phase.name} scanId=$scanId error=$error');
    if (stackTrace != null) {
      debugPrint('[Sync] stack: $stackTrace');
    }
  }
}
