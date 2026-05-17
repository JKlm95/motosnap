import 'package:flutter/foundation.dart';

import '../firebase/cloud_sync_availability.dart';
import '../remote/sync_summary.dart';
import '../../features/scan/domain/pending_scan_sync.dart';
import '../../features/scan/domain/scan_processing_coordinator.dart';
import '../../features/scan/domain/scan_repository.dart';
import 'manual_scan_sync_result.dart';
import 'sync_error_mapper.dart';

/// Upload pending + pull Firestore + opcjonalna kolejka AI — jedna ścieżka dla UI.
final class ManualScanSyncCoordinator {
  ManualScanSyncCoordinator({
    required ScanRepository repository,
    required CloudSyncAvailability cloudAvailability,
    PendingScanSync? pendingSync,
    ScanProcessingCoordinator? processingCoordinator,
  }) : _repository = repository,
       _cloud = cloudAvailability,
       _pendingSync = pendingSync,
       _processing = processingCoordinator;

  final ScanRepository _repository;
  final CloudSyncAvailability _cloud;
  final PendingScanSync? _pendingSync;
  final ScanProcessingCoordinator? _processing;

  Future<ManualScanSyncResult> syncNow({required String languageCode}) async {
    final pending = _pendingSync;
    if (!_cloud.available || pending == null) {
      return const ManualScanSyncCloudUnavailable();
    }

    try {
      final summary = await pending.syncAllPending(_repository);
      await _enqueuePostSync(summary, languageCode);
      if (kDebugMode) {
        debugPrint(
          '[ManualSync] ok uploaded=${summary.uploaded} '
          'downloaded=${summary.downloaded} updated=${summary.updated} '
          'failed=${summary.failed}',
        );
      }
      return ManualScanSyncSuccess(summary);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ManualSync] failed: $e\n$st');
      }
      return ManualScanSyncFailure(SyncErrorMapper.userErrorFor(e));
    }
  }

  Future<void> _enqueuePostSync(
    SyncSummary summary,
    String languageCode,
  ) async {
    final queue = _processing;
    if (queue == null) {
      return;
    }
    try {
      final lang = languageCode.toLowerCase();
      for (final id in summary.uploadedScanIds) {
        queue.enqueue(id, lang);
      }
      await queue.enqueuePendingScans(languageCode: lang);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ManualSync] enqueue after sync failed (ignored): $e\n$st');
      }
    }
  }
}
