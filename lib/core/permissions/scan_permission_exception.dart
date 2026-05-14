import 'scan_permission_denied_kind.dart';

/// Odmowa uprawnień potrzebnych do zapisu skanu.
final class ScanPermissionException implements Exception {
  const ScanPermissionException(this.denied);

  final ScanPermissionDeniedKind denied;

  @override
  String toString() => 'ScanPermissionException($denied)';
}
