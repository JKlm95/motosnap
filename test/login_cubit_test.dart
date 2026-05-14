import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/auth/domain/auth_repository.dart';
import 'package:motosnap/features/auth/presentation/login/cubit/login_cubit.dart';
import 'package:motosnap/features/auth/presentation/login/cubit/login_state.dart';

void main() {
  test('LoginCubit — walidacja pustego e-maila', () async {
    final cubit = LoginCubit(_FakeAuth());
    var navigated = false;
    await cubit.submit(
      email: '',
      password: 'secret12',
      onSuccessNavigate: () => navigated = true,
    );
    expect(cubit.state.errorMessage, isNotNull);
    expect(cubit.state.status, LoginStatus.idle);
    expect(navigated, isFalse);
    await cubit.close();
  });

  test('LoginCubit — sukces wywołuje nawigację', () async {
    final cubit = LoginCubit(_FakeAuth(ok: true));
    var navigated = false;
    await cubit.submit(
      email: 'a@b.com',
      password: 'secret12',
      onSuccessNavigate: () => navigated = true,
    );
    expect(cubit.state.status, LoginStatus.success);
    expect(navigated, isTrue);
    await cubit.close();
  });
}

final class _FakeAuth implements AuthRepository {
  _FakeAuth({this.ok = false});

  final bool ok;

  @override
  String? get currentUserEmail => ok ? 'a@b.com' : null;

  @override
  AuthSessionState readSessionSync() =>
      ok ? AuthSessionState.signedIn : AuthSessionState.signedOut;

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
  }) async {
    if (!ok) {
      throw const AuthFailure('Zły login.');
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSessionState> watchSession() => throw UnimplementedError();
}
