import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
