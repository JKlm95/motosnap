# MotoSnap — dokumentacja techniczna

## Cel dokumentu

Opisuje architekturę, przepływ danych, modele, repozytoria, routing oraz znane kompromisy i dług techniczny. Aktualizować przy każdej istotnej zmianie implementacji.

---

## Architektura

- **`lib/app/`** — `AppBootstrap` (Hive, Firebase `try/catch`, wybór repozytoriów auth/sync), `MotosnapApp`, `go_router` z redirectem auth + `RouterRefreshBridge`, motyw.
- **`lib/core/`** — usługi infrastrukturalne: GPS, geokodowanie, aparat, zapis plików, uprawnienia, Hive, abstrakcja kolejki chmury (`CloudScanSyncService`), wynik ręcznego sync (`SyncSummary`), init Firebase (`FirebaseInitializer`, `CloudSyncAvailability`).
- **`lib/features/`** — `splash` (hydracja sesji), `auth` (Firebase / offline), `scan` (domena, repozytorium, sync do Firestore+Storage, UI), `history`, `settings`.

Logika biznesowa skanowania i persystencji jest w **repozytorium** i serwisach core; widgety/Cubit ograniczają się do stanu UI i wywołań repozytorium.

---

## Model `VehicleScan` (DTO, ręczny JSON)

- **Wersjonowanie:** `toJson()` zapisuje `schema_version: 3`. `fromJson()` rozpoznaje rekordy legacy (pola `image_path`, `captured_at`, `latitude`/`longitude` na root) i mapuje je na nowy kształt ze statusem `waitingForRecognition`.
- **Status:** `VehicleScanStatus` — `draft`, `waitingForRecognition`, `recognized`, `failed` (UI nie symuluje rozpoznania — po zapisie lokalnym jest `waitingForRecognition`).
- **Lokalizacja:** `ScanLocation` — `latitude`, `longitude`, opcjonalnie `city`, `country`, `displayName`, `isApproximatePublicLocation` (domyślnie `true`).
- **Pojazd:** `VehicleInfo?` — pola pod przyszłe AI; `null` oznacza brak rozpoznania.
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

---

## Hive

- Box: `vehicle_scans_json` — wartość: `jsonEncode(VehicleScan.toJson())`, klucz: `id`.
- Ustawienia motywu: osobny box (`SettingsLocalDataSource`).

---

## Routing (`go_router`)

- **Redirect auth:** `AuthRouteResolution.redirect` — czysta funkcja (testy w `test/auth_route_resolution_test.dart`). Niezalogowany użytkownik na trasach shell (`/scan`, `/history`, `/settings`) lub `/vehicle-scan/...` jest kierowany na `/auth/login`. Zalogowany na `/auth/*` — na `/scan`. Splash (`/splash`) jest wyłączony z pętli: redirect zwraca `null`, a `SplashCubit` po krótkim opóźnieniu i pierwszym zdarzeniu `watchSession()` wykonuje `context.go` na login lub shell.
- **Odświeżanie:** `RouterRefreshBridge` nasłuchuje `AuthRepository.watchSession()` i podpięty jest do `GoRouter.refreshListenable` — po loginie/logoucie router przelicza redirect bez ręcznego „haka” w każdym ekranie.
- Shell: `/scan`, `/history`, `/settings` (`StatefulShellRoute.indexedStack`).
- Poza shellem: `/splash`, `/auth/login`, `/auth/register`, `/auth/forgot-password`, `/vehicle-scan/:scanId` — odpowiednie `BlocProvider` w builderach tras.
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

- Ścieżka: `users/{uid}/scans/{scanId}` (merge `set`).
- Pola m.in.: `status`, `is_public`, `remote_image_url`, `vehicle_info`, `recognition_error`, `schema_version`, znaczniki czasu.
- **Prywatność GPS:** `exact_location` — mapa z dokładnymi `latitude` / `longitude` (tylko w dokumencie prywatnym użytkownika). `public_location_approximation` — wyłącznie `city`, `country`, `display_name` (bez dokładnych współrzędnych w tym polu). Flaga `is_public` zapisana w dokumencie; publiczny feed / mapa **nie** są zaimplementowane (TODO poniżej).

### Storage

- Ścieżka obiektu: `users/{uid}/scans/{scanId}/original.jpg` (JPEG z metadanymi `contentType`).

### Sync (ręczny)

- Interfejs domenowy: `PendingScanSync.syncAllPending` — implementacja `FirebaseCloudSyncService` (równolegle `CloudScanSyncService` z pustym `enqueueForUpload`, żeby nie robić automatycznego uploadu po zapisie lokalnym).
- Po sukcesie: `remoteImageUrl` (download URL), `pendingSync: false`, czyszczenie `sync_last_error`. Przy błędzie: `sync_last_error` + `pendingSync` pozostaje `true`.
- UI: `SettingsScreen` → „Synchronizuj teraz” + `SyncCubit`; podsumowanie w `SnackBar` (liczba OK / błędów).

### Cloud Functions — rozpoznanie pojazdu (Gemini)

