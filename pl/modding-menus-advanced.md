# 🧪 Menu II — wnętrzności silnika, assety i pułapki

Wszystko na tej stronie zostało wyuczone na twardo — przez wydawanie menu
i patrzenie, jak się psują. Przeczytaj najpierw [Własne menu](/pl/modding-menus.md)
po podstawy.

> 💡 Większość poniższego jest dużo łatwiejsza z live'owym podglądem:
> **[CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)** —
> narzędzie w przeglądarce, które renderuje pliki `.menu` tak jak silnik, waliduje
> je (Menu Doctor) i eksportuje tekstury IWI **wraz z** skompilowanymi plikami
> material.

---

## Jak menu naprawdę się ładują

To każdego wywraca, więc bądźmy precyzyjni:

| Rodzaj menu | Jak się ładuje | Czego potrzebujesz |
|---|---|---|
| Menu klienta (menu główne, opcje…) | skompilowane do `mod.ff` | `menufile,ui_mp/x.menu` w mod.csv |
| Menu skryptowe (otwierane przez GSC) | skompilowane do `mod.ff` **i** precache'owane | `menufile,…` + `precacheMenu()` w GSC |

Kluczowe fakty:

- **Luźne pliki `.menu` i edycje `menus.txt` same z siebie nic nie robią** —
  jeśli twoja zmiana się nie pokazuje, to dlatego, że skompilowany `mod.ff` wciąż
  ma starą wersję. Przebuduj fastfile.
- **Nadpisanie po tej samej nazwie wygrywa.** Jeśli twój `mod.ff` zawiera `menuDef`
  o nazwie `main_text` (albo `player_profile`, `quit_popmenu`, …), zastępuje on
  stockowy. Tak przeskórowujesz wbudowane ekrany bez dotykania czegokolwiek innego.
- Stockowe menu często deklarują nazwy **bez cudzysłowów** (`name pc_join_unranked`).
  Jeśli skanujesz pliki po nazwach menu, obsłuż obie formy.
- Materiały odwoływane przez skompilowane menu (`background "my_mat"`,
  `exp material(…)`) stają się **automatycznymi zależnościami fastfile** — *nie*
  potrzebujesz dla nich linii `material,…` w mod.csv. Ale jeśli taki materiał jest
  zepsuty lub brakuje go przy linkowaniu, cały build wywala błąd.

---

## Twarde limity silnika (zapamiętaj je)

| Limit | Wartość | Objaw po przekroczeniu |
|---|---|---|
| itemDefy per menuDef | **256** | element #257: `unknown menu keyword {` + kaskada błędów |
| pojedynczy plik `.menu`/`.inc` | **32 KB** | błędy parsowania w punkcie odcięcia |
| sloty GSC `precacheMenu()` | ~32 | późniejsze precache zawodzą; trzymaj menu skryptowe szczupłe |
| pojedyncza alokacja obrazu | **~8 MB zdekodowane** | `Needed to allocate at least 8.0 MB to load images` |
| obszar klikalny (standardowy menuDef) | x ≈ **75–565** | przyciski przy krawędziach ekranu mają martwe strefy na 16:9 |

Praktyczne notatki:

- Licz itemDefy **po rozwinięciu makr** — lista 12 rzędów zbudowana z makra rzędu
  o 18 elementach to już 216 elementów.
- Limit obrazu 8 MB oznacza, że pełnoekranowe nieskompresowane tło musi być
  **rozbite na kafle** (np. cztery kawałki 1024×512 rysowane jako cztery itemDefy).
- Trzymaj każdy klikalny (`type 2`) element wewnątrz x 75–565; dekoracje mogą iść
  szerzej.

---

## Dziwactwa tekstu

- `\n` wewnątrz stringa **łamie** linie w grze:
  `text "Line one\nLine two"`.
- **Nigdy nie używaj em-dasha (—)** w tekście menu — font silnika renderuje go
  jako śmieci (`â`). Używaj `-`.
- Na klientach CoD4X **`^8` wewnątrz tekstu menu renderuje się jako ulubiony kolor
  gracza** — jedyny sposób na per-gracz kolor w menu. `forecolor` / `bordercolor`
  to skompilowane stałe i nigdy nie mogą być per-gracz.
- `exp forecolor A(…)` (alfa) działa; `exp forecolor R/G/B` to **błąd parsowania**.
  Animacja koloru = cross-fade dwóch różnie pokolorowanych elementów przez alfę.

### Pułapka etykiety przycisku

Tekst umieszczony bezpośrednio wewnątrz klikalnego elementu często w ogóle się nie
renderuje. Niezawodny wzorzec to: niewidoczne pudełko klikalne + osobna etykieta
dekoracji, przekolorowana na hover przez `setitemcolor`:

