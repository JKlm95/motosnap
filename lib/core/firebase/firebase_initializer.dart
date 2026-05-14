import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Result of attempting to initialize Firebase.
enum FirebaseInitStatus {
  /// Domyślna aplikacja Firebase jest dostępna (świeżo zainicjalizowana lub już istniejąca).
  ready,

  /// Inicjalizacja nie powiodła się (brak/niepoprawna konfiguracja, sieć itd.) —
  /// **nie** obejmuje sytuacji „app już istnieje” (to traktujemy jako [ready]).
  failed,
}

/// Idempotentna inicjalizacja Firebase — bezpieczna przy auto-init z natywnego
/// `google-services` / wielokrotnym wywołaniu z Dartu.
final class FirebaseInitializer {
  const FirebaseInitializer._();

  static FirebaseInitStatus? _status;

  static FirebaseInitStatus? get lastStatus => _status;

  /// Jeśli [Firebase.apps] nie jest puste, używa istniejącej aplikacji (np. [Firebase.app]).
  /// W przeciwnym razie wywołuje [Firebase.initializeApp].
  /// [FirebaseException] z kodem `duplicate-app` uznaje za sukces — aplikacja już istnieje.
  static Future<FirebaseInitStatus> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      _status = FirebaseInitStatus.ready;
      return FirebaseInitStatus.ready;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _status = FirebaseInitStatus.ready;
      return FirebaseInitStatus.ready;
    } on FirebaseException catch (e, st) {
      if (_isDuplicateDefaultAppError(e)) {
        debugPrint(
          'FirebaseInitializer: default app already exists (duplicate-app), '
          'reusing.\n$st',
        );
        _status = FirebaseInitStatus.ready;
        return FirebaseInitStatus.ready;
      }
      debugPrint('FirebaseInitializer: init failed: $e\n$st');
      _status = FirebaseInitStatus.failed;
      return FirebaseInitStatus.failed;
    } on Object catch (e, st) {
      if (e is FirebaseException && _isDuplicateDefaultAppError(e)) {
        debugPrint(
          'FirebaseInitializer: default app already exists (duplicate-app), '
          'reusing.\n$st',
        );
        _status = FirebaseInitStatus.ready;
        return FirebaseInitStatus.ready;
      }
      debugPrint('FirebaseInitializer: init failed: $e\n$st');
      _status = FirebaseInitStatus.failed;
      return FirebaseInitStatus.failed;
    }
  }

  static bool _isDuplicateDefaultAppError(FirebaseException e) {
    return e.code == 'duplicate-app';
  }

  /// Do testów jednostkowych — ta sama logika co przy obsłudze [Firebase.initializeApp].
  @visibleForTesting
  static bool isDuplicateDefaultAppErrorForTesting(FirebaseException e) =>
      _isDuplicateDefaultAppError(e);

  static bool get isReady => _status == FirebaseInitStatus.ready;
}