- **Katalog:** [`functions/`](functions/) — TypeScript, `npm run build` → `lib/`, testy `vitest` w `src/__tests__/`.
- **Callable:** `analyzeVehicleScan` (Cloud Functions **v2**, region domyślny **`us-central1`** — musi być zgodny z `FirebaseFunctions.instanceFor(region: 'us-central1')` w [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart)).
- **Sekret:** `GEMINI_API_KEY` przez `defineSecret` (`firebase-functions/params`) — **nigdy** w repozytorium; ustawienie: `firebase functions:secrets:set GEMINI_API_KEY` (interaktywnie wklej klucz z Google AI Studio / Vertex). Po pierwszym deployu z sekretem Firebase podłącza go do runtime funkcji.
- **Model:** `gemini-2.0-flash`, `responseMimeType: application/json`.
- **Wejście (data):** `{ "scanId": string, "language": "pl" | "en" }` — wymaga zalogowanego użytkownika (`context.auth`).
- **Przepływ:** walidacja → odczyt `users/{uid}/scans/{scanId}` → wymóg `remote_image_url` + plik `users/{uid}/scans/{scanId}/original.jpg` w Storage → pobranie JPEG → Gemini → parsowanie JSON (Zod) → zapis w Firestore (`status`, `vehicle_info` w snake_case, `recognition_error`, `recognized_at`, `updated_at`). Sukces: `recognized`; błąd sieciowy AI lub parsowania: `failed` + krótki `recognition_error`.
- **Prompt (zasady):** identyfikacja pojazdu z obrazu; bez VIN/tablic/osób; `possibleEngines` max 4 krótkie stringi; `shortDescription` max 2 zdania; język treści zgodny z `language`; schemat JSON jak w [`vehicleSchema.ts`](functions/src/vehicleSchema.ts).
- **Flutter:** [`VehicleAnalysisService`](lib/features/scan/domain/vehicle_analysis_service.dart) + [`FirebaseVehicleAnalysisService`](lib/features/scan/data/firebase_vehicle_analysis_service.dart) wywołują callable i **aktualizują lokalny Hive** na podstawie odpowiedzi (bez bezpośredniego Gemini w aplikacji). UI: szczegóły skanu — przycisk „Analizuj przez AI” gdy `waitingForRecognition` i skan zsynchronizowany (`!pendingSync` + `remoteImageUrl`).

### Reguły bezpieczeństwa (podsumowanie)

- Repozytorium: [`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules), wpis [`firebase.json`](firebase.json) pod deploy CLI.
- **Firestore:** odczyt/zapis tylko dla `request.auth.uid == userId` w `users/{userId}` oraz `users/{userId}/scans/{scanId}` (długość `scanId` ograniczona).
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

- `test/vehicle_scan_test.dart` — roundtrip JSON (schema 3) + migracja legacy.
- `test/scan_repository_test.dart` — integracja repozytorium z Hive + stub pozycji oraz widget historii (pusty stan).
- `test/auth_route_resolution_test.dart` — redirecty auth (`go_router`).
- `test/sync_cubit_test.dart` — ręczny sync (stub `PendingScanSync` / brak backendu).
- `test/login_cubit_test.dart` — walidacja i ścieżka sukcesu logowania (fake `AuthRepository`).
- `test/firebase_initializer_test.dart` — rozpoznawanie błędu `duplicate-app` jako „już zainicjalizowane”.
- `test/vehicle_info_from_json_test.dart` — `VehicleInfo.fromJson` (camelCase jak z Cloud Function).
- `test/widget_test.dart` — lekki smoke MaterialApp.
- Katalog **`functions/`**: `npm test` — walidacja schematu JSON (Zod) dla odpowiedzi Gemini.

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
4. **Szczegóły skanu** — brak ręcznej edycji `vehicleInfo` z UI (wynik tylko z Cloud Function); brak automatycznego AI po zapisie lokalnym.
5. **Publiczny feed / mapa / kolekcja „społecznościowa”** — pole `is_public` i `public_location_approximation` są przygotowane pod Firestore, ale brak osobnej kolekcji indeksu publicznego, agregacji ani endpointów — unikamy wycieku dokładnego GPS poza dokument prywatny użytkownika. Rozwój: osobna kolekcja lub Cloud Function filtrująca dane oraz zasady odczytu tylko dla zaufanych ról.
6. **Synchronizacja w tle** — tylko ręczny przycisk; brak Workmanagera / retry backoff / kolejki offline-dedicated.
7. **`RouterRefreshBridge`** — strumień sesji trwa cały czas życia aplikacji; przy rozbudowie auth rozważyć jawne zamknięcie subskrypcji poza `dispose` widgetu root (obecnie powiązane z `_RouterLifecycle`).

---

## Kompromisy

- Reverse geocoding może zawieść (brak sieci, limity API platformy) — UI pokazuje współrzędne jako fallback.
- `ScanPermissionsService` tworzony inline w `AppRouter` dla zakładki Skan (bez globalnego DI) — akceptowalne na MVP; przy rozroście przenieść do `RepositoryProvider` / injectora.
- **Firestore + sync klienta:** reguły nadal pozwalają właścicielowi na zapis całego dokumentu skanu; ponowny upload z lokalnego stanu może nadpisać `vehicle_info` ustawione przez Cloud Function — TODO: rozdzielenie pól serwerowych (patrz komentarz w `firestore.rules`).
