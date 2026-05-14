# MotoSnap

[![Flutter CI](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml)

**MotoSnap** to mobilny MVP do dokumentowania pojazdów w terenie: jedno dotknięcie, zdjęcie z **aparatu**, **obowiązkowy GPS** i zapis **lokalnej historii** — gotowe pod dalszą synchronizację z chmurą i rozpoznanie AI, bez udawania gotowych wyników.

---

## Dlaczego warto zerknąć

- **Przepływ „skan → historia”** działa w pełni offline: uprawnienia, zdjęcie, pozycja, reverse geocoding (best effort), zapis w **Hive** jako JSON.
- **UX w stylu iOS**: stonowany motyw jasny/ciemny, duży przycisk skanu, czytelne karty sukcesu/błędu, lista historii z miniaturą i statusem.
- **Architektura pod rozwój**: feature-first, repozytorium skanów z `watchScans()`, szczegóły rekordu, publiczność rekordu, usuwanie; **Firebase Auth + Firestore + Storage** (inicjalizacja z bezpiecznym fallbackiem), ręczna synchronizacja `pendingSync`.

---

## Funkcje (stan obecny)

| Obszar | Co działa |
|--------|-----------|
| **Skan** | Prośba o kamerę + lokalizację, zdjęcie tylko z aparatu (bez galerii), zapis pliku i rekordu `waitingForRecognition` |
| **Historia** | Lista lokalna, miniatura, data, miejsce (jeśli uda się z geokodowania), odświeżanie |
| **Szczegóły** | Pełnoekranowy widok zdjęcia, status, lokalizacja, przełącznik publiczny/prywatny, usuwanie |
| **Ustawienia** | Motyw, konto (e-mail, wylogowanie), język (placeholder), status sync + **„Synchronizuj teraz”** (gdy Firebase działa) |

### Firebase (skrót)

1. Zainstaluj [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) i uruchom w katalogu projektu: `flutterfire configure` — nadpisze `lib/firebase_options.dart` oraz pliki natywne.
2. W konsoli Firebase włącz **Authentication (e-mail/hasło)**, utwórz bazę **Firestore** i **Storage**; wdróż reguły z repo: `firebase deploy --only firestore:rules,storage` (wymaga zalogowanego `firebase-tools`).
3. Bez poprawnej konfiguracji aplikacja startuje w trybie **offline** (lokalne skany działają; logowanie i sync z komunikatem o braku konfiguracji).

Szczegóły techniczne, modele i kompromisy: **[TECHNICAL.md](TECHNICAL.md)**.

---

## Szybki start

```bash
flutter pub get
flutter run
```

Wymagane platformy: **Android** i **iOS** (z akceptacją uprawnień do kamery i lokalizacji).

---

## Jakość kodu

```bash
dart format .
flutter analyze
flutter test
```

---

## Roadmap (wysoki poziom)

1. **AI** — wypełnianie `vehicleInfo`, zmiana statusu na `recognized` / `failed` (np. Gemini).
2. **Synchronizacja** — tło, retry, konflikty, ewentualnie pełna kolejka offline.
3. **Publiczny feed** — osobna kolekcja / reguły tylko dla przybliżonej lokalizacji (bez dokładnego GPS w danych publicznych).

Pull requesty mile widziane; produkt jest świadomie „portfolio-grade”: czytelny kod, uczciwe komunikaty, bez magii w UI.
