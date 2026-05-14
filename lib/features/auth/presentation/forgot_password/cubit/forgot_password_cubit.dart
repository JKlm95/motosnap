import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth_input_validators.dart';
import '../../../domain/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._auth) : super(const ForgotPasswordState());

  final AuthRepository _auth;

  Future<void> submit(String email) async {
    final emailErr = AuthInputValidators.emailError(email);
    if (emailErr != null) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.idle,
          errorMessage: emailErr,
        ),
      );
      return;
    }

    emit(const ForgotPasswordState(status: ForgotPasswordStatus.loading));
    try {
      await _auth.sendPasswordResetEmail(email);
      emit(
        const ForgotPasswordState(
          status: ForgotPasswordStatus.success,
          infoMessage:
              'Jeśli konto istnieje, wyślemy wiadomość z linkiem resetu hasła.',
        ),
      );
    } on AuthFailure catch (e) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.idle,
          errorMessage: e.message,
        ),
      );
    } on Object catch (e) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.idle,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void reset() {
    emit(const ForgotPasswordState());
  }
}