```menu
itemDef {
    name "btn_x"
    style 3
    rect 200 200 120 22 4 4
    background "white"
    forecolor 0 0 0 0
    type 2
    visible 1
    mouseenter { play "mouse_over"; setitemcolor "btn_x_t" forecolor 0.15 0.85 1 1; }
    mouseexit  { setitemcolor "btn_x_t" forecolor 0.78 0.86 0.94 0.85; }
    action { play "mouse_click"; open some_menu; }
}
itemDef {
    name "btn_x_t"
    rect 200 202 120 18 4 4
    forecolor 0.78 0.86 0.94 0.85
    textFont 0  textAlign 1  textScale 0.2  textstyle 6  textaligny 13
    exp text( "MY BUTTON" )
    visible 1
    decoration
}
```

Ponadto: silnik rysuje białą "focus" poświatę na ostatnio klikniętym elemencie —
zabij ją przez `focusColor 0 0 0 0` w menuDef.

---

## Animacje z `exp` (bez GSC)

Wyrażenia `exp` są ewaluowane co klatkę, a język wyrażeń ma zegar:
`milliseconds()`, plus `sin`, `cos`, `min`, `max`, `abs`. Cele animowalne:
**alfa** (`forecolor A`), **pozycja/rozmiar** (`rect X/Y/W/H`), **tekst**, **material**.

**Puls (oddychająca alfa):**

```menu
exp forecolor A( 0.05 + 0.05 * sin( milliseconds() / 900 ) );
```

**Ruch w jedną stronę** (przelot, który nigdy widocznie "nie wraca"): steruj
pozycją przez `sin`, a ukryj powrotną połowę cyklu bramkując alfę przez `cos`
tego samego argumentu:

```menu
exp rect Y( ( ( sin( milliseconds() / 4500 ) + 1 ) / 2 ) * 478 );
exp forecolor A( max( 0, cos( milliseconds() / 4500 ) ) * 0.1 );
```

**Efekty animowane sterowane hoverem:** `mouseenter`/`mouseexit` mogą uruchamiać
`setdvar`, a animowane elementy mogą być bramkowane na tym dvarze — więc najechanie
na przycisk może *włączyć dodatkowe animowane warstwy*:

```menu
mouseenter { setdvar ui_fx_boost 1; }
mouseexit  { setdvar ui_fx_boost 0; }
// na animowanym elemencie:
visible when( dvarint( "ui_fx_boost" ) == 1 )
```

### Fizyka blendowania alfy, którą musisz znać

- Nałożenie obrazu **na siebie** z alfą *nic nie robi*:
  `c*(1-a) + c*a = c`. "Rozjaśniająca" kopia tej samej tekstury jest
  matematycznie niewidoczna.
- **Rozjaśnianie** wymaga *innego* źródła: jaśniejszego wariantu obrazu (cross-fade
  dwóch obrazów), białego/tonowanego wypełnienia albo materiału addytywnego.
- **Przyciemnianie zawsze działa**: czarne wypełnienie z animowaną alfą.

---

## Tekstury: format IWI

`.iwi` (CoD4, wersja 6) to malutki nagłówek + dane pikseli:

| Offset | Rozmiar | Znaczenie |
|---|---|---|
| 0 | 3 | magic `IWi` |
| 3 | 1 | wersja = **6** |
| 4 | 1 | format: `0x01` RGBA32, `0x0B` DXT1, `0x0C` DXT3, `0x0D` DXT5 |
| 5 | 1 | flagi: `0x02` = brak mipmap |
| 6 | 2+2+2 | szerokość, wysokość, głębokość (u16 LE) |
| 12 | 4×4 | rozmiary per picmip: `[0]` = cały plik, `[1..3]` = rozmiar danych |
| 28 | … | dane pikseli (RGBA32 = kolejność bajtów BGRA, top-down) |

Pułapki, które dają "plik nie ładuje się w grze":

- flagi `0x00` bez obecnych danych mipmap — silnik oczekuje mipów i czyta śmieci.
  Dla grafiki UI zawsze zapisuj `0x02`.
- Nieskompresowane RGBA32 wygląda najlepiej dla gradientów menu (DXT1 powoduje
  banding), ale respektuj **limit dekodowania 8 MB** — kafluj duże tła.
- Rozmiary nie będące potęgą dwójki działają dla obrazów UI na CoD4X.

---

## Materiały bez Asset Managera

Skompilowane pliki material, które linker konsumuje (`materials/<name>`,
bez rozszerzenia), to małe binarki ze stałym 76-bajtowym nagłówkiem, po którym
idą stringi. Użyteczne fakty:

- Nagłówek trzyma **offsety stringów** (`@0` = nazwa materiału, `@4` = nazwa
  obrazu, `@64` = dosłowne `colorMap`, `@52/@60` = techset `2d`), więc dowolna
  długość nazwy jest ok, jeśli je przeliczysz.
