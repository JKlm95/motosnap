import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';

/// Implementacja Firebase Auth + zapis profilu użytkownika w Firestore (`users/{uid}`).
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthSessionState> watchSession() {
    return _auth.authStateChanges().map(
      (user) =>
          user == null ? AuthSessionState.signedOut : AuthSessionState.signedIn,
    );
  }

  @override
  AuthSessionState readSessionSync() {
    return _auth.currentUser == null
        ? AuthSessionState.signedOut
        : AuthSessionState.signedIn;
  }

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    }
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set(<String, dynamic>{
          'email': email.trim(),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Nieprawidłowy adres e-mail.';
      case 'user-disabled':
        return 'To konto zostało wyłączone.';
      case 'user-not-found':
        return 'Nie znaleziono użytkownika z tym adresem.';
      case 'wrong-password':
        return 'Nieprawidłowe hasło.';
      case 'invalid-credential':
        return 'Nieprawidłowy e-mail lub hasło.';
      case 'email-already-in-use':
        return 'Ten adres e-mail jest już zarejestrowany.';
      case 'weak-password':
        return 'Hasło jest zbyt słabe.';
      case 'network-request-failed':
        return 'Brak połączenia z siecią. Spróbuj ponownie.';
      default:
        return e.message ?? 'Błąd uwierzytelniania (${e.code}).';
    }
  }
}
