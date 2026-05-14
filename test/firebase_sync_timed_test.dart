import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/data/firebase_sync_timed.dart';

void main() {
  group('firebaseSyncTimed', () {
    test('zwraca wartość gdy future kończy się w limicie', () async {
      final v = await firebaseSyncTimed(
        Future.value(42),
        const Duration(seconds: 1),
        'test',
      );
      expect(v, 42);
    });

    test(
      'rzuca FirebaseSyncTimeoutException gdy future przekracza limit',
      () async {
        await expectLater(
          firebaseSyncTimed(
            Future<void>.delayed(const Duration(seconds: 30)),
            const Duration(milliseconds: 20),
            FirebaseSyncPhase.storageUpload,
          ),
          throwsA(isA<FirebaseSyncTimeoutException>()),
        );
      },
    );
  });

  group('firebaseSyncStoredErrorCode', () {
    test('timeout uploadu → SYNC_STORAGE_TIMEOUT', () {
      expect(
        firebaseSyncStoredErrorCode(
          FirebaseSyncTimeoutException(
            FirebaseSyncPhase.storageUpload,
            const Duration(seconds: 30),
          ),
        ),
        FirebaseSyncStoredErrors.storageTimeout,
      );
    });

    test('timeout odczytu Firestore → SYNC_FIRESTORE_READ_TIMEOUT', () {
      expect(
        firebaseSyncStoredErrorCode(
          FirebaseSyncTimeoutException(
            FirebaseSyncPhase.firestoreReadExisting,
            const Duration(seconds: 15),
          ),
        ),
        FirebaseSyncStoredErrors.firestoreReadTimeout,
      );
    });

    test('timeout zapisu Firestore → SYNC_FIRESTORE_WRITE_TIMEOUT', () {
      expect(
        firebaseSyncStoredErrorCode(
          FirebaseSyncTimeoutException(
            FirebaseSyncPhase.firestoreWrite,
            const Duration(seconds: 15),
          ),
        ),
        FirebaseSyncStoredErrors.firestoreWriteTimeout,
      );
    });

    test('SyncLocalFileMissing → SYNC_MISSING_LOCAL_FILE', () {
      expect(
        firebaseSyncStoredErrorCode(SyncLocalFileMissing('/x/y.jpg')),
        FirebaseSyncStoredErrors.missingLocalFile,
      );
    });

    test('FirebaseException storage → SYNC_STORAGE_FAILED', () {
      expect(
        firebaseSyncStoredErrorCode(
          FirebaseException(plugin: 'firebase_storage', message: 'net'),
        ),
        FirebaseSyncStoredErrors.storageFailed,
      );
    });

    test('FirebaseException firestore → SYNC_FIRESTORE_FAILED', () {
      expect(
        firebaseSyncStoredErrorCode(
          FirebaseException(plugin: 'cloud_firestore', message: 'denied'),
        ),
        FirebaseSyncStoredErrors.firestoreFailed,
      );
    });

    test('nieznany wyjątek → SYNC_UNKNOWN', () {
      expect(
        firebaseSyncStoredErrorCode(Exception('raw')),
        FirebaseSyncStoredErrors.unknown,
      );
    });
  });
}
