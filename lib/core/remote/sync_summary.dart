import 'package:equatable/equatable.dart';

/// Wynik ręcznej synchronizacji: upload lokalnych pending + pull z Firestore.
final class SyncSummary extends Equatable {
  const SyncSummary({
    required this.uploaded,
    required this.failed,
    this.uploadedScanIds = const [],
    this.downloaded = 0,
    this.updated = 0,
    this.downloadedScanIds = const [],
    this.updatedScanIds = const [],
  });

  final int uploaded;
  final int failed;

  /// Id skanów, dla których upload i merge do Hive zakończyły się powodzeniem w tej sesji.
  final List<String> uploadedScanIds;

  /// Nowe rekordy utworzone lokalnie z dokumentów Firestore (brak wcześniej w Hive).
  final int downloaded;

  /// Istniejące lokalnie rekordy zaktualizowane danymi z chmury.
  final int updated;

  final List<String> downloadedScanIds;
  final List<String> updatedScanIds;

  int get totalPulled => downloaded + updated;

  bool get hasActivity => uploaded > 0 || totalPulled > 0 || failed > 0;

  @override
  List<Object?> get props => [
    uploaded,
    failed,
    uploadedScanIds,
    downloaded,
    updated,
    downloadedScanIds,
    updatedScanIds,
  ];
}
