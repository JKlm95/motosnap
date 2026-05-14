import 'package:equatable/equatable.dart';

enum LoginStatus { idle, loading, success }

class LoginState extends Equatable {
  const LoginState({this.status = LoginStatus.idle, this.errorMessage});

  final LoginStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}
