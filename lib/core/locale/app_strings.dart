import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';

import '../../features/scan/domain/vehicle_analysis_exception.dart';
import '../../features/scan/domain/vehicle_scan_status.dart';
import '../../features/scan/domain/vehicle_type.dart';

/// Lekkie etykiety PL/EN na MVP — bez `gen_l10n`. Źródło języka: [Localizations.localeOf].
///
/// Docelowo można zastąpić `flutter gen_l10n` + ARB.
class AppStrings {
  AppStrings._(this._pl);

  final bool _pl;

  /// `languageCode` z `Localizations.localeOf` lub `'pl'` / `'en'`.
  factory AppStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return AppStrings._(code == 'pl');
  }

  factory AppStrings.fromLanguageCode(String? code) {
    final c = code?.toLowerCase() ?? 'en';
    return AppStrings._(c == 'pl');
  }

  // --- Vehicle type (UI) ---
  String vehicleType(VehicleType? type) {
    if (type == null) {
      return _pl ? '—' : '—';
    }
    if (_pl) {
      return switch (type) {
        VehicleType.car => 'Samochód',
        VehicleType.motorcycle => 'Motocykl',
        VehicleType.truck => 'Ciężarówka',
        VehicleType.bus => 'Autobus',
        VehicleType.van => 'Van / dostawczy',
        VehicleType.aircraft => 'Samolot',
        VehicleType.boat => 'Łódź / statek',
        VehicleType.train => 'Pociąg',
        VehicleType.agricultural => 'Pojazd rolniczy',
        VehicleType.construction => 'Maszyna budowlana',
        VehicleType.military => 'Pojazd wojskowy',
        VehicleType.emergency => 'Pojazd uprzywilejowany',
        VehicleType.bicycle => 'Rower',
        VehicleType.scooter => 'Hulajnoga / skuter',
        VehicleType.other => 'Inny pojazd',
        VehicleType.unknown => 'Nieznany',
      };
    }
    return switch (type) {
      VehicleType.car => 'Car',
      VehicleType.motorcycle => 'Motorcycle',
      VehicleType.truck => 'Truck',
      VehicleType.bus => 'Bus',
      VehicleType.van => 'Van',
      VehicleType.aircraft => 'Aircraft',
      VehicleType.boat => 'Boat / vessel',
      VehicleType.train => 'Train',
      VehicleType.agricultural => 'Agricultural vehicle',
      VehicleType.construction => 'Construction machine',
      VehicleType.military => 'Military vehicle',
      VehicleType.emergency => 'Emergency vehicle',
      VehicleType.bicycle => 'Bicycle',
      VehicleType.scooter => 'Scooter',
      VehicleType.other => 'Other vehicle',
      VehicleType.unknown => 'Unknown',
    };
  }

  // --- Scan status ---
  String scanStatus(VehicleScanStatus status) {
    if (_pl) {
      return switch (status) {
        VehicleScanStatus.draft => 'Szkic',
        VehicleScanStatus.waitingForRecognition => 'Oczekuje na rozpoznanie',
        VehicleScanStatus.recognized => 'Rozpoznano',
        VehicleScanStatus.failed => 'Rozpoznanie nieudane',
      };
    }
    return switch (status) {
      VehicleScanStatus.draft => 'Draft',
      VehicleScanStatus.waitingForRecognition => 'Waiting for recognition',
      VehicleScanStatus.recognized => 'Recognized',
      VehicleScanStatus.failed => 'Recognition failed',
    };
  }

  // --- Scan detail ---
  String get scanDetailsTitle => _pl ? 'Szczegóły skanu' : 'Scan details';
  String get vehicleInformationSection =>
      _pl ? 'Informacje o pojeździe' : 'Vehicle information';
  String get correctedByUserLabel =>
      _pl ? 'Poprawione przez użytkownika' : 'Corrected by user';
  String get originalAiResult =>
      _pl ? 'Oryginalny wynik AI' : 'Original AI result';
  String get analyzeWithAi => _pl ? 'Rozpoznaj przez AI' : 'Analyze with AI';
  String get syncBeforeAiHint => _pl
      ? 'Zsynchronizuj skan przed analizą AI (Ustawienia → Synchronizuj teraz).'
      : 'Sync the scan before AI analysis (Settings → Sync now).';
  String get correctResult => _pl ? 'Popraw wynik' : 'Correct result';
  String get recognitionFailedTitle =>
      _pl ? 'Rozpoznanie nie powiodło się.' : 'Recognition failed.';
  String get recognitionFailedNoDetails => _pl
      ? 'Szczegóły techniczne są ukryte. Możesz spróbować ponownie.'
      : 'Technical details are hidden. You can try again.';
  String get tryAgain => _pl ? 'Spróbuj ponownie' : 'Try again';
  String get closeMessage => _pl ? 'Zamknij komunikat' : 'Dismiss';
  String get scanNotFound => _pl ? 'Nie znaleziono skanu.' : 'Scan not found.';
  String get back => _pl ? 'Wróć' : 'Back';
  String get locationPrefix => _pl ? 'Lokalizacja' : 'Location';
  String get syncedToCloud =>
      _pl ? 'Zsynchronizowano z chmurą' : 'Synced to cloud';
  String get setPrivate => _pl ? 'Ustaw jako prywatny' : 'Set as private';
  String get setPublic => _pl ? 'Ustaw jako publiczny' : 'Set as public';
  String get deleteScan => _pl ? 'Usuń skan' : 'Delete scan';
  String get deleteScanConfirmTitle => _pl ? 'Usunąć skan?' : 'Delete scan?';
  String get deleteScanConfirmBody => _pl
      ? 'Zdjęcie i rekord zostaną usunięte z tego urządzenia.'
      : 'The photo and record will be removed from this device.';
  String get cancel => _pl ? 'Anuluj' : 'Cancel';
  String get delete => _pl ? 'Usuń' : 'Delete';

  // --- Vehicle info card rows ---
  String get fieldType => _pl ? 'Typ' : 'Type';
  String get fieldBrand => _pl ? 'Marka' : 'Brand';
  String get fieldModel => _pl ? 'Model' : 'Model';
  String get fieldGeneration => _pl ? 'Generacja' : 'Generation';
  String get fieldProductionYears =>
      _pl ? 'Lata produkcji' : 'Production years';
  String get fieldEnginesHint =>
      _pl ? 'Silniki (propozycje)' : 'Engines (suggestions)';
  String get fieldConfidence => _pl ? 'Pewność' : 'Confidence';
  String get emDash => '—';

  // --- Correction sheet ---
  String get correctionSheetTitle => _pl ? 'Popraw wynik' : 'Correct result';
  String get correctionVehicleTypeLabel => _pl ? 'Typ pojazdu' : 'Vehicle type';
  String get correctionSave => _pl ? 'Zapisz poprawkę' : 'Save correction';
  String get correctionEnginesLabel =>
      _pl ? 'Możliwe silniki' : 'Possible engines';
  String get correctionEnginesHelper => _pl
      ? 'Oddziel wartości przecinkiem (np. 2.0 TDI, 3.0 V6).'
      : 'Separate values with commas (e.g. 2.0 TDI, 3.0 V6).';
  String get correctionShortDescription =>
      _pl ? 'Krótki opis' : 'Short description';
  String get correctionShortDescriptionHelper => _pl
      ? 'Opcjonalnie: własna notatka o pojeździe.'
      : 'Optional: your own note about the vehicle.';

  // --- Scan screen ---
  String get scanTabTitle => _pl ? 'Skan' : 'Scan';
  String get scanIntro => _pl
      ? 'Zrób zdjęcie z aparatu. Lokalizacja GPS jest wymagana — bez niej skan nie zostanie zapisany.'
      : 'Take a photo with the camera. GPS location is required — the scan cannot be saved without it.';
  String get scanButton => _pl ? 'Skanuj' : 'Scan';
  String get scanSavedLocally => _pl ? 'Zapisano lokalnie' : 'Saved locally';
  String scanSavedStatusLine(String statusLabel) =>
      _pl ? 'Status: $statusLabel' : 'Status: $statusLabel';
  String get scanAiPendingHint => _pl
      ? 'Rozpoznanie AI nie zostało jeszcze uruchomione — to tylko lokalny rekord.'
      : 'AI recognition has not run yet — this is a local record only.';
  String get nextScan => _pl ? 'Kolejny skan' : 'Next scan';
  String get ok => _pl ? 'OK' : 'OK';
  String get photoCancelled => _pl ? 'Anulowano zdjęcie.' : 'Photo cancelled.';

  // --- History ---
  String get historyTitle => _pl ? 'Historia' : 'History';
  String get historyRefreshTooltip => _pl ? 'Odśwież' : 'Refresh';
  String get historyEmpty => _pl
      ? 'Brak zapisanych skanów.\nZrób pierwszy skan w zakładce „Skan”.'
      : 'No saved scans yet.\nCapture your first scan in the Scan tab.';
  String get historyRecognitionPending =>
      _pl ? 'Oczekuje na rozpoznanie' : 'Recognition pending';
  String historyVehicleSummary(String? line) {
    if (line == null || line.isEmpty) {
      return historyRecognitionPending;
    }
    return line;
  }

  String get historyPublicBadge => _pl ? 'Publiczny' : 'Public';

  String get historyFilterAll => _pl ? 'Wszystkie' : 'All';
  String get historyFilterRecognized => _pl ? 'Rozpoznane' : 'Recognized';
  String get historyFilterWaiting => _pl ? 'Oczekujące' : 'Waiting';
  String get historyFilterCorrected => _pl ? 'Poprawione' : 'Corrected';
  String get historyFilterPublic => _pl ? 'Publiczne' : 'Public';

  String get historySortNewest => _pl ? 'Najnowsze' : 'Newest';
  String get historySortOldest => _pl ? 'Najstarsze' : 'Oldest';
  String get historySortConfidence => _pl ? 'Pewność' : 'Confidence';
  String get historySortBrand => _pl ? 'Marka' : 'Brand';
  String get historySortMenuTitle => _pl ? 'Sortowanie' : 'Sort by';

  String get historyLoadError =>
      _pl ? 'Nie udało się wczytać historii.' : 'Could not load history.';
  String get historyRefreshError =>
      _pl ? 'Nie udało się odświeżyć listy.' : 'Could not refresh the list.';
  String get historyFilterEmpty => _pl
      ? 'Brak wyników dla wybranego filtra.'
      : 'No scans match this filter.';
  String get historyGoToScanCta => _pl ? 'Przejdź do skanu' : 'Go to Scan';

  String get historyOfflineHint => _pl
      ? 'Bez pełnej chmury skany zostają tylko na tym urządzeniu.'
      : 'Without full cloud setup, scans stay on this device.';

  String get historySwipeDelete => _pl ? 'Usuń' : 'Delete';
  String get historySwipePublic => _pl ? 'Publiczny' : 'Make public';
  String get historySwipePrivate => _pl ? 'Prywatny' : 'Make private';
  String get historySwipeRetryAi => _pl ? 'Ponów AI' : 'Retry AI';

  String get confidenceHigh => _pl ? 'Wysoka pewność' : 'High confidence';
  String get confidenceMedium => _pl ? 'Średnia pewność' : 'Medium confidence';
  String get confidenceLow => _pl ? 'Niska pewność' : 'Low confidence';

  // --- Settings / sync ---
  String get settingsTitle => _pl ? 'Ustawienia' : 'Settings';
  String get settingsAccount => _pl ? 'Konto' : 'Account';
  String get settingsEmail => _pl ? 'E-mail' : 'Email';
  String get settingsSignOut => _pl ? 'Wyloguj' : 'Sign out';
  String get settingsSyncSection => _pl ? 'Synchronizacja' : 'Sync';
  String get settingsSyncReadyBody => _pl
      ? 'Chmura jest dostępna. Skany oznaczone jako oczekujące na wysłanie możesz zsynchronizować jednym przyciskiem — dane zdjęcia i metadane trafią na Twoje konto.'
      : 'Cloud is available. Scans marked as pending can be uploaded with one tap — image and metadata go to your account.';
  String get settingsSyncOfflineBody => _pl
      ? 'Aplikacja działa bez pełnej konfiguracji Firebase (np. brak `flutterfire configure`). Skany pozostają tylko na tym urządzeniu.'
      : 'The app is running without full Firebase setup (e.g. missing `flutterfire configure`). Scans stay on this device only.';
  String get settingsSyncNow => _pl ? 'Synchronizuj teraz' : 'Sync now';
  String syncDoneSnack(int ok, int failed) => _pl
      ? 'Synchronizacja zakończona: wysłano $ok, błędy $failed.'
      : 'Sync finished: uploaded $ok, failed $failed.';
  String get settingsLanguageSection => _pl ? 'Język' : 'Language';
  String get settingsLanguageTitle => _pl ? 'Język aplikacji' : 'App language';
  String get settingsLanguageSubtitle => _pl
      ? 'Używany jest język systemu (PL/EN). Pełny wybór wkrótce.'
      : 'Follows system language (PL/EN). Full picker coming soon.';
  String get settingsAppearance => _pl ? 'Wygląd' : 'Appearance';
  String get settingsTheme => _pl ? 'Motyw' : 'Theme';
  String get themeSystem => _pl ? 'System' : 'System';
  String get themeLight => _pl ? 'Jasny' : 'Light';
  String get themeDark => _pl ? 'Ciemny' : 'Dark';

  // --- Scan flow errors (permissions / GPS) ---
  String get errorLocationPermission => _pl
      ? 'Brak zgody na lokalizację. Włącz uprawnienie w ustawieniach systemu — GPS jest wymagany.'
      : 'Location permission denied. Enable it in system settings — GPS is required.';
  String get errorCameraPermission => _pl
      ? 'Brak zgody na aparat. Włącz uprawnienie w ustawieniach systemu.'
      : 'Camera permission denied. Enable it in system settings.';
  String get errorLocationServiceDisabled => _pl
      ? 'Usługi lokalizacji są wyłączone. Włącz GPS w ustawieniach systemu.'
      : 'Location services are disabled. Turn on location in system settings.';
  String get errorScanSaveGeneric => _pl
      ? 'Nie udało się zapisać skanu. Spróbuj ponownie.'
      : 'Could not save the scan. Please try again.';

  // --- Sync errors (user-facing codes) ---
  String get errorSyncCloudUnavailable => _pl
      ? 'Synchronizacja z chmurą jest niedostępna (brak konfiguracji Firebase).'
      : 'Cloud sync is not available (Firebase not configured).';
  String get errorSyncGeneric => _pl
      ? 'Synchronizacja nie powiodła się. Sprawdź połączenie z siecią i spróbuj ponownie.'
      : 'Sync failed. Check your network connection and try again.';
  String get errorOperationFailed => _pl
      ? 'Operacja nie powiodła się. Spróbuj ponownie.'
      : 'Something went wrong. Please try again.';
  String get errorDeleteFailed => _pl
      ? 'Nie udało się usunąć skanu. Spróbuj ponownie.'
      : 'Could not delete the scan. Please try again.';
  String get errorSaveCorrectionFailed => _pl
      ? 'Nie udało się zapisać poprawki. Spróbuj ponownie.'
      : 'Could not save the correction. Please try again.';

  // --- AI analysis (user-facing; never raw provider text) ---
  String get errorAiGeneric => _pl
      ? 'Rozpoznanie AI nie powiodło się. Spróbuj ponownie za chwilę.'
      : 'AI recognition failed. Please try again in a moment.';
  String get errorAiScanNotFound =>
      _pl ? 'Nie znaleziono skanu.' : 'Scan not found.';
  String get errorAiInvalidServerResponse => _pl
      ? 'Serwer zwrócił nieoczekiwany wynik. Spróbuj ponownie.'
      : 'The server returned an unexpected response. Please try again.';
  String get errorAiCloudCall => _pl
      ? 'Połączenie z usługą rozpoznania nie powiodło się. Spróbuj ponownie.'
      : 'Could not reach the recognition service. Please try again.';

  /// Mapuje wyjątek z analizy AI na komunikat bezpieczny dla UI.
  String aiAnalysisUserMessage(Object? error) {
    if (error == null) {
      return errorAiGeneric;
    }
    if (error is VehicleAnalysisException) {
      final m = error.message;
      if (m.contains('Nie znaleziono skanu') || m.contains('Scan not found')) {
        return errorAiScanNotFound;
      }
      if (m.contains('Nieprawidłowa odpowiedź serwera') ||
          m.contains('Invalid server response')) {
        return errorAiInvalidServerResponse;
      }
      if (m.contains('Połączenie z usługą') || m.contains('Could not reach')) {
        return errorAiCloudCall;
      }
      return errorAiGeneric;
    }
    if (error is FirebaseFunctionsException) {
      return errorAiCloudCall;
    }
    final text = error.toString();
    if (text.contains('LocationServiceDisabled')) {
      return errorLocationServiceDisabled;
    }
    if (text.contains('LocationPermissionDenied')) {
      return errorLocationPermission;
    }
    return errorAiGeneric;
  }
}
