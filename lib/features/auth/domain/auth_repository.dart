import 'dart:async';

/// Sesja użytkownika — pod Firebase Auth w kolejnych iteracjach.
enum AuthSessionState { unknown, signedOut, signedIn }

/// Repozytorium uwierzytelniania (placeholder). UI logowania jest przygotowane pod przyszłą integrację.
abstract class AuthRepository {
  Stream<AuthSessionState> watchSession();

  Future<AuthSessionState> readSession();

  Future<void> signOut();
}
