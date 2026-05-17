/// Klasyfikacja błędu syncu dla mapowania na [AppStrings] w UI.
enum SyncUserError {
  cloudDisabled,
  generic,
  notSignedIn,
  permissionDenied,
  timedOut,
}