- **Tryb blendowania to dwa bajty na offsecie 26–27**: `00 01` = normalny blend,
  `40 00` = addytywny.
- Żadne wymiary obrazu nie są przechowywane — jeden szablon pasuje do dowolnego
  rozmiaru tekstury.
- Pliki `material_properties/` **nie są potrzebne** dla materiałów 2D.
- Najtańsza droga ręcznie: skopiuj znany-dobry materiał 2D i wpatch'uj dwa
  stringi nazw (zachowaj identyczne długości). Albo pozwól
  [CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)
  wygenerować IWI **i** materiał jednym kliknięciem.

---

## Listboxy i feedery (lista serwerów, profile…)

Przewijalne listy silnika są napędzane przez *feedery*. Stałe mieszkają
w `ui/menudefinition.h` (dołączanym przez `ui/menudef.h`): `FEEDER_SERVERS`,
`FEEDER_PLAYER_PROFILES`, `FEEDER_MODS`, ownerdrawy jak `UI_NETSOURCE`,
`UI_SERVERREFRESHDATE`, …

```menu
itemDef {
    name mylist
    rect 52 138 536 236 4 4
    type ITEM_TYPE_LISTBOX
    style WINDOW_STYLE_FILLED
    elementwidth 528
    elementheight 15
    textscale 0.21
    elementtype LISTBOX_TEXT
    feeder FEEDER_SERVERS
    forecolor 1 1 1 1
    backcolor 0 0 0 0.35
    outlinecolor 0.15 0.85 1 0.12
    visible 1
    columns 11  2 16 20   18 16 10   36 170 22   208 86 25   296 50 10
                348 56 22  406 16 14  424 16 10  442 16 20  460 16 20  478 34 20
    doubleClick { uiScript JoinServer }
}
```

- `columns N`, potem N trójek `x width maxChars` (x względem listboxa).
- `elementwidth` kontroluje **szerokość paska zaznaczenia** — ustaw na wewnętrzną
  szerokość, inaczej podświetlenie się nie zgra.
- Per-element `textalign` centrujące jest ignorowane; projektuj pod tekst
  wyrównany do lewej z paddingiem `textalignx`.
- `noscrollbars` **nie istnieje** w PC CoD4 — stockowy scrollbar zawsze się rysuje.
  Ukryj go, zakrywając ten pasek pełną dekoracją rysowaną *po* listboxie
  (kolejność rysowania = kolejność w pliku), potem narysuj swoje linie ramki na
  wierzchu. Przewijanie kółkiem myszy nadal działa.
- Warunkowe przyciski wokół list używają `dvarTest` + `hideDvar`/`showDvar`.

Gdy przeskórowujesz stockowe ekrany (wybór profilu, przeglądarka serwerów…),
zachowaj każde wywołanie `uiScript` **dosłownie** — to jest funkcjonalność;
zmieniasz tylko chrom. I zachowaj każdy popup, który silnik otwiera **po nazwie**
(np. `profile_create_popmenu`, `password_popmenu`), zdefiniowany gdzieś, inaczej
te przepływy trafią w ślepy zaułek.

---

## Różne fakty o silniku

- **`open X` wewnątrz `onOpen` menu głównego nie działa przy boot** — silnik
  wciąż aktywuje `main_text`; nie buduj tam przekierowań "bounce". (`close self`
  tam jest jeszcze gorsze: czarny ekran.)
- Menu używane i w grze, i poza grą może bramkować elementy na dvarze silnika
  **`cl_ingame`** (`1` tylko gdy połączony).
- `cg_fov` / `cg_fovscale` są chronione przed cheatami — menu-side `setdvar`/
  `exec` na nich zawodzi po cichu; działa tylko server-side GSC `setclientdvar`.
  (`cg_thirdperson*` jest ok menu-side.)
- Na klientach CoD4X tekst brandingu menu głównego i numer buildu (prawy-dolny)
  są rysowane przez klienta, zakotwiczone do pozycji numeru buildu. Możesz zepchnąć
  cały blok poza ekran ze swojego menu:

  ```menu
  onOpen { setdvar ui_buildSize 0; setdvar ui_buildLocation "-1000 -1000"; }
  ```

- Makra: wewnątrz `#define` słowa kluczowe z opcjonalnymi końcowymi wartościami
  (jak `rect`) muszą wylistować **wszystkie sześć** wartości
  (`rect x y w h halign valign`) — preprocesor łączy linie, więc parser nie może
  polegać na końcach linii.
- Argumenty makr nie mogą zawierać przecinków; wielo-instrukcyjne akcje
  oddzielone `;` są ok.

---

*Chcesz szybko cokolwiek z tego zweryfikować? Załaduj swoje menu do
[CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)
i uruchom Menu Doctor.*
