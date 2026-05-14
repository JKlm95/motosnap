import 'dart:async';

/// Stan sesji z perspektywy routingu i UI.
enum AuthSessionState {
  /// Firebase Auth jeszcze nie zwrócił pierwszego zdarzenia (np. przywracanie sesji).
  unknown,

  /// Brak zalogowanego użytkownika.
  signedOut,

  /// Użytkownik zalogowany.
  signedIn,
}

/// Błędy domenowe uwierzytelniania (komunikat bezpieczny do pokazania użytkownikowi).
final class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repozytorium uwierzytelniania (Firebase Auth lub tryb offline).
abstract class AuthRepository {
  Stream<AuthSessionState> watchSession();

  /// Bieżący stan sesji (na potrzeby synchronicznego redirectu w `go_router`).
  AuthSessionState readSessionSync();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  /// E-mail zalogowanego użytkownika lub `null`.
  String? get currentUserEmail;
}
