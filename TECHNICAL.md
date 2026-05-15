# MotoSnap — dokumentacja techniczna

## Cel dokumentu

Opisuje architekturę, przepływ danych, modele, repozytoria, routing oraz znane kompromisy i dług techniczny. Aktualizować przy każdej istotnej zmianie implementacji.

---

## Architektura

- **`lib/app/`** — `AppBootstrap` (Hive, Firebase `try/catch`, wybór repozytoriów auth/sync), `MotosnapApp`, `go_router` z redirectem auth + `RouterRefreshBridge`, motyw.
- **`lib/core/`** — usługi infrastrukturalne: GPS, geokodowanie, aparat, zapis plików, uprawnienia, Hive, **etykiety PL/EN MVP** ([`AppStrings`](lib/core/locale/app_strings.dart)), abstrakcja kolejki chmury (`CloudScanSyncService`), wynik ręcznego sync (`SyncSummary`), init Firebase (`FirebaseInitializer`, `CloudSyncAvailability`).
- **`lib/features/`** — `splash` (hydracja sesji), `auth` (Firebase / offline), `scan` (domena, repozytorium, sync do Firestore+Storage, UI), `history`, `settings`.

### UI premium (glass, nawigacja, haptyka)

- **`lib/core/ui/app_motion.dart`** — wspólne `Duration` i krzywe (`AppMotion`) dla animacji lekkich na słabszych urządzeniach; `AppMotion.imageFade` przy pierwszym wyświetleniu zdjęcia (sieć / dekodowanie).
- **`lib/core/ui/app_shape.dart`** — wspólne promienie (`card`, `headerImage`, `sheetTop`, `thumbnail`) i poziomy blur (`blurNavBar`, `blurNavFab`, `blurDetailSheet`, `glassPanel`) dla spójności szkła, kart i ekranu szczegółów.
- **`lib/core/haptics/app_haptics.dart`** — `AppHaptics` (wrapper na `HapticFeedback` w `try/catch`).
- **`lib/core/ui/glass/`** — `GlassSurface` (`BackdropFilter` + półprzezroczyste tło; `blurSigma <= 0` pomija blur), `GlassCard`, `GlassBottomBar` (pill), opcjonalnie `GlassStatusBadge` (domyślnie bez blur), `GlassIconButton`.
- **`lib/app/shell/`** — `MainShellLayout` / `kShellGlassNavContentPadding` (dolny margines treści pod pływającą nawigacją), `GlassShellBottomNav` (trzy gałęzie shell: skan środek, historia, ustawienia; etykiety z `AppStrings`).
- **`lib/features/scan/presentation/widgets/scan_status_badge.dart`** — plakietki statusu skanu i „poprawione przez użytkownika” **bez** blur (bezpieczne w przewijanych listach).
- **Szczegóły skanu (photo-first):** [`ScanImageDisplay`](lib/features/scan/presentation/widgets/scan_image_display.dart) — kolejność **plik lokalny** → **`Image.network(remoteImageUrl)`** (stan ładowania / błąd) → **placeholder**; ten sam **Hero** w historii i nagłówku szczegółów: tag `motosnap-scan-photo-{id}` przez `ScanImageDisplay.heroTagFor(id)`. [`ScanDetailScreen`](lib/features/scan/presentation/detail/scan_detail_screen.dart): nagłówek zdjęcia ~42–48% wysokości ekranu, dolny panel [`DraggableScrollableSheet`](https://api.flutter.dev/flutter/widgets/DraggableScrollableSheet-class.html) z wierzchem w [`GlassSurface`](lib/core/ui/glass/glass_surface.dart) (blur tylko na obrysie panelu, treść w zwykłym `ListView`); uchwyt przeciągania; treść sekcji w [`ScanDetailSheetContent`](lib/features/scan/presentation/detail/scan_detail_sheet_content.dart); siatka pól pojazdu w [`ScanDetailVehicleInfoCard`](lib/features/scan/presentation/detail/scan_detail_vehicle_info_card.dart); po udanym AI z „oczekuje” — kaskadowy [`ScanDetailVehicleRevealCard`](lib/features/scan/presentation/detail/scan_detail_vehicle_reveal_card.dart) sterowany licznikiem `vehicleRevealToken` w [`ScanDetailCubit`](lib/features/scan/presentation/detail/scan_detail_cubit.dart) (otwarcie istniejącego rekordu = statyczna karta bez animacji).
- **Historia (MVP+):** [`HistoryCubit`](lib/features/history/presentation/cubit/history_cubit.dart) trzyma listę z `watchScans()` oraz **lokalny** stan `HistoryFilter` / `HistorySort`; widoczna lista to `visibleScans` (`applyHistoryFilterSort` w [`history_list_query.dart`](lib/features/history/domain/history_list_query.dart)) — bez dodatkowych zapytań do Hive. UI: [`HistoryFiltersBar`](lib/features/history/presentation/widgets/history_filters_bar.dart) (chips + menu sortowania), [`HistorySlidableScanTile`](lib/features/history/presentation/widgets/history_slidable_scan_tile.dart) (`flutter_slidable`, `groupTag: 'history'`, `closeOnScroll: true`), lekkie wejście listy [`HistoryTileEnterAnimation`](lib/features/history/presentation/widgets/history_slidable_scan_tile.dart) tylko gdy rośnie `listAnimationEpoch` (pierwsze dane, ręczne odświeżenie — **nie** przy każdej zmianie filtra/sortu, żeby uniknąć męczącego powtarzania animacji). Skeleton: [`HistoryListSkeleton`](lib/features/history/presentation/widgets/history_list_skeleton.dart) + [`MotoShimmer`](lib/core/ui/shimmer/moto_shimmer.dart). Pull-to-refresh: stylizowany `RefreshIndicator` + cienki `LinearProgressIndicator` przy odświeżeniu, gdy lista już nie jest pusta. Ponów AI z wiersza: ten sam [`VehicleAnalysisService`](lib/features/scan/domain/vehicle_analysis_service.dart) / callable co [`ScanDetailCubit.runAiAnalysis`](lib/features/scan/presentation/detail/scan_detail_cubit.dart) ([`HistoryCubit.retryAiAnalysis`](lib/features/history/presentation/cubit/history_cubit.dart)); stan `retryingScanId` pokazuje lekki wskaźnik tylko na tym wierszu — **bez** globalnego overlaya blokującego całą listę; przy błędzie snackbar z `AppStrings`.
- **Historia — kontrakt produktowy (domyślne założenia):** filtr „Poprawione” (`HistoryFilter.corrected`) = `scan.userCorrection != null` — patrz [`historyScanMatchesFilter`](lib/features/history/domain/history_list_query.dart). Usuwanie z listy = ten sam dialog (`deleteScanConfirmTitle` / `Body`) i ta sama ścieżka `ScanRepository.deleteScan` co na ekranie szczegółów ([`HistoryCubit.deleteScan`](lib/features/history/presentation/cubit/history_cubit.dart)), bez konieczności otwierania szczegółów. Filtr i sort wyłącznie w pamięci sesji `HistoryCubit` — **brak** persystencji w Hive na tym etapie.
- **Polityka ryzyka (historia / gesty / architektura):** przy nierozwiązywalnym konflikcie gestów (np. swipe vs Hero albo nawigacja do szczegółów) nie wdrażamy kruchego UX na sklejkach — zatrzymujemy się i opisujemy problem. Jeśli „pełne” rozwiązanie wymagałoby dużej przepinki architektury, dostarczamy uproszczone MVP i kompromis zapisujemy w tym dokumencie.

Zasady: blur tylko tam, gdzie ma sens (nawigacja, pojedyncze karty), nie na każdym wierszu listy. Szczegóły haptyki i wydajności `BackdropFilter`: patrz sekcja poniżej (Kompromisy).

**Kompromis MVP (szczegóły):** brak osobnego „silnika” mapy z niezależnym skalowaniem mapy i listy (jak Apple Maps); jest **jeden** nagłówek zdjęcia + **jeden** `DraggableScrollableSheet` z `snap` i kilkoma `snapSizes` — mniej ryzyka regresji layoutu niż w pełni customowy layout sync mapy/listy.

Logika biznesowa skanowania i persystencji jest w **repozytorium** i serwisach core; widgety/Cubit ograniczają się do stanu UI i wywołań repozytorium.

---

## Teksty UI i język (MVP)

- [`AppStrings`](lib/core/locale/app_strings.dart): `AppStrings.of(context)` bazuje na `Localizations.localeOf` (język systemu / `supportedLocales`); `AppStrings.fromLanguageCode` używane w Cubitach bez `BuildContext` (np. skan, szczegóły z `uiLanguageCode` z routera).
- Zakres: typ pojazdu (`VehicleType`), status skanu, etykiety sekcji (skan, historia, szczegóły, korekta, ustawienia/sync), komunikaty błędów użytkownika (bez surowych treści z Firebase/Gemini w snackbarach / banerach).
- [`MotosnapApp`](lib/app/motosnap_app.dart): `flutter_localizations` (`GlobalMaterialLocalizations` itd.) + `supportedLocales: en`, `pl`.
- Sync: [`SyncState.userError`](lib/features/settings/presentation/cubit/sync_state.dart) (`SyncUserError`) zamiast przekazywania `e.toString()` do UI; szczegóły w `debugPrint` w [`SyncCubit`](lib/features/settings/presentation/cubit/sync_cubit.dart).
- Uprawnienia: [`ScanPermissionException`](lib/core/permissions/scan_permission_exception.dart) z [`ScanPermissionDeniedKind`](lib/core/permissions/scan_permission_denied_kind.dart) — mapowanie na tekst w [`ScanCubit`](lib/features/scan/presentation/cubit/scan_cubit.dart) przez `AppStrings`.
- Formularz korekty: [`VehicleCorrectionPrefill`](lib/features/scan/presentation/detail/vehicle_correction_prefill.dart) — prefill z `effectiveVehicleInfo` / korekty.
- **Migracja docelowa:** `flutter gen_l10n` + pliki ARB, trwały wybór języka w ustawieniach (obecnie placeholder + podpis że UI podąża za systemem).

---

## Model `VehicleScan` (DTO, ręczny JSON)

- **Wersjonowanie:** `toJson()` zapisuje `schema_version: 4`. `fromJson()` rozpoznaje rekordy legacy (pola `image_path`, `captured_at`, `latitude`/`longitude` na root) i mapuje je na nowy kształt ze statusem `waitingForRecognition`.
- **Status:** `VehicleScanStatus` — `draft`, `waitingForRecognition`, `recognized`, `failed` (UI nie symuluje rozpoznania — po zapisie lokalnym jest `waitingForRecognition`).
- **Lokalizacja:** `ScanLocation` — `latitude`, `longitude`, opcjonalnie `city`, `country`, `displayName`, `isApproximatePublicLocation` (domyślnie `true`).
- **Wynik AI (niezmieniany korektą UI):** `vehicleInfo` (`vehicle_info` w Firestore) — wyłącznie z Cloud Function / backendu; przy parsowaniu z odpowiedzi callable używane jest `VehicleInfo.fromAiResponseJson`, żeby wyczyścić ewentualne `was_user_corrected` z JSON.
- **Korekta użytkownika:** `userCorrection` (`user_correction` w Firestore) — osobny obiekt [`UserVehicleCorrection`](lib/features/scan/domain/user_vehicle_correction.dart) (`vehicle_type`, pola tekstowe, `possible_engines`, `short_description`, `corrected_at`, `source: "user"`). Nie nadpisuje `vehicleInfo`.
- **Prezentacja:** `effectiveVehicleInfo` — jeśli jest `userCorrection`, buduje [`VehicleInfo`](lib/features/scan/domain/vehicle_info.dart) z `wasUserCorrected: true` i uzupełnia braki z `vehicleInfo` (baseline AI); w przeciwnym razie zwraca `vehicleInfo`.
- **Czas rozpoznania AI:** `recognizedAt` (ISO w Hive; w Firestore `recognized_at` jako `Timestamp`) — ustawiany z callable (`recognized_at` w JSON odpowiedzi) oraz przy scaleniu po syncu.
- **Pola dodatkowe:** `remoteImageUrl`, `recognitionError`, `isPublic`, `pendingSync`, `syncLastError` (ostatni błąd uploadu do chmury).

Enum **`VehicleType`** jest w modelu informacji o pojeździe; dopuszczalne są `unknown` / `other`.

---

## Repozytorium skanów (`ScanRepository` / `ScanRepositoryImpl`)

Metody:

| Metoda | Zachowanie |
|--------|--------------|
| `watchScans()` | `async*` — pierwsza emisja pełnej listy, potem po każdej zmianie (wewnętrzny broadcast `void`). |
| `getRecentScans(limit)` | Sort malejąco po `createdAt`, obcięcie do `limit`. |
| `getScan(id)` | Odczyt z Hive. |
| `createScan(capturedPhoto:)` | Kopia pliku do katalogu aplikacji → GPS (wymagany) → enrich lokalizacji → zapis `VehicleScan` (`pendingSync: true`) → `CloudScanSyncService.enqueueForUpload` (w MVP **puste** w `FirebaseCloudSyncService` — brak auto-uploadu) → harmonogram analizy (no-op) → emisja zmiany. Przy błędzie po zapisie pliku — usunięcie skopiowego pliku. |
| `updateScan` | `upsert` z aktualizacją `updatedAt`. |
| `deleteScan` | Usunięcie pliku lokalnego (best effort) + rekordu w Hive. |
| `markAsPublic` / `markAsPrivate` | Odczyt, `copyWith(isPublic: ...)`, `updateScan`. |
| `updateUserCorrection` | Zapis `userCorrection` w Hive; jeśli skan jest zsynchronizowany (`!pendingSync` + `remoteImageUrl`), wypchnięcie tylko `user_correction` do Firestore przez [`UserCorrectionRemoteSink`](lib/features/scan/domain/user_correction_remote_sink.dart) (implementacja: [`FirebaseCloudSyncService`](lib/features/scan/data/firebase_cloud_sync_service.dart)). |

---

## Hive

- Box: `vehicle_scans_json` — wartość: `jsonEncode(VehicleScan.toJson())`, klucz: `id`.
- Ustawienia motywu: osobny box (`SettingsLocalDataSource`).

---

## Routing (`go_router`)

- **Redirect auth:** `AuthRouteResolution.redirect` — czysta funkcja (testy w `test/auth_route_resolution_test.dart`). Niezalogowany użytkownik na trasach shell (`/scan`, `/history`, `/settings`) lub `/vehicle-scan/...` jest kierowany na `/auth/login`. Zalogowany na `/auth/*` — na `/scan`. Splash (`/splash`) jest wyłączony z pętli: redirect zwraca `null`, a `SplashCubit` po krótkim opóźnieniu i pierwszym zdarzeniu `watchSession()` wykonuje `context.go` na login lub shell.
- **Odświeżanie:** `RouterRefreshBridge` nasłuchuje `AuthRepository.watchSession()` i podpięty jest do `GoRouter.refreshListenable` — po loginie/logoucie router przelicza redirect bez ręcznego „haka” w każdym ekranie.
- Shell: `/scan`, `/history`, `/settings` (`StatefulShellRoute.indexedStack`) — dolny pasek: [`GlassShellBottomNav`](lib/app/shell/glass_shell_bottom_nav.dart) + [`MainShellLayout`](lib/app/shell/main_shell_layout.dart) (dolny padding treści).
- Poza shellem: `/splash`, `/auth/login`, `/auth/register`, `/auth/forgot-password`, `/vehicle-scan/:scanId` — odpowiednie `BlocProvider` w builderach tras; **szczegół skanu** używa `CustomTransitionPage` (fade + lekki slide, czasy z `AppMotion`) zamiast domyślnego `MaterialPage`, żeby zachować płynniejsze wejście bez psucia Hero.
- `AppRoutes.vehicleScan(id)` buduje ścieżkę.

---

## Firebase (MVP)

### Inicjalizacja

- `FirebaseInitializer.initialize()` wywoływane tylko przy starcie produkcyjnym (`hivePath == null` w `AppBootstrap`). W testach jednostkowych z podanym `hivePath` Firebase **nie** jest startowane.
- **Idempotentność:** jeśli `Firebase.apps` nie jest puste, zwracany jest od razu `FirebaseInitStatus.ready` (istniejąca domyślna aplikacja — bez drugiego `initializeApp`). W przeciwnym razie wywoływane jest `Firebase.initializeApp(options: …)`. Błąd `FirebaseException` z kodem `duplicate-app` (np. wyścig z auto-init natywnym po `google-services`) jest traktowany jak sukces — `ready`, a nie tryb offline.
- Konfiguracja przez FlutterFire: `lib/firebase_options.dart` (placeholder + komentarz), natywne `google-services.json` / `GoogleService-Info.plist`. Brak sekretów serwerowych w repo — same identyfikatory klienckie zgodne z konwencją FlutterFire.
- Przy **rzeczywistym** błędzie `initializeApp` (inny niż `duplicate-app`): `FirebaseInitStatus.failed` → `OfflineAuthRepository` + brak `PendingScanSync` (przycisk „Synchronizuj teraz” nieaktywny).

### Auth

- Interfejs: `AuthRepository` (`watchSession`, `readSessionSync`, e-mail/hasło, reset hasła, `signOut`, `currentUserEmail`).
- Implementacje: `FirebaseAuthRepository` (Firestore: dokument `users/{uid}` przy rejestracji — `email`, `created_at`) oraz `OfflineAuthRepository` (tryb degradacji — operacje auth z komunikatem o konfiguracji).
- UI: `LoginCubit` / `RegisterCubit` / `ForgotPasswordCubit` + ekrany pod `/auth/*`.

### Firestore (skany)

- Ścieżka: `users/{uid}/scans/{scanId}` (merge `set` przy uploadzie klienta).
- Pola m.in.: `status`, `is_public`, `remote_image_url`, `vehicle_info`, `user_correction`, `recognition_error`, `recognized_at`, `schema_version`, znaczniki czasu, `exact_location`, `public_location_approximation`.
- **Prywatność GPS:** `exact_location` — mapa z dokładnymi `latitude` / `longitude` (tylko w dokumencie prywatnym użytkownika). `public_location_approximation` — wyłącznie `city`, `country`, `display_name` (bez dokładnych współrzędnych w tym polu). Flaga `is_public` zapisana w dokumencie; publiczny feed / mapa **nie** są zaimplementowane (TODO poniżej).

### Storage

- Ścieżka obiektu: `users/{uid}/scans/{scanId}/original.jpg` (JPEG z metadanymi `contentType`).

### Sync (ręczny)

- Interfejs domenowy: `PendingScanSync.syncAllPending` — implementacja `FirebaseCloudSyncService` (równolegle `CloudScanSyncService` z pustym `enqueueForUpload`, żeby nie robić automatycznego uploadu po zapisie lokalnym).
- **Timeouty (polityka):** operacje sieciowe w jednym skanie są ograniczone czasem, żeby ręczny sync nie wisiał w nieskończoność przy „no route to host” / braku sieci: upload Storage (`putFile` + `getDownloadURL`) **30 s**, odczyt dokumentu Firestore (`get`) **15 s**, zapis (`set` merge) **15 s**. Implementacja: [`firebase_sync_timed.dart`](lib/features/scan/data/firebase_sync_timed.dart) + wywołania w [`FirebaseCloudSyncService`](lib/features/scan/data/firebase_cloud_sync_service.dart). Po przekroczeniu czasu rzucany jest `FirebaseSyncTimeoutException` (w `kDebugMode` log `debugPrint` z fazą i stack trace).
- **Kolejność i spójność:** najpierw upload JPEG do Storage; dopiero po sukcesie i uzyskaniu `downloadUrl` wykonywane są odczyt istniejącego dokumentu, `set(merge)` i ponowny `get` do scalenia. Przy błędzie lub timeoucie **przed** zapisem metadanych do Firestore **nie** tworzy się nowego dokumentu skanu (brak „pustego” rekordu bez obrazu). Jeśli obraz jest w Storage, a zapis/odczyt Firestore się nie powiedzie, skan pozostaje `pendingSync: true` z kodem błędu w `sync_last_error` — użytkownik może ponowić sync (ścieżki Storage/Firestore bez zmian; ponowny upload nadpisuje ten sam obiekt).
- **Wiele skanów oczekujących:** pętla po `pendingSync` — błąd lub timeout jednego skanu zwiększa licznik `failed` w [`SyncSummary`](lib/core/remote/sync_summary.dart), zapisuje bezpieczny kod błędu lokalnie i **kontynuuje** kolejne skany (żaden pojedynczy upload nie blokuje reszty partii).
- **`sync_last_error`:** zapisywane są stabilne kody (`SYNC_STORAGE_TIMEOUT`, `SYNC_FIRESTORE_READ_TIMEOUT`, itd. — patrz `FirebaseSyncStoredErrors`), nie surowy tekst wyjątków Firebase; szczegóły techniczne tylko w `debugPrint` przy `kDebugMode`.
- **UI:** po syncu z `failed > 0` snackbar zawiera przyjazny komunikat (`AppStrings.errorSyncScanConnection`, PL/EN) oraz podsumowanie liczbowe; surowe komunikaty providerów nie trafiają do UI.
- **Upload klienta (merge):** przy istniejącym dokumencie **nie** wysyła `vehicle_info`, `recognized_at`, `recognition_error` ani `status` — uniknięcie nadpisania wyniku AI i degradacji statusu z `recognized` do `waitingForRecognition`. Przy pierwszym utworzeniu dokumentu wysyłany jest `status: waitingForRecognition`. Zawsze wysyłane są m.in. `remote_image_url`, `is_public`, lokalizacja, `schema_version`, opcjonalnie `user_correction` jeśli istnieje lokalnie.
- **Scalanie po zapisie:** po `set(merge)` wykonywany jest `get` dokumentu; [`VehicleScanRemoteMerger`](lib/features/scan/data/vehicle_scan_remote_merger.dart) scala odpowiedź z lokalnym `VehicleScan` i zapisuje wynik w Hive (`pendingSync: false`, `remoteImageUrl`, pola AI z Firestore gdy ustawione, ochrona lokalnego stanu „po AI” gdy w chmurze nadal brak `vehicle_info` / status niekońcowy). `user_correction`: wybór nowszego znacznika `corrected_at` (lokal vs zdalny). `localImagePath` i `location` pozostają lokalne.
- Po sukcesie scalenia: czyszczenie `sync_last_error`. Przy błędzie uploadu: `sync_last_error` + `pendingSync` pozostaje `true`.
- **Automatyczne rozpoznanie AI po syncu:** przy dostępnej chmurze, po zrobieniu zdjęcia [`ScanCubit`](lib/features/scan/presentation/cubit/scan_cubit.dart) wywołuje `syncAllPending`, potem [`PostSyncRecognitionCoordinator`](lib/features/scan/domain/post_sync_recognition.dart) dla `SyncSummary.uploadedScanIds` odpala [`VehicleAnalysisService.analyzeScan`](lib/features/scan/domain/vehicle_analysis_service.dart), o ile [`PostSyncRecognitionPolicy`](lib/features/scan/domain/post_sync_recognition.dart) (`!pendingSync`, `remoteImageUrl`, status `waitingForRecognition`, brak `vehicleInfo`). Identycznie po **Synchronizuj teraz** w [`SyncCubit`](lib/features/settings/presentation/cubit/sync_cubit.dart). AI **nie** startuje przed pomyślnym merge skanu po uploadzie. Duplikaty równoległego `analyzeScan` dla jednego `scanId` są łączone w [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart). Błąd AI: lokalny `failed` + możliwość ręcznego ponowienia w szczegółach.
- UI: `SettingsScreen` → „Synchronizuj teraz” + `SyncCubit`; podsumowanie w `SnackBar` (liczba OK / błędów); przy `failed > 0` dodatkowo komunikat `errorSyncScanConnection` (bez surowego tekstu Firebase).

### Cloud Functions — rozpoznanie pojazdu (Gemini)

- **Katalog:** [`functions/`](functions/) — TypeScript, `npm run build` → `lib/`, testy `vitest` w `src/__tests__/`.
- **Callable:** `analyzeVehicleScan` (Cloud Functions **v2**, region domyślny **`us-central1`** — musi być zgodny z `FirebaseFunctions.instanceFor(region: 'us-central1')` w [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart)).
- **Sekret:** `GEMINI_API_KEY` przez `defineSecret` (`firebase-functions/params`) — **nigdy** w repozytorium; ustawienie: `firebase functions:secrets:set GEMINI_API_KEY` (interaktywnie wklej klucz z Google AI Studio / Vertex). Po pierwszym deployu z sekretem Firebase podłącza go do runtime funkcji.
- **Model:** `gemini-2.5-flash`, `responseMimeType: application/json`.
- **Wejście (data):** `{ "scanId": string, "language": "pl" | "en" }` — wymaga zalogowanego użytkownika (`context.auth`). Kontrakt zsynchronizowany z Flutter: [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart) (`httpsCallable('analyzeVehicleScan')`).
- **HttpsError (krótkie komunikaty dla klienta):** `unauthenticated` (brak auth), `invalid-argument` (Zod wejścia), `not-found` (brak dokumentu skanu lub brak pliku JPEG w Storage), `failed-precondition` (brak `remote_image_url` / brak skonfigurowanego sekretu Gemini po stronie serwera), `internal` (np. błąd odczytu Firestore, downloadu z Storage, zapisu `recognized` po sukcesie modelu). Błędy **Gemini / parsowania JSON / Zod** po zapisie `failed` w Firestore zwracane są jako **HTTP 200** z ciałem `{ status: "failed", recognition_error, ... }`, żeby Flutter mógł zaktualizować Hive (`_applyResponseAndReturn`) — szczegóły techniczne wtedy w `console.error` z polem `stage` (`gemini`, `zod_validate`, …).
- **Logi (Cloud Logging / `firebase functions:log`):** funkcja emituje `console.info` / `console.error` w formacie JSON (`fn`, `message`, `uid`, `scanId`, opcjonalnie `storagePath`, `outcome`) — bez promptu, bez `GEMINI_API_KEY`, bez pełnego `request.data` (logowana jest tylko lista kluczy). Szczegóły: [`functions/README.md`](functions/README.md) sekcja *Logi*.
- **Przepływ:** walidacja → odczyt `users/{uid}/scans/{scanId}` → wymóg `remote_image_url` + plik `users/{uid}/scans/{scanId}/original.jpg` w Storage → pobranie JPEG → Gemini → parsowanie JSON (Zod) → zapis w Firestore (`status`, `vehicle_info` w snake_case, `recognition_error`, `recognized_at`, `updated_at`). Sukces: `recognized`; błąd sieciowy AI lub parsowania: `failed` + krótki `recognition_error`.
- **Prompt (zasady):** identyfikacja pojazdu z obrazu; bez VIN/tablic/osób; `possibleEngines` max 4 krótkie stringi; `shortDescription` max 2 zdania; treści ludzkie (marka, opis…) w języku z `language`; **`vehicleType` i klucze JSON muszą być po angielsku** (tokeny enum); przed Zod odpowiedź jest normalizowana aliasami PL→EN w [`geminiEnumNormalize.ts`](functions/src/geminiEnumNormalize.ts) (trim, lower-case, usunięcie diakrytyków / `ł`→`l`). Schemat JSON jak w [`vehicleSchema.ts`](functions/src/vehicleSchema.ts).
- **Flutter:** [`VehicleAnalysisService`](lib/features/scan/domain/vehicle_analysis_service.dart) + [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart) wywołują callable i **aktualizują lokalny Hive** na podstawie odpowiedzi (bez bezpośredniego Gemini w aplikacji). Odpowiedź zawiera m.in. `recognized_at` (ISO) dla spójnego `recognizedAt` lokalnie; `userCorrection` w skanie **nie** jest kasowany przy aktualizacji AI. UI: szczegóły skanu — przycisk „Analizuj przez AI” gdy `waitingForRecognition` i skan zsynchronizowany (`!pendingSync` + `remoteImageUrl`).

### Reguły bezpieczeństwa (podsumowanie)

- Repozytorium: [`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules), wpis [`firebase.json`](firebase.json) pod deploy CLI.
- **Firestore — dokument użytkownika `users/{userId}`:** pełny odczyt/zapis dla właściciela (profil).
- **Firestore — skany `users/{userId}/scans/{scanId}`:** odczyt/usuń dla właściciela; **create** — tylko `status == waitingForRecognition` i brak pól `vehicle_info`, `recognized_at`, `recognition_error` w żądaniu; **update** — klient nie może zmieniać kluczy `vehicle_info`, `recognized_at`, `recognition_error`, `status` (przejścia do `recognized` / `failed` wyłącznie przez Admin SDK w Cloud Function). Dozwolone są m.in. `user_correction`, `is_public`, `remote_image_url`, lokalizacja, `schema_version`, `updated_at`.
- **Storage:** odczyt/zapis tylko własnego prefiksu `users/{uid}/scans/.../original.jpg`.

---

## Uprawnienia

- **Android / iOS:** manifest / Info.plist — kamera, lokalizacja when-in-use; brak uprawnień do galerii (import z galerii nie jest wspierany).
- **Runtime:** `ScanPermissionsService` (permission_handler) przed otwarciem aparatu; `Geolocator` nadal waliduje usługi i zgody przy `getCurrentPosition`.

---

## Zależności istotne dla MVP

- `permission_handler` — jawna prośba o kamerę i lokalizację.
- `geocoding` — uzupełnienie `city` / `country` / `displayName` (best effort; sieć/zależność od platformy).
- `hive_flutter`, `image_picker` (tylko kamera), `geolocator`, `go_router`, `flutter_bloc`.
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`.

---

## Testy

- `test/vehicle_scan_test.dart` — roundtrip JSON (schema 4), `user_correction` + `effectiveVehicleInfo`, migracja legacy.
- `test/app_strings_test.dart` — mapowanie typu pojazdu i statusu (PL/EN).
- `test/vehicle_correction_prefill_test.dart` — prefill formularza korekty z `effectiveVehicleInfo` / `userCorrection`.
- `test/scan_repository_test.dart` — integracja repozytorium z Hive + stub pozycji oraz widget historii (pusty stan; `CloudSyncAvailability` + `VehicleAnalysisService` dla `HistoryCubit`).
- `test/history_list_query_test.dart` — filtry/sortowanie historii i `isHistoryScanSyncedToCloud`.
- `test/confidence_viz_test.dart` — render etykiety poziomu pewności (`ConfidenceViz`).
- `test/auth_route_resolution_test.dart` — redirecty auth (`go_router`).
- `test/post_sync_recognition_test.dart` — reguły i koordynator auto-AI po syncu.
- `test/sync_cubit_test.dart` — m.in. wywołanie koordynatora po syncu z `uploadedScanIds`.
- `test/firebase_sync_timed_test.dart` — timeouty syncu i mapowanie kodów `sync_last_error`.
- `test/login_cubit_test.dart` — walidacja i ścieżka sukcesu logowania (fake `AuthRepository`).
- `test/firebase_initializer_test.dart` — rozpoznawanie błędu `duplicate-app` jako „już zainicjalizowane”.
- `test/vehicle_info_from_json_test.dart` — `VehicleInfo.fromJson` (camelCase jak z Cloud Function).
- `functions/src/__tests__/vehicleSchema.test.ts` (Vitest) — `callableInputSchema` (m.in. brakujący / pusty `scanId`) oraz parsowanie odpowiedzi Gemini (Zod).
- `test/widget_test.dart` — lekki smoke MaterialApp.
- Katalog **`functions/`**: `npm test` — Vitest w `src/__tests__/` (schemat callable + odpowiedź Gemini).

---

## CI (GitHub Actions)

Plik: [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### Triggery

- **push** do gałęzi `main` — każdy merge musi przejść pipeline zanim badge na README odzwierciedli stan repozytorium.
- **pull_request** do `main` — ten sam zestaw kroków na gałęzi źródłowej PR; zapobiega regresjom przed merge.

### Kroki i uzasadnienie

| Krok | Cel |
|------|-----|
| **Checkout** | Spójna kopia repo z commita/PR. |
| **Java 17 (Temurin)** | Wymóg Gradle / Android toolchain przy `flutter build apk`; wersja zgodna z typową konfiguracją Flutter 3.x. |
| **Cache Gradle** (`~/.gradle/caches`, `wrapper`) | Skraca czas joba — budowanie APK bez ponownego pobierania zależności Gradle przy niezmienionych plikach Android. |
| **Flutter stable + cache** (`subosito/flutter-action`, `cache: true`) | Stabilny kanał SDK + cache pub (`PUB_CACHE`), żeby `pub get` nie był bottleneckiem na każdym uruchomieniu. |
| **`flutter pub get`** | Deterministyczna instalacja zależności z `pubspec.lock`. |
| **`dart format --set-exit-if-changed .`** | Twardy gate stylu — brak „cichego” formatowania w CI; niezgodność kończy job kodem wyjścia ≠ 0. |
| **`flutter analyze`** | Blokuje merge przy błędach / ostrzeżeniach skonfigurowanych w `analysis_options.yaml`. |
| **`flutter test`** | Regresje jednostkowe/widgetowe bez uruchamiania emulatora. |
| **Node 20 + `npm ci` / `npm run build` / `npm test` w `functions/`** | Kompilacja TypeScript Cloud Functions + testy Vitest (schemat JSON). |
| **`flutter build apk --debug`** | Weryfikacja, że projekt **kompiluje się** w konfiguracji Android (Gradle, manifest, pluginy natywne); debug wystarcza na CI (szybsze, bez keystore). |

### Zachowanie przy błędach

Każdy z kroków z `run:` jest domyślnie **fail-fast** — pierwszy błąd przerywa job (format, analyze, test lub APK).

### Concurrency

`cancel-in-progress` dla tej samej grupy (np. ten sam PR przy kolejnych pushach) — mniej kolejek, świeższy wynik na ostatnim commicie.

### Rozszerzenia na później

- **iOS** — `flutter build ios --no-codesign` na `macos-latest` (osobny job macOS lub maciej w macierzy).
- **Sztywne pinowanie SDK** — pole `flutter-version` w `flutter-action` albo FVM + odczyt wersji z repo.
- **Sekrety / Firebase** — joby z `google-services.json` z GitHub Secrets (tylko gdy pojawi się integracja).
- **coverage** — `flutter test --coverage` + upload do Codecov / strona HTML artefaktu.
- **dependency review / Dependabot** — bezpieczeństwo łańcucha zależności.
- **Szeregowanie jobów** — np. szybki job „analyze + test” i wolniejszy „APK” z `needs:` dla czytelniejszej diagnostyki.

---

## Dług techniczny / TODO

1. **Freezed / `json_serializable`** — celowo wyłączone do czasu stabilnego `build_runner` w łańcuchu zależności; DTO są ręczne.
2. **`watchScans`** — implementacja oparta o broadcast i pełne przeładowanie listy; przy dużej liczbie rekordów rozważyć stronicowanie lub incremental sync.
3. **Usuwanie pliku przy nieudanym zapisie Hive** — obsłużone tylko dla etapu po `persistCameraImage` a przed sukcesem zapisu rekordu; inne ścieżki błędów warto dalej twardo audytować.
4. **Szczegóły skanu** — formularz korekty zapisuje `userCorrection`, nie `vehicleInfo`; brak automatycznego AI po zapisie lokalnym; UI photo-first z Hero i panelem dolnym.
5. **Publiczny feed / mapa / kolekcja „społecznościowa”** — pole `is_public` i `public_location_approximation` są przygotowane pod Firestore, ale brak osobnej kolekcji indeksu publicznego, agregacji ani endpointów — unikamy wycieku dokładnego GPS poza dokument prywatny użytkownika. Rozwój: osobna kolekcja lub Cloud Function filtrująca dane oraz zasady odczytu tylko dla zaufanych ról.
6. **Synchronizacja w tle** — tylko ręczny przycisk; brak Workmanagera / retry backoff / kolejki offline-dedicated.
7. **`RouterRefreshBridge`** — strumień sesji trwa cały czas życia aplikacji; przy rozbudowie auth rozważyć jawne zamknięcie subskrypcji poza `dispose` widgetu root (obecnie powiązane z `_RouterLifecycle`).

---

## Kompromisy

- Reverse geocoding może zawieść (brak sieci, limity API platformy) — UI pokazuje współrzędne jako fallback.
- **`BackdropFilter` (glass):** kilka stałych warstw (np. pływająca nawigacja) jest akceptowalne kosztem wydajności; **nie** stosować blur na każdym wierszu przewijanej listy — spadek FPS na starszych Androidach. Przy `blurSigma == 0` `GlassSurface` używa tylko półprzezroczystego tła (tańszy fallback).
- **Haptyka:** `AppHaptics` opiera się na `HapticFeedback`; na emulatorze lub urządzeniu bez silnika efekt bywa pusty — to normalne, UI nie powinno tego wymagać.
- **Hero + Slidable:** `flutter_slidable` z `closeOnScroll` i osobnym `InkWell` na kafelku minimalizuje konflikt z przewijaniem; nadal unikaj zagnieżdżania gestów (np. długie przeciągnięcia na tym samym wierszu co inny horizontal drag). Jeśli pojawią się regresje na konkretnych launcherach, rozważyć wyłączenie slidable na route z aktywnym Hero lub zawężenie `extentRatio`.
- **Testy z `ScanStatusBadge` w stanie „oczekuje”:** animacja pulsowania jest nieskończona — `pumpAndSettle()` w testach może wisieć; używać `pump(Duration)`.
- `ScanPermissionsService` tworzony inline w `AppRouter` dla zakładki Skan (bez globalnego DI) — akceptowalne na MVP; przy rozroście przenieść do `RepositoryProvider` / injectora.
- **Reguły Firestore vs pełny model:** klient nadal może w teorii wysłać w merge pola spoza listy zabronionych (np. przyszłe pola serwerowe o innych nazwach); trzymać spójność payloadu w [`FirebaseCloudSyncService`](lib/features/scan/data/firebase_cloud_sync_service.dart). Dokument nadrzędny `users/{uid}` ma szerokie `write` — jeśli kiedyś profil będzie edytowany z klienta, rozważyć węższe reguły.
