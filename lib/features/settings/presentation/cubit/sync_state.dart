import 'package:equatable/equatable.dart';

import '../../../../core/remote/sync_summary.dart';

enum ManualSyncStatus { idle, running, done, error }

class SyncState extends Equatable {
  const SyncState({
    this.status = ManualSyncStatus.idle,
    this.summary,
    this.errorMessage,
  });

  final ManualSyncStatus status;
  final SyncSummary? summary;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
