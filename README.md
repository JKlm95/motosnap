# MotoSnap

[![Flutter CI](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/JKlm95/motosnap/actions/workflows/ci.yml)

**MotoSnap** to mobilny MVP do dokumentowania pojazdów w terenie: jedno dotknięcie, zdjęcie z **aparatu**, **obowiązkowy GPS** i zapis **lokalnej historii** — gotowe pod dalszą synchronizację z chmurą i rozpoznanie AI, bez udawania gotowych wyników.

---

## Dlaczego warto zerknąć

- **Przepływ „skan → historia”** działa w pełni offline: uprawnienia, zdjęcie, pozycja, reverse geocoding (best effort), zapis w **Hive** jako JSON.
- **UX w stylu iOS**: stonowany motyw jasny/ciemny, duży przycisk skanu, czytelne karty sukcesu/błędu, lista historii z miniaturą i statusem.
- **Architektura pod rozwój**: feature-first, repozytorium skanów z `watchScans()`, szczegóły rekordu, publiczność rekordu, usuwanie — bez Firebase w tej iteracji.

---

## Funkcje (stan obecny)

| Obszar | Co działa |
|--------|-----------|
| **Skan** | Prośba o kamerę + lokalizację, zdjęcie tylko z aparatu (bez galerii), zapis pliku i rekordu `waitingForRecognition` |
| **Historia** | Lista lokalna, miniatura, data, miejsce (jeśli uda się z geokodowania), odświeżanie |
| **Szczegóły** | Pełnoekranowy widok zdjęcia, status, lokalizacja, przełącznik publiczny/prywatny, usuwanie |
| **Ustawienia** | Motyw systemowy/jasny/ciemny, placeholder pod logowanie (Firebase później) |

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

1. **Firebase** — Auth, Storage, Firestore, kolejka `pendingSync`.
2. **AI** — wypełnianie `vehicleInfo`, zmiana statusu na `recognized` / `failed`.
3. **Synchronizacja** — konflikty, retry, tło.

Pull requesty mile widziane; produkt jest świadomie „portfolio-grade”: czytelny kod, uczciwe komunikaty, bez magii w UI.
