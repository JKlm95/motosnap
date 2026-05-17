import 'package:equatable/equatable.dart';

import '../../../../core/remote/sync_summary.dart';
import '../../../../core/sync/sync_user_error.dart';

export '../../../../core/sync/sync_user_error.dart';

enum ManualSyncStatus { idle, running, done, error }

class SyncState extends Equatable {
  const SyncState({
    this.status = ManualSyncStatus.idle,
    this.summary,
    this.userError,
  });

  final ManualSyncStatus status;
  final SyncSummary? summary;
  final SyncUserError? userError;

  @override
  List<Object?> get props => [status, summary, userError];
}
