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

Callable HTTPS (wymaga zalogowanego użytkownika Firebase). Szczegóły przepływu, model (`gemini-2.0-flash`) i schemat JSON: **[../TECHNICAL.md](../TECHNICAL.md)** (sekcja *Cloud Functions — rozpoznanie pojazdu*).
