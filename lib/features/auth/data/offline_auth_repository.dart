import 'dart:async';

import '../domain/auth_repository.dart';

/// Używane gdy Firebase nie został poprawnie zainicjalizowany (np. brak `flutterfire configure`).
final class OfflineAuthRepository implements AuthRepository {
  OfflineAuthRepository();

  final _controller = StreamController<AuthSessionState>.broadcast();

  @override
  Stream<AuthSessionState> watchSession() async* {
    yield AuthSessionState.signedOut;
    yield* _controller.stream;
  }

  @override
  AuthSessionState readSessionSync() => AuthSessionState.signedOut;

  @override
  String? get currentUserEmail => null;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure(
      'Firebase nie jest skonfigurowany. Uruchom `flutterfire configure` i dodaj prawdziwe pliki konfiguracyjne.',
    );
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure(
      'Firebase nie jest skonfigurowany. Uruchom `flutterfire configure`.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw const AuthFailure(
      'Firebase nie jest skonfigurowany. Uruchom `flutterfire configure`.',
    );
  }

  @override
  Future<void> signOut() async {
    _controller.add(AuthSessionState.signedOut);
  }
}
