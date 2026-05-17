# MotoSnap

[![Flutter CI](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml)

Aplikacja Flutter (Android / iOS) do skanowania pojazdów w terenie: zdjęcie z aparatu, wymagany GPS, zapis lokalny w Hive, opcjonalnie Firebase (auth, Firestore, Storage) i analiza AI przez Cloud Function (Gemini po stronie serwera).

---

## Co robi produkt

- **Skan:** uprawnienia → zdjęcie z kamery → szybki zapis lokalny (`waitingForRecognition`) → od razu można robić kolejny skan; sync do chmury i rozpoznanie AI lecą **w tle działającej aplikacji** (kolejka, nie OS background service).
- **Historia:** lista lokalna, filtry/sort (tylko klient), swipe (usuń / publiczność / ponów AI), skeleton przy pierwszym ładowaniu, pull-to-refresh.
- **Szczegóły:** Hero z listy, nagłówek zdjęcia, panel szkła z `DraggableScrollableSheet`, AI na żądanie, korekta użytkownika, publiczność, usuwanie.
- **Ustawienia:** motyw, konto, ręczny sync gdy Firebase jest skonfigurowany.

Szczegóły modeli, routingu, reguł Firestore i funkcji: [TECHNICAL.md](TECHNICAL.md).

---

## Firebase

### Konfiguracja w repozytorium

- **Android / iOS / web:** w repozytorium są **placeholdery** (`android/app/google-services.json`, `lib/firebase_options.dart`, iOS `GoogleService-Info.plist`) — bezpieczne do publicznego VCS. Aby podłączyć prawdziwy projekt Firebase, uruchom [`flutterfire configure`](https://firebase.flutter.dev/docs/cli/) (lokalnie nadpisze pliki; **nie commituj** produkcyjnych kluczy). Identyfikatory klienckie to nie sekrety serwera jak `GEMINI_API_KEY`, ale i tak unikaj wrzucania prawdziwej konfiguracji produkcyjnej do publicznego repo.
- **Publikacja produkcyjna / publiczne repo z żywym projektem:** warto włączyć **Firebase App Check**, **restrykcje klucza API** w Google Cloud (np. powiązanie z pakietem Android + SHA) oraz rozważyć **osobny projekt demo** na potrzeby portfolio — szczegóły w [TECHNICAL.md](TECHNICAL.md) (Firebase).

### Szybki start (nowe środowisko)

1. [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) — `flutterfire configure` w katalogu projektu.
2. W konsoli: Auth (e-mail/hasło), Firestore, Storage; reguły z repo: `firebase deploy --only firestore:rules,storage`.
3. Bez konfiguracji: tryb degradacji (skany lokalnie; komunikaty o braku chmury).
4. AI: wdrożone Cloud Functions + sekret `GEMINI_API_KEY` — [functions/README.md](functions/README.md).

---

## Uruchomienie

```bash
flutter pub get
flutter run
```

---

## Jakość

```bash
dart format .
flutter analyze
flutter test
```

W repozytorium jest workflow GitHub Actions (`ci.yml`) — ten sam zestaw kroków na `main` / PR.

---

## Dalszy rozwój (wysoki poziom)

1. AI / sync w tle, kolejki, retry.
2. Publiczny feed tylko z przybliżoną lokalizacją (bez dokładnego GPS w danych publicznych).

Kod trzyma się feature-first, repozytoriów i jawnych komunikatów błędów zamiast „udawania” gotowych integracji.
