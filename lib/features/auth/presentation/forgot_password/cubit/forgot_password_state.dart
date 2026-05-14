import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus { idle, loading, success }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.errorMessage,
    this.infoMessage,
  });

  final ForgotPasswordStatus status;
  final String? errorMessage;
  final String? infoMessage;

  @override
  List<Object?> get props => [status, errorMessage, infoMessage];
}
