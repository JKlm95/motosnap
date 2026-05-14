/// Wynik ręcznej synchronizacji skanów oczekujących na upload.
final class SyncSummary {
  const SyncSummary({required this.uploaded, required this.failed});

  final int uploaded;
  final int failed;
}
