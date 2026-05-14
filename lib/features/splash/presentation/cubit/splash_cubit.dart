import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/auth_repository.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._auth) : super(const SplashState());

  final AuthRepository _auth;

  Future<void> runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    try {
      await _auth.watchSession().first.timeout(const Duration(seconds: 4));
    } on Object {
      // Ignorujemy timeout — i tak sprawdzamy stan synchronicznie poniżej.
    }
    final signedIn = _auth.readSessionSync() == AuthSessionState.signedIn;
    emit(
      SplashState(
        phase: SplashPhase.done,
        destination: signedIn
            ? SplashDestination.shell
            : SplashDestination.login,
      ),
    );
  }
}
