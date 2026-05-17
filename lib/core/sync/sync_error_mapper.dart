import 'package:firebase_auth/firebase_auth.dart';

import '../../features/scan/data/firebase_sync_timed.dart';
import 'sync_user_error.dart';

/// Mapowanie wyjątków sync na komunikat UI (bez surowego Firebase w snackbarze).
abstract final class SyncErrorMapper {
  static SyncUserError userErrorFor(Object error) {
    if (error is StateError && error.message.contains('zalogowanego')) {
      return SyncUserError.notSignedIn;
    }
    if (error is FirebaseAuthException) {
      return SyncUserError.notSignedIn;
    }
    if (error is FirebaseSyncTimeoutException) {
      return SyncUserError.timedOut;
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => SyncUserError.permissionDenied,
        'unauthenticated' => SyncUserError.notSignedIn,
        'unavailable' || 'deadline-exceeded' => SyncUserError.timedOut,
        _ => SyncUserError.generic,
      };
    }
    return SyncUserError.generic;
  }
}
