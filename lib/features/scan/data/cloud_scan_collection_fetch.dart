import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_restore_debug.dart';

/// Limit dokumentów przy cold-start restore z Firestore.
const int kCloudRestoreScanLimit = 500;

/// Wynik listowania kolekcji `users/{uid}/scans`.
typedef CloudScanRemoteDoc = ({String id, Map<String, dynamic> data});

/// Pobranie listy skanów z chmury (cold start / pełny restore).
abstract final class CloudScanCollectionFetch {
  /// Kolejność: `created_at` → `createdAt` (legacy) → bez orderBy.
  static List<Query<Map<String, dynamic>>> restoreQueries(
    CollectionReference<Map<String, dynamic>> collection,
  ) {
    return <Query<Map<String, dynamic>>>[
      collection
          .orderBy('created_at', descending: true)
          .limit(kCloudRestoreScanLimit),
      collection
          .orderBy('createdAt', descending: true)
          .limit(kCloudRestoreScanLimit),
      collection.limit(kCloudRestoreScanLimit),
    ];
  }

  static List<String> restoreQueryLabels() {
    return <String>[
      'orderBy(created_at desc, limit $kCloudRestoreScanLimit)',
      'orderBy(createdAt desc, limit $kCloudRestoreScanLimit)',
      'limit($kCloudRestoreScanLimit) no orderBy',
    ];
  }

  /// Wykonuje zapytania po kolei aż jedno się uda.
  static Future<
    ({List<CloudScanRemoteDoc> docs, int parseSkipped, String queryLabel})
  >
  fetchWithQueryFallback({
    required CollectionReference<Map<String, dynamic>> collection,
    required Future<QuerySnapshot<Map<String, dynamic>>> Function(
      String queryLabel,
      Query<Map<String, dynamic>> query,
    )
    executeQuery,
  }) {
    final queries = restoreQueries(collection);
    final labels = restoreQueryLabels();
    return fetchWithAttempts(
      labels: labels,
      executeQuery: (label, index) => executeQuery(label, queries[index]),
    );
  }

  /// Wykonuje zapytania po kolei (testowalne bez mockowania [Query]).
  @visibleForTesting
  static Future<
    ({List<CloudScanRemoteDoc> docs, int parseSkipped, String queryLabel})
  >
  fetchWithAttempts({
    required List<String> labels,
    required Future<QuerySnapshot<Map<String, dynamic>>> Function(
      String queryLabel,
      int queryIndex,
    )
    executeQuery,
  }) async {
    FirebaseException? lastFirebase;
    final attempted = <String>[];

    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      attempted.add(label);
      if (kDebugMode) {
        debugPrint(
          '[Sync] collection query attempt ${i + 1}/${labels.length}: $label',
        );
      }
      try {
        final snap = await executeQuery(label, i);
        if (kDebugMode) {
          debugPrint(
            '[Sync] collection query OK ($label) rawDocs=${snap.docs.length}',
          );
        }
        final parsed = documentsFromSnapshot(snap);
        if (kDebugMode && snap.docs.isNotEmpty) {
          final sample = snap.docs.first.data();
          final keys = sample.keys.take(12).join(', ');
          debugPrint('[Sync] collection sample doc keys: $keys');
        }
        return (
          docs: parsed.docs,
          parseSkipped: parsed.parseSkipped,
          queryLabel: label,
        );
      } on FirebaseException catch (e, st) {
        lastFirebase = e;
        SyncRestoreDebug.logFirebaseException(
          context: 'collectionQuery:$label',
          e: e,
          stackTrace: st,
        );
        if (_isNonRetriableQueryError(e)) {
          if (kDebugMode) {
            debugPrint(
              '[Sync] collection query abort (non-retriable ${e.code}) — '
              'nie próbuję dalszego fallbacku',
            );
          }
          rethrow;
        }
        if (_isRetriableQueryError(e)) {
          if (kDebugMode) {
            debugPrint(
              '[Sync] collection query retry next fallback po ${e.code}',
            );
          }
          continue;
        }
        rethrow;
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint('[Sync] collection query failed ($label): $e\n$st');
        }
        continue;
      }
    }

    throw CloudScanCollectionFetchException(
      message: 'Nie udało się pobrać listy skanów z Firestore',
      attemptedQueries: attempted,
      lastFirebaseException: lastFirebase,
    );
  }

  /// Indeks / złe pole — spróbuj kolejnego wariantu query.
  static bool _isRetriableQueryError(FirebaseException e) {
    return e.code == 'failed-precondition' || e.code == 'invalid-argument';
  }

  /// Rules / auth / zły projekt — fallback query nie pomoże.
  static bool _isNonRetriableQueryError(FirebaseException e) {
    return e.code == 'permission-denied' ||
        e.code == 'unauthenticated' ||
        e.code == 'not-found';
  }

  /// Mapuje snapshot → dokumenty; uszkodzone wpisy są pomijane (nie blokują reszty).
  static ({List<CloudScanRemoteDoc> docs, int parseSkipped})
  documentsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final docs = <CloudScanRemoteDoc>[];
    var parseSkipped = 0;

    for (final d in snap.docs) {
      try {
        final data = d.data();
        docs.add((id: d.id, data: Map<String, dynamic>.from(data)));
      } on Object catch (e, st) {
        parseSkipped++;
        SyncRestoreDebug.logPhaseFailure(
          phase: SyncRestoreFailurePhase.documentParse,
          scanId: d.id,
          error: e,
          stackTrace: st,
        );
      }
    }

    return (docs: docs, parseSkipped: parseSkipped);
  }
}

/// Wszystkie warianty query kolekcji zawiodły.
final class CloudScanCollectionFetchException implements Exception {
  CloudScanCollectionFetchException({
    required this.message,
    required this.attemptedQueries,
    this.lastFirebaseException,
  });

  final String message;
  final List<String> attemptedQueries;
  final FirebaseException? lastFirebaseException;

  @override
  String toString() {
    final fe = lastFirebaseException;
    if (fe == null) {
      return '$message (attempts: ${attemptedQueries.join(' → ')})';
    }
    return '$message: [${fe.plugin}/${fe.code}] ${fe.message} '
        '(attempts: ${attemptedQueries.join(' → ')})';
  }
}
