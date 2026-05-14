# MotoSnap

MVP aplikacji Flutter do skanowania pojazdów: zdjęcie z aparatu, **wymagana** lokalizacja GPS, zapis skanu lokalnie oraz przygotowanie pod późniejszą synchronizację z Firebase i analizę AI (na razie tylko kontrakty / no-op).

## Stack

- **Architektura:** clean architecture, układ **feature-first** (`lib/features/...`, `lib/core/...`, `lib/app/...`).
- **Stan:** `flutter_bloc` (Cubit tam, gdzie wystarczy prostszy przepływ).
- **Nawigacja:** `go_router` + `StatefulShellRoute.indexedStack` (Skan / Historia / Ustawienia).
- **Lokalny cache:** **Hive** (`hive_flutter`) z zapisem JSON modelu skanu. **Isar** jest świetny przy bardzo dużych zbiorach i zapytaniach indeksowanych, ale na tym etapie wygrywa prostszy stack: Hive + jeden model JSON bez drugiego generatora (Isar + `json_serializable` często utrudniają `build_runner`). Dodatkowo w obecnym SDK `dart run build_runner` potrafi się wyłożyć na „build hooks” w transitive dependencies — stąd **modele są ręcznymi immutable DTO** z `toJson` / `fromJson` (łatwo później zastąpić Freezed + `json_serializable`, gdy toolchain się ustabilizuje).
- **Firebase / AI:** nie są jeszcze podłączone; są interfejsy (`CloudScanSyncService`, `VehicleAnalysisService`) i szkielety ekranów auth.

## Uruchomienie

```bash
flutter pub get
flutter run
```

## Testy i jakość

```bash
flutter analyze
flutter test
dart format .
```

## Struktura `lib/`

- `app/` — `MotosnapApp`, router, motyw, bootstrap (Hive, repozytoria).
- `core/` — usługi wspólne (lokalizacja, aparat, storage, „chmura” jako abstrakcja).
- `features/` — `splash`, `auth`, `scan`, `history`, `settings` (data / domain / presentation).

## Uprawnienia

Skonfigurowane wpisy w **AndroidManifest** oraz **Info.plist** (kamera + lokalizacja). Po stronie użytkownika trzeba zaakceptować dialogi systemowe.

## Następne kroki (poza tym PR)

- Firebase Auth + synchronizacja skanów.
- Implementacja `CloudScanSyncService` i kolejki uploadu.
- Integracja `VehicleAnalysisService` z backendem AI.
