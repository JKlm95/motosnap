import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/data/cloud_scan_collection_fetch.dart';
import 'package:motosnap/features/scan/data/firebase_sync_timed.dart';
import 'package:motosnap/core/sync/sync_error_mapper.dart';
import 'package:motosnap/core/sync/sync_user_error.dart';

void main() {
  test('permission-denied → permissionDenied', () {
    expect(
      SyncErrorMapper.userErrorFor(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      SyncUserError.permissionDenied,
    );
  });

  test('timeout → timedOut', () {
    expect(
      SyncErrorMapper.userErrorFor(
        FirebaseSyncTimeoutException(
          FirebaseSyncPhase.firestoreReadPull,
          const Duration(seconds: 15),
        ),
      ),
      SyncUserError.timedOut,
    );
  });

  test('failed-precondition → generic (nie permissionDenied)', () {
    expect(
      SyncErrorMapper.userErrorFor(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'index',
        ),
      ),
      SyncUserError.generic,
    );
  });

  test(
    'CloudScanCollectionFetchException z permission-denied → permissionDenied',
    () {
      expect(
        SyncErrorMapper.userErrorFor(
          CloudScanCollectionFetchException(
            message: 'fail',
            attemptedQueries: const ['q1'],
            lastFirebaseException: FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'rules',
            ),
          ),
        ),
        SyncUserError.permissionDenied,
      );
    },
  );

  test('CloudScanCollectionFetchException z failed-precondition → generic', () {
    expect(
      SyncErrorMapper.userErrorFor(
        CloudScanCollectionFetchException(
          message: 'fail',
          attemptedQueries: const ['orderBy', 'limit'],
          lastFirebaseException: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'index',
          ),
        ),
      ),
      SyncUserError.generic,
    );
  });
}
