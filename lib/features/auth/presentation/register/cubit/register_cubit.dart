import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth_input_validators.dart';
import '../../../domain/auth_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._auth) : super(const RegisterState());

  final AuthRepository _auth;

  Future<void> submit({
    required String email,
    required String password,
    required void Function() onSuccessNavigate,
  }) async {
    final emailErr = AuthInputValidators.emailError(email);
    if (emailErr != null) {
      emit(RegisterState(status: RegisterStatus.idle, errorMessage: emailErr));
      return;
    }
    final passErr = AuthInputValidators.passwordRegisterError(password);
    if (passErr != null) {
      emit(RegisterState(status: RegisterStatus.idle, errorMessage: passErr));
      return;
    }

    emit(const RegisterState(status: RegisterStatus.loading));
    try {
      await _auth.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(const RegisterState(status: RegisterStatus.success));
      onSuccessNavigate();
    } on AuthFailure catch (e) {
      emit(RegisterState(status: RegisterStatus.idle, errorMessage: e.message));
    } on Object catch (e) {
      emit(
        RegisterState(status: RegisterStatus.idle, errorMessage: e.toString()),
      );
    }
  }

  void clearError() {
    emit(const RegisterState());
  }
}
