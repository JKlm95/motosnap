import 'package:flutter/foundation.dart';

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
      final remote = doc.data;
      final local = localById[scanId];

      if (local == null) {
        final url = remote['remote_image_url'] as String?;
        if (url == null || url.trim().isEmpty) {
          if (kDebugMode) {
            debugPrint('[Sync] pull skip $scanId: brak remote_image_url');
          }
          skipped++;
          continue;
        }
        final created = VehicleScanFirestoreMapper.createFromRemoteDocument(
          scanId: scanId,
          remote: remote,
        );
        await localRepository.updateScan(created);
        localById[scanId] = created;
        downloaded++;
        downloadedScanIds.add(scanId);
        if (kDebugMode) {
          debugPrint('[Sync] pull downloaded $scanId');
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

      await localRepository.updateScan(merged);
      localById[scanId] = merged;
      updated++;
      updatedScanIds.add(scanId);
      if (kDebugMode) {
        debugPrint('[Sync] pull updated $scanId status=${merged.status.name}');
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
