# 🗺️ VLCT Deathrun - Przewodnik dla Mapperów

Defensywny przewodnik po skryptowaniu GSC dla map **CoD4 Deathrun**. Wzorce, przepisy i zasady przetrwania zapobiegające crashom serwera.

> **Nowy tutaj?** Zacznij od [Szybkiego startu](#szybki-start-5-krokow) poniżej, potem przeczytaj [Podstawy](/pl/fundamentals.md) - to wszystko czego potrzebujesz żeby napisać swoją pierwszą pułapkę. Mówisz po angielsku/niemiecku/rosyjsku/hiszpańsku/francusku? Użyj przełącznika języka (prawy górny róg).

---

## Szybki start (5 kroków)

Najszybsza droga od zera do działającej mapy:

1. **Skopiuj plik szablonu**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_TWOJANAZWA.gsc`

2. **Otwórz go.** Przewiń do `main()`. Usuń linie `thread` dla funkcji których NIE chcesz (np. usuń `thread combat_room_sniper();` jeśli mapa nie ma pokoju snajperskiego). Zostaw `maps\mp\_load::main();` na górze.

3. **Dla każdej funkcji którą zostawisz,** znajdź jej sekcję w tym przewodniku i edytuj nazwy `targetname` z Radianta (wartości w `getEnt("...")`) żeby pasowały do tego co umieściłeś w Radiant.

4. **Skompiluj swój `.bsp`** w Radiancie (`Compile > BSP + Light + Link`). Twój `.gsc` zostanie wpieczony w `.ff` przez `linkMap`.

5. **Test:** `/map mp_dr_TWOJANAZWA` w konsoli serwera. Po każdym teście sprawdź `qconsole.log` pod kątem `script runtime error` (zobacz [Jak debugować](/pl/fundamentals.md#jak-debugowac)).

---

## Po co ten przewodnik

Engine GSC w CoD4 ma ostre krawędzie - jedna niezabezpieczona linia może:

* Wywalić **cały serwer** (np. wywołanie nieistniejącej funkcji wbudowanej jak `setmovespeed()`)
* Spamować tysiącami błędów na minutę (np. dostęp do `level.activ.X` gdy nikt nie jest w drużynie aktywatora)
* Po cichu zepsuć twoją mapę (np. duplikat `targetname` w Radiancie → `getEnt` zwraca undefined)

Większość istniejących map społeczności została napisana lata temu bez tych zabezpieczeń. Ten przewodnik został **wyciągnięty z prawdziwych bugów** które trafiliśmy na live serwerze z tysiącami gier dziennie. Każdy defensywny wzorzec poniżej ma swoją historię.

---

## Jak korzystać z przewodnika

| Jeśli jesteś... | Przeczytaj najpierw |
|---|---|
| **Zupełnie nowy w GSC** | [Podstawy](/pl/fundamentals.md) (Słownik + Zasady) → [Basics](/pl/basics.md) (Hello World) |
| **Używałeś tylko Radianta** | [Podstawy](/pl/fundamentals.md#radiant-gsc-bridge) (Most Radiant ↔ GSC) |
| **Pisałeś już mapy** | [Zanim napiszesz kod](/pl/before-you-code.md) (Anti-wzorce + Częste błędy) |
| **Szukasz przepisu** | [Pułapki](/pl/traps.md), [Pokoje](/pl/rooms.md), [Efekty](/pl/effects.md), [Zaawansowane](/pl/advanced.md) |
| **Trafiłeś na błąd którego nie rozumiesz** | [Podstawy](/pl/fundamentals.md#jak-debugowac) (Jak debugować) |
| **Chcesz copy-paste ściągę** | [Referencja](/pl/reference.md) |

---

## Pomóż w tłumaczeniu

Przewodnik jest **English-first** (serwer jest międzynarodowy) ale mapperzy są globalni. Jeśli Twoim ojczystym językiem jest niemiecki, rosyjski, hiszpański, francuski lub turecki - możesz pomóc tłumacząc dowolną stronę.

Odezwij się na [VLCT Discord](https://vlct.mxme.pro/discord) - załatwimy ci dostęp. Nawet jedna przetłumaczona strona pomaga tysiącom mapperów.

Brakujące tłumaczenia automatycznie powracają do angielskiego, więc częściowe tłumaczenia są od razu użyteczne.

---

## Konwencje w tym przewodniku

* **Bloki kodu GSC** są podświetlone jako C (najbliższe dopasowanie do GSC).
* Każdy przykład używa **defensywnych helperów** (`isValidPlayer`, `safeGetEnt`, `canUse`, `debugPrint`) zdefiniowanych w [Basics](/pl/basics.md).
* `// Komentarze tylko po angielsku.` Polski/rosyjski/etc wewnątrz plików `.gsc` rozwala engine - utrzymuj kod po angielsku nawet jeśli twój język to nie angielski.
* `level.activ` to **zawsze** slot aktywatora - i **zawsze** jest podejrzany. Każde odwołanie traktuj jako potencjalny crash chyba że jest opakowane w `isplayer(level.activ)`.

---

> Gotowy? → [Podstawy](/pl/fundamentals.md) to następny przystanek.
