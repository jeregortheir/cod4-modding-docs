# 🛠️ Dla Modderów

Ta sekcja jest dla **twórców modów**, nie twórców map.

Reszta tego przewodnika ([Podstawy](/pl/fundamentals), [Pułapki](/pl/traps), [Pokoje](/pl/rooms) ...) uczy cię, jak oskryptować **pojedynczą mapę**. Ta sekcja jest inna: obejmuje systemy na poziomie silnika, które leżą pod każdą mapą - zaczynając od systemu **menu (UI)**.

> **Mapper czy modder?**
> Jeśli piszesz `.gsc` mapy (`maps\mp\mp_dr_TWOJANAZWA.gsc`), jesteś **mapperem** - zacznij od [Podstaw](/pl/fundamentals).
> Jeśli budujesz **UI / menu** albo inne systemy server-side, jesteś **modderem** - jesteś we właściwym miejscu.

To ogólna wiedza o moddingu CoD4 - dotyczy każdego moda CoD4, nie tylko jednego serwera.

---

## Co tu znajdziesz

| Temat | Co obejmuje |
|---|---|
| [🖼️ Własne menu (.menu UI)](/pl/modding-menus) | Budowanie nakładek HUD i ekranów plikami `.menu` - system UI sterowany dvarami |
| [🧪 Menu II — wnętrzności i assety](/pl/modding-menus-advanced) | Wnętrzności menu, limity assetów, pipeline IWI/material |
| [🔤 Własne fonty i emoji na czacie](/pl/modding-fonts) *(eksperymentalne)* | Obrazki inline w tekście czatu - tablice glifów, atlas fontu i dostarczanie go przez `mod.ff`, żeby gracze nie potrzebowali patcha klienta |

*(z czasem dojdą kolejne rozdziały)*

---

## Zanim ruszysz żywego moda

Kod moda działa pod **każdą** mapą naraz. Zła zmiana tutaj psuje wszystkie, nie tylko twoją.

* **Najpierw testuj na lokalnym serwerze.** Nigdy nie pushuj prosto na żywy serwer.
* **Jeden system naraz.** Zmień jedno, przetestuj to jedno, potem idź dalej.
* **Tylko angielski w kodzie i komentarzach.** Nie-ASCII w `.gsc`/`.menu` może zepsuć silnik.
* **Jak nie masz pewności - najpierw zapytaj.** [Discord VLCT](https://vlct.mxme.pro/discord) jest do tego.

---

> Zacznij od [Własnych menu (.menu UI)](/pl/modding-menus) - najczęściej proszonego tematu modderskiego.
