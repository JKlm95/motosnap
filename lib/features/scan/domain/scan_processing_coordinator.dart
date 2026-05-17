import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/firebase/cloud_sync_availability.dart';
import 'pending_scan_sync.dart';
import 'post_sync_recognition.dart';
import 'scan_repository.dart';
import 'vehicle_analysis_exception.dart';
import 'vehicle_analysis_service.dart';

/// Kolejka sync + AI w obrębie działającej aplikacji (nie OS background service).
final class ScanProcessingCoordinator {
  ScanProcessingCoordinator({
    required ScanRepository repository,
    required CloudSyncAvailability cloudAvailability,
    PendingScanSync? pendingSync,
    VehicleAnalysisService? analysis,
  }) : _repository = repository,
       _cloud = cloudAvailability,
       _pendingSync = pendingSync,
       _analysis = analysis;

  final ScanRepository _repository;
  final CloudSyncAvailability _cloud;
  final PendingScanSync? _pendingSync;
  final VehicleAnalysisService? _analysis;

  final List<_ScanJob> _pending = [];
  final Set<String> _queuedOrRunning = {};
  bool _processing = false;

  bool get _canProcess =>
      _cloud.available && _pendingSync != null && _analysis != null;

  /// Dodaje skan do kolejki (bez duplikatów). Nie blokuje wywołującego.
  void enqueue(String scanId, String languageCode) {
    if (!_canProcess) {
      return;
    }
    if (_queuedOrRunning.contains(scanId)) {
      return;
    }
    _queuedOrRunning.add(scanId);
    _pending.add(_ScanJob(scanId, _normalizeLang(languageCode)));
    unawaited(_drainQueue());
  }

  /// Po wznowieniu aplikacji — tylko skany wymagające sync lub AI (limit chroni przed 1M odczytem).
  Future<void> enqueuePendingScans({
    String? languageCode,
    int limit = 64,
  }) async {
    if (!_canProcess) {
      return;
    }
    final lang = _normalizeLang(languageCode ?? 'en');
    final scans = await _repository.getRecentScans(limit);
    for (final scan in scans) {
      final needsSync =
          scan.pendingSync ||
          scan.remoteImageUrl == null ||
          scan.remoteImageUrl!.isEmpty;
      if (needsSync || PostSyncRecognitionPolicy.shouldRun(scan)) {
        enqueue(scan.id, lang);
      }
    }
  }

  /// Testy / await po ręcznym syncu — czeka aż kolejka opróżni się bez timerów.
  @visibleForTesting
  Future<void> waitUntilIdle() async {
    while (_processing || _pending.isNotEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _drainQueue() async {
    if (_processing) {
      return;
    }
    _processing = true;
    try {
      while (_pending.isNotEmpty) {
        final job = _pending.removeAt(0);
        try {
          await _processJob(job);
        } on Object catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'ScanProcessingCoordinator job=${job.scanId} failed: $e\n$st',
            );
          }
        } finally {
          _queuedOrRunning.remove(job.scanId);
        }
      }
    } finally {
      _processing = false;
      if (_pending.isNotEmpty) {
        unawaited(_drainQueue());
      }
    }
  }

  Future<void> _processJob(_ScanJob job) async {
    var scan = await _repository.getScan(job.scanId);
    if (scan == null) {
      return;
    }

    final needsSync =
        scan.pendingSync ||
        scan.remoteImageUrl == null ||
        scan.remoteImageUrl!.isEmpty;

    if (needsSync) {
      try {
        await _pendingSync!.syncPendingScan(_repository, job.scanId);
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'ScanProcessingCoordinator sync failed scanId=${job.scanId}: $e\n$st',
          );
        }
        return;
      }
      scan = await _repository.getScan(job.scanId);
      if (scan == null) {
        return;
      }
    }

    if (!PostSyncRecognitionPolicy.shouldRun(scan)) {
      return;
    }

    try {
      await _analysis!.analyzeScan(
        scanId: job.scanId,
        languageCode: job.languageCode,
      );
    } on VehicleAnalysisException {
      // Stan failed zapisuje implementacja analizy.
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'ScanProcessingCoordinator AI failed scanId=${job.scanId}: $e\n$st',
        );
      }
    }
  }

  static String _normalizeLang(String code) =>
      code.toLowerCase().startsWith('pl') ? 'pl' : 'en';
}

final class _ScanJob {
  const _ScanJob(this.scanId, this.languageCode);

  final String scanId;
  final String languageCode;
}
