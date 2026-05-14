import 'package:equatable/equatable.dart';

import '../../../../core/remote/sync_summary.dart';

enum ManualSyncStatus { idle, running, done, error }

/// Klasyfikacja błędu syncu dla mapowania na [AppStrings] w UI (bez surowego `e.toString()`).
enum SyncUserError { cloudDisabled, generic }

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
