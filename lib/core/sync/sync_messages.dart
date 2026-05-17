import '../locale/app_strings.dart';
import '../remote/sync_summary.dart';
import 'sync_user_error.dart';

/// Przyjazne komunikaty syncu (PL/EN) — wspólne dla Ustawień i Historii.
abstract final class SyncMessages {
  static String userError(AppStrings s, SyncUserError error) {
    return switch (error) {
      SyncUserError.cloudDisabled => s.errorSyncCloudUnavailable,
      SyncUserError.notSignedIn => s.errorSyncNotSignedIn,
      SyncUserError.permissionDenied => s.errorSyncPermissionDenied,
      SyncUserError.timedOut => s.errorSyncTimedOut,
      SyncUserError.generic => s.errorSyncGeneric,
    };
  }

  /// Krótki snack po syncu z Historii (tylko gdy była aktywność lub błędy częściowe).
  static String? historyRefreshSnack(AppStrings s, SyncSummary summary) {
    if (!summary.hasActivity) {
      return null;
    }
    if (summary.failed > 0 &&
        summary.totalPulled == 0 &&
        summary.uploaded == 0) {
      return s.errorSyncScanConnection;
    }
    return s.syncDoneSnackDetailed(
      uploaded: summary.uploaded,
      downloaded: summary.downloaded,
      updated: summary.updated,
      failed: summary.failed,
    );
  }
}
