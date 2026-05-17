import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_restore_debug.dart';
import '../domain/scan_repository.dart';
import '../domain/vehicle_scan.dart';
import 'vehicle_scan_firestore_mapper.dart';

/// Pull dokumentów Firestore → Hive (czysta logika do testów).
abstract final class CloudScanRemotePull {
  static Future<
    ({
      int downloaded,
      int updated,
      List<String> downloadedScanIds,
      List<String> updatedScanIds,
      int skipped,
    })
  >
  applyRemoteDocuments({
    required ScanRepository localRepository,
    required Map<String, VehicleScan> localById,
    required Iterable<({String id, Map<String, dynamic> data})> remoteDocs,
  }) async {
    var downloaded = 0;
    var updated = 0;
    var skipped = 0;
    final downloadedScanIds = <String>[];
    final updatedScanIds = <String>[];

    for (final doc in remoteDocs) {
      final scanId = doc.id;
      try {
        final remote = doc.data;
        final local = localById[scanId];

        if (local == null) {
          final url = remote['remote_image_url'] as String?;
          final VehicleScan created;
          try {
            created = VehicleScanFirestoreMapper.createFromRemoteDocument(
              scanId: scanId,
              remote: remote,
            );
          } on Object catch (e, st) {
            SyncRestoreDebug.logPhaseFailure(
              phase: SyncRestoreFailurePhase.remoteMapping,
              scanId: scanId,
              error: e,
              stackTrace: st,
            );
            rethrow;
          }
          try {
            await localRepository.updateScan(created);
          } on Object catch (e, st) {
            SyncRestoreDebug.logPhaseFailure(
              phase: SyncRestoreFailurePhase.hivePersist,
              scanId: scanId,
              error: e,
              stackTrace: st,
            );
            rethrow;
          }
          localById[scanId] = created;
          downloaded++;
          downloadedScanIds.add(scanId);
          if (kDebugMode) {
            final hasUrl = url != null && url.trim().isNotEmpty;
            debugPrint(
              hasUrl
                  ? '[Sync] pull downloaded $scanId'
                  : '[Sync] pull downloaded $scanId (metadata-only, brak remote_image_url)',
            );
          }
          continue;
        }

        final merged = VehicleScanFirestoreMapper.mergePull(
          local: local,
          remote: remote,
        );
        if (!VehicleScanFirestoreMapper.hasSyncRelevantChanges(local, merged)) {
          skipped++;
          if (kDebugMode) {
            debugPrint('[Sync] pull skip $scanId: brak zmian');
          }
          continue;
        }

        try {
          await localRepository.updateScan(merged);
        } on Object catch (e, st) {
          SyncRestoreDebug.logPhaseFailure(
            phase: SyncRestoreFailurePhase.hivePersist,
            scanId: scanId,
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
        localById[scanId] = merged;
        updated++;
        updatedScanIds.add(scanId);
        if (kDebugMode) {
          debugPrint(
            '[Sync] pull updated $scanId status=${merged.status.name}',
          );
        }
      } on Object catch (e, st) {
        skipped++;
        SyncRestoreDebug.logPhaseFailure(
          phase: SyncRestoreFailurePhase.remoteMapping,
          scanId: scanId,
          error: e,
          stackTrace: st,
        );
      }
    }

    return (
      downloaded: downloaded,
      updated: updated,
      downloadedScanIds: downloadedScanIds,
      updatedScanIds: updatedScanIds,
      skipped: skipped,
    );
  }
}
