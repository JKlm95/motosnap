import 'user_vehicle_correction.dart';

/// Wypchnięcie korekty użytkownika do Firestore (bez dotykania pól AI).
abstract interface class UserCorrectionRemoteSink {
  Future<void> pushUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  );
}

final class NoOpUserCorrectionRemoteSink implements UserCorrectionRemoteSink {
  const NoOpUserCorrectionRemoteSink();

  @override
  Future<void> pushUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {}
}
