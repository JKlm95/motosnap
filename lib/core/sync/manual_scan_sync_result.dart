import '../remote/sync_summary.dart';
import 'sync_user_error.dart';

/// Wynik wspólnego flow sync (Ustawienia + Historia).
sealed class ManualScanSyncResult {
  const ManualScanSyncResult();
}

final class ManualScanSyncSuccess extends ManualScanSyncResult {
  const ManualScanSyncSuccess(this.summary);

  final SyncSummary summary;
}

/// Brak Firebase / backendu sync — tylko lokalny odczyt.
final class ManualScanSyncCloudUnavailable extends ManualScanSyncResult {
  const ManualScanSyncCloudUnavailable();
}

final class ManualScanSyncFailure extends ManualScanSyncResult {
  const ManualScanSyncFailure(this.userError);

  final SyncUserError userError;
}
