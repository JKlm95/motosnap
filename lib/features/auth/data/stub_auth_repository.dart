import 'dart:async';

import '../domain/auth_repository.dart';

/// Tymczasowa implementacja: brak Firebase — emituje [AuthSessionState.signedOut].
class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSessionState>.broadcast();

  StubAuthRepository() {
    _controller.add(AuthSessionState.signedOut);
  }

  @override
  Stream<AuthSessionState> watchSession() => _controller.stream;

  @override
  Future<AuthSessionState> readSession() async => AuthSessionState.signedOut;

  @override
  Future<void> signOut() async {
    _controller.add(AuthSessionState.signedOut);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
