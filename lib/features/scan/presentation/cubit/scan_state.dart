import 'package:equatable/equatable.dart';

enum ScanUiStatus { idle, working, success, error }

class ScanState extends Equatable {
  const ScanState({
    this.status = ScanUiStatus.idle,
    this.userMessage,
    this.lastSavedId,
  });

  final ScanUiStatus status;
  final String? userMessage;
  final String? lastSavedId;

  ScanState copyWith({
    ScanUiStatus? status,
    String? userMessage,
    String? lastSavedId,
  }) {
    return ScanState(
      status: status ?? this.status,
      userMessage: userMessage,
      lastSavedId: lastSavedId ?? this.lastSavedId,
    );
  }

  @override
  List<Object?> get props => [status, userMessage, lastSavedId];
}
