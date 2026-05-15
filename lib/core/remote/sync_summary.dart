import 'package:equatable/equatable.dart';

/// Wynik ręcznej synchronizacji skanów oczekujących na upload.
final class SyncSummary extends Equatable {
  const SyncSummary({
    required this.uploaded,
    required this.failed,
    this.uploadedScanIds = const [],
  });

  final int uploaded;
  final int failed;

  /// Id skanów, dla których upload i merge do Hive zakończyły się powodzeniem w tej sesji.
  final List<String> uploadedScanIds;

  @override
  List<Object?> get props => [uploaded, failed, uploadedScanIds];
}
