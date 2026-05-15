# MotoSnap — Firebase Cloud Functions

TypeScript (Node **≥ 20**), kompilacja `tsc` → katalog `lib/` (generowany; nie commituj ręcznie).

## Skrypty

| Skrypt | Opis |
|--------|------|
| `npm install` | Instalacja zależności + generacja `package-lock.json`. |
| `npm run build` | `tsc` — kompilacja do `lib/`. |
| `npm run lint` | `tsc --noEmit` (szybka weryfikacja typów). |
| `npm test` | Vitest — m.in. walidacja schematu JSON odpowiedzi Gemini. |

## Sekret Gemini (wymagany do `analyzeVehicleScan`)

1. Utwórz klucz API w [Google AI Studio](https://aistudio.google.com/) (lub użyj odpowiednika w Vertex AI).
2. W katalogu **głównym** projektu (tam gdzie `firebase.json`):

   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```

   Wklej wartość klucza — **nie zapisuj jej w repo**.

3. Pierwszy deploy z sekretem:

   ```bash
   cd functions
   npm ci
   npm run build
   cd ..
   firebase deploy --only functions
   ```

Firebase CLI powiąże sekret z funkcją używającą `defineSecret("GEMINI_API_KEY")`.

## Deploy

- Region funkcji: **`us-central1`** (zgodnie z kodem Flutter `FirebaseFunctions.instanceFor`).
- Po zmianach w `src/`:

  ```bash
  cd functions && npm run build && cd .. && firebase deploy --only functions
  ```

## Funkcja `analyzeVehicleScan`

Callable HTTPS (wymaga zalogowanego użytkownika Firebase). Szczegóły przepływu, model (`gemini-2.5-flash`) i schemat JSON: **[../TECHNICAL.md](../TECHNICAL.md)** (sekcja *Cloud Functions — rozpoznanie pojazdu*).

### Payload (callable `request.data`)

| Pole | Typ | Opis |
|------|-----|------|
| `scanId` | string | Niepusty, max 128 znaków — ten sam id co w Firestore / Storage. |
| `language` | `"pl"` \| `"en"` | Język treści odpowiedzi AI. |

Zgodne z Flutter: `FirebaseVehicleAnalysisService` → `httpsCallable('analyzeVehicleScan').call({ scanId, language })`.

### Obraz w Storage

Ścieżka (dokładnie): `users/{uid}/scans/{scanId}/original.jpg` (JPEG) — taka sama jak przy uploadzie z aplikacji.

### Logi (diagnostyka)

Po deployu logi są w **Google Cloud Console → Logging** (lub `firebase functions:log`), filtr np. `resource.type="cloud_run_revision"` + tekst `analyzeVehicleScan`.

- **`console.info`**: JSON z polami `severity`, `fn`, `message`, `uid`, `scanId`, ewent. `stage` / `storagePath` / `outcome` — **bez** promptu, **bez** sekretów, **bez** pełnego `request.data` (tylko lista kluczy).
- **`console.error`**: JSON z `stage`, `uid`, `scanId`, `errorName`, `errorMessage`, `stack` przy wyjątkach.

Typowe `message` / etapy po kliknięciu „Analizuj przez AI”: `started` → `auth_ok` → `request_data_shape` → `input_parsed` → `firestore_scan_path` → `firestore_scan_present` → `storage_path_resolved` → `image_download_started` / `image_download_finished` → `gemini_request_started` → `gemini_response_received` → walidacja → `firestore_update_recognized_*` lub `function_success` z `outcome`.
