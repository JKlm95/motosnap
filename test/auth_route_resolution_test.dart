import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/app/router/app_routes.dart';
import 'package:motosnap/app/router/auth_route_resolution.dart';
import 'package:motosnap/features/auth/domain/auth_repository.dart';

void main() {
  test('AuthRouteResolution — niezalogowany: shell → login', () {
    final r = _FakeAuth(AuthSessionState.signedOut);
    expect(
      AuthRouteResolution.redirect(auth: r, location: AppRoutes.scanRelative),
      AppRoutes.login,
    );
  });

  test('AuthRouteResolution — niezalogowany: splash → null', () {
    final r = _FakeAuth(AuthSessionState.signedOut);
    expect(
      AuthRouteResolution.redirect(auth: r, location: AppRoutes.splash),
      isNull,
    );
  });

  test('AuthRouteResolution — zalogowany: login → scan', () {
    final r = _FakeAuth(AuthSessionState.signedIn);
    expect(
      AuthRouteResolution.redirect(auth: r, location: AppRoutes.login),
      AppRoutes.scanRelative,
    );
  });

  test('AuthRouteResolution — zalogowany: splash → null', () {
    final r = _FakeAuth(AuthSessionState.signedIn);
    expect(
      AuthRouteResolution.redirect(auth: r, location: AppRoutes.splash),
      isNull,
    );
  });

  test('AuthRouteResolution — zalogowany: vehicle-scan → null', () {
    final r = _FakeAuth(AuthSessionState.signedIn);
    expect(
      AuthRouteResolution.redirect(
        auth: r,
        location: AppRoutes.vehicleScan('x'),
      ),
      isNull,
    );
  });
}

final class _FakeAuth implements AuthRepository {
  _FakeAuth(this._session);

  final AuthSessionState _session;

  @override
  String? get currentUserEmail => null;

  @override
  AuthSessionState readSessionSync() => _session;

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Stream<AuthSessionState> watchSession() => throw UnimplementedError();
}
