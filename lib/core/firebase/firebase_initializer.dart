import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Result of attempting to initialize Firebase.
enum FirebaseInitStatus {
  /// [Firebase.initializeApp] completed successfully.
  ready,

  /// Initialization failed (missing/invalid config, network, etc.).
  failed,
}

/// Wraps [Firebase.initializeApp] with error handling — no secrets in code paths.
final class FirebaseInitializer {
  const FirebaseInitializer._();

  static FirebaseInitStatus? _status;

  static FirebaseInitStatus? get lastStatus => _status;

  /// Initializes Firebase using [DefaultFirebaseOptions] (from FlutterFire).
  /// On failure, logs and returns [FirebaseInitStatus.failed]; app may continue
  /// in a degraded mode (see bootstrap).
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
    } on Object catch (e, st) {
      debugPrint('FirebaseInitializer: init failed: $e\n$st');
      _status = FirebaseInitStatus.failed;
      return FirebaseInitStatus.failed;
    }
  }

  static bool get isReady => _status == FirebaseInitStatus.ready;
}
