# MotoSnap — dokumentacja techniczna

## Cel dokumentu

Opisuje architekturę, przepływ danych, modele, repozytoria, routing oraz znane kompromisy i dług techniczny. Aktualizować przy każdej istotnej zmianie implementacji.

---

## Architektura

- **`lib/app/`** — `AppBootstrap` (inicjalizacja Hive, składanie zależności), `MotosnapApp`, `go_router`, motyw.
- **`lib/core/`** — usługi infrastrukturalne: GPS (`DeviceLocationService` + `CurrentPositionReader`), reverse geocoding (`GeocodingLocationEnricher` / `PassthroughLocationEnricher`), aparat (`CameraCaptureService`, wyłącznie `ImageSource.camera`), zapis plików (`ImageStorageService`), uprawnienia (`ScanPermissionsService` + `permission_handler`), Hive (`ScanLocalDataSource`, `SettingsLocalDataSource`), abstrakcja chmury (`CloudScanSyncService`).
- **`lib/features/`** — `splash`, `auth` (placeholdery), `scan` (domena, repozytorium, UI skanu + szczegółów), `history` (lista), `settings`.

Logika biznesowa skanowania i persystencji jest w **repozytorium** i serwisach core; widgety/Cubit ograniczają się do stanu UI i wywołań repozytorium.

---

## Model `VehicleScan` (DTO, ręczny JSON)

- **Wersjonowanie:** `toJson()` zapisuje `schema_version: 2`. `fromJson()` rozpoznaje rekordy legacy (pola `image_path`, `captured_at`, `latitude`/`longitude` na root) i mapuje je na nowy kształt ze statusem `waitingForRecognition`.
- **Status:** `VehicleScanStatus` — `draft`, `waitingForRecognition`, `recognized`, `failed` (UI nie symuluje rozpoznania — po zapisie lokalnym jest `waitingForRecognition`).
- **Lokalizacja:** `ScanLocation` — `latitude`, `longitude`, opcjonalnie `city`, `country`, `displayName`, `isApproximatePublicLocation` (domyślnie `true`).
- **Pojazd:** `VehicleInfo?` — pola pod przyszłe AI; `null` oznacza brak rozpoznania.
- **Pola dodatkowe:** `remoteImageUrl`, `recognitionError`, `isPublic`, `pendingSync`.

Enum **`VehicleType`** jest w modelu informacji o pojeździe; dopuszczalne są `unknown` / `other`.

---

## Repozytorium skanów (`ScanRepository` / `ScanRepositoryImpl`)

Metody:

| Metoda | Zachowanie |
|--------|--------------|
| `watchScans()` | `async*` — pierwsza emisja pełnej listy, potem po każdej zmianie (wewnętrzny broadcast `void`). |
| `getRecentScans(limit)` | Sort malejąco po `createdAt`, obcięcie do `limit`. |
| `getScan(id)` | Odczyt z Hive. |
| `createScan(capturedPhoto:)` | Kopia pliku do katalogu aplikacji → GPS (wymagany) → enrich lokalizacji → zapis `VehicleScan` → no-op sync/AI → emisja zmiany. Przy błędzie po zapisie pliku — usunięcie skopiowego pliku. |
| `updateScan` | `upsert` z aktualizacją `updatedAt`. |
| `deleteScan` | Usunięcie pliku lokalnego (best effort) + rekordu w Hive. |
| `markAsPublic` / `markAsPrivate` | Odczyt, `copyWith(isPublic: ...)`, `updateScan`. |

---

## Hive

- Box: `vehicle_scans_json` — wartość: `jsonEncode(VehicleScan.toJson())`, klucz: `id`.
- Ustawienia motywu: osobny box (`SettingsLocalDataSource`).

---

## Routing (`go_router`)

- Shell: `/scan`, `/history`, `/settings` (`StatefulShellRoute.indexedStack`).
- Poza shellem: `/vehicle-scan/:scanId` — szczegóły skanu; `BlocProvider` + `ScanDetailCubit` tworzone w builderze trasy.
- `AppRoutes.vehicleScan(id)` buduje ścieżkę.

---

## Uprawnienia

- **Android / iOS:** manifest / Info.plist — kamera, lokalizacja when-in-use; brak uprawnień do galerii (import z galerii nie jest wspierany).
- **Runtime:** `ScanPermissionsService` (permission_handler) przed otwarciem aparatu; `Geolocator` nadal waliduje usługi i zgody przy `getCurrentPosition`.

---

## Zależności istotne dla MVP

- `permission_handler` — jawna prośba o kamerę i lokalizację.
- `geocoding` — uzupełnienie `city` / `country` / `displayName` (best effort; sieć/zależność od platformy).
- `hive_flutter`, `image_picker` (tylko kamera), `geolocator`, `go_router`, `flutter_bloc`.

---

## Testy

- `test/vehicle_scan_test.dart` — roundtrip JSON v2 + migracja legacy.
- `test/scan_repository_test.dart` — integracja repozytorium z Hive + stub pozycji oraz widget historii (pusty stan).
- `test/widget_test.dart` — lekki smoke MaterialApp.

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
4. **Szczegóły skanu** — brak edycji pól `vehicleInfo` z UI (świadomie do czasu AI).
5. **Firebase** — `pendingSync`, `CloudScanSyncService`, `VehicleAnalysisService` pozostają stubami.

---

## Kompromisy

- Reverse geocoding może zawieść (brak sieci, limity API platformy) — UI pokazuje współrzędne jako fallback.
- `ScanPermissionsService` tworzony inline w `AppRouter` dla zakładki Skan (bez globalnego DI) — akceptowalne na MVP; przy rozroście przenieść do `RepositoryProvider` / injectora.
