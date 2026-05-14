import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth_input_validators.dart';
import '../../../domain/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth) : super(const LoginState());

  final AuthRepository _auth;

  Future<void> submit({
    required String email,
    required String password,
    required void Function() onSuccessNavigate,
  }) async {
    final emailErr = AuthInputValidators.emailError(email);
    if (emailErr != null) {
      emit(LoginState(status: LoginStatus.idle, errorMessage: emailErr));
      return;
    }
    final passErr = AuthInputValidators.passwordSignInError(password);
    if (passErr != null) {
      emit(LoginState(status: LoginStatus.idle, errorMessage: passErr));
      return;
    }

    emit(const LoginState(status: LoginStatus.loading));
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      emit(const LoginState(status: LoginStatus.success));
      onSuccessNavigate();
    } on AuthFailure catch (e) {
      emit(LoginState(status: LoginStatus.idle, errorMessage: e.message));
    } on Object catch (e) {
      emit(LoginState(status: LoginStatus.idle, errorMessage: e.toString()));
    }
  }

  void clearError() {
    emit(const LoginState());
  }
}
