import 'package:equatable/equatable.dart';

enum RegisterStatus { idle, loading, success }

class RegisterState extends Equatable {
  const RegisterState({this.status = RegisterStatus.idle, this.errorMessage});

  final RegisterStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}
