# 🖼️ Własne menu (.menu UI)

Jak budować nakładki HUD i ekrany systemem `.menu` CoD4 - sterowane dvarami UI używane do live'owych paneli HUD, ekranów-list i interaktywnych menu. To ogólna wiedza CoD4 działająca w każdym modzie.

> **Czemu nie po prostu `newHudElem`?** Każdy gracz ma twardy limit **~31 elementów HUD** (zobacz [Efekty → Własny HUD](/pl/effects?id=własny-element-hud-timer-odliczania-baner)). Serwerowe `newHudElem()` i per-gracz `newClientHudElem()` dzielą ten budżet. Siatka 12 rzędów z 8 widgetami każdy = 96 elementów - silnik po cichu renderuje tylko pierwsze ~31 i porzuca resztę. Nakładki `.menu` renderują się **po stronie silnika z dvarów** i **nie** liczą się do tego limitu. Dlatego każde bogate, wielopanelowe UI powinno być `.menu`.

---

## Szybki start — działający panel w 4 krokach

Skopiuj to, zmień dwie nazwy i masz live'owy panel HUD sterowany dvarem. Reszta strony wyjaśnia każdy element.

**1. Utwórz `ui_mp/scriptmenus/mypanel.menu`:**

```c
#include "ui/menudef.h"
{
    menuDef {
        name        "mypanel"
        fullscreen  0
        rect        0 0 640 480
        visible     1

        // ciemne pudelko, pokazuje sie tylko gdy GSC ustawi ui_mypanel = 1
        itemDef {
            style       WINDOW_STYLE_FILLED
            rect        20 20 200 40 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
            backcolor   0 0 0 0.6
            visible     when( dvarInt("ui_mypanel") == 1 )
            decoration
        }
        // tekst ciagniety na zywo z dvara
        itemDef {
            rect        28 28 184 24 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
            forecolor   1 0.8 0 1
            textfont    UI_FONT_DEFAULT
            textscale   0.3
            textaligny  16
            exp text( dvarString("ui_mypanel_text") )
            visible     when( dvarInt("ui_mypanel") == 1 )
            decoration
        }
    }
}
```

**2. Zarejestruj to** w `mod.csv`: `menufile,ui_mp/scriptmenus/mypanel.menu`
i upewnij się, że build `.bat` kopiuje UI: `xcopy ui_mp ..\..\raw\ui_mp /SY`

**3. Precache'uj** to raz w GSC (nazwa pliku + każda nazwa menuDef):

```c
precacheMenu("mypanel");   // plik
precacheMenu("mypanel");   // menuDef (tu ta sama nazwa)
```

**4. Steruj tym z GSC** - panel reaguje, żaden redraw nie jest potrzebny:

```c
player setClientDvar("ui_mypanel_text", "Hello!");
player setClientDvar("ui_mypanel", 1);     // pokaz
// pozniej: player setClientDvar("ui_mypanel", 0);  // ukryj
```

To cała pętla: **menu opisuje wygląd raz, GSC zmienia dvary, silnik przerysowuje.** Dla nakładki HUD, która jest zawsze na ekranie, `#include`ujesz swój panel do trwałego menu HUD zamiast go otwierać; dla ekranu, który gracz otwiera na żądanie, użyj `player openMenu("mypanel")`.

> Chcesz, żeby szybko dobrze wyglądało? Przeskocz do [Stylowanie przycisków](#stylowanie-przycisków-hover-focus-motyw) i [Auto-layout list](#auto-layout-list-deklaratywne-makra) - te dwa wzorce pokrywają 90% dopracowanego menu.

---

## Jak to działa (szeroki obraz)

Plik `.menu` opisuje **layout** UI raz. Twój kod GSC karmi go **danymi** ustawiając dvary. Silnik przerysowuje co klatkę, czytając bieżące wartości dvarów.

```
GSC (serwer)                    .menu (klient, rysowane przez silnik)
------------                    ----------------------------
setClientDvar("ui_x", "Hello")  -->  exp text( dvarString("ui_x") )   pokazuje "Hello"
setClientDvar("ui_s", 1)        -->  visible when( dvarInt("ui_s") == 1 )   pokazuje panel
```

Nigdy nie "przerysowujesz" z GSC. Zmieniasz dvar; menu reaguje. **Zero zużytego budżetu HUD-elementów.**

---

## Struktura plików

* Pliki **`.menu`** trzymają jeden lub więcej bloków `menuDef { }`. Najwyższy poziom.
* Pliki **`.inc`** to fragmenty wciągane przez `#include` - zwykle `itemDef`y lub makra `#define`. Nie mają własnego `menuDef` (są dołączane do jednego).
* Pliki menu mieszkają pod `ui_mp/`. Częsty układ to jedno trwałe menu HUD w grze, które `#include`uje kilka fragmentów-paneli (`.inc`), więc każdy panel jest utrzymywany we własnym małym pliku.

> **Limit ładowania:** serwer może `precacheMenu` tylko **~32 menu**. Jeśli dodasz nowe samodzielne menu i uderzysz w limit, trzeba najpierw usunąć stare/nieużywane. Panele HUD dodane jako fragmenty `#include` wewnątrz istniejącego `menuDef` **nie** kosztują slotu precache - preferuj to.

---

## Układ współrzędnych

Wszystko jest na wirtualnym ekranie **640 × 480**, zawsze - niezależnie od prawdziwej rozdzielczości. `(320, 240)` to środek ekranu. `0 0 640 480` to pełny ekran.

```c
rect [x] [y] [width] [height] [HORIZONTAL_ALIGN] [VERTICAL_ALIGN]
```

| Słowo kluczowe align | Znaczenie |
|---|---|
| `HORIZONTAL_ALIGN_LEFT` | x mierzone od lewej krawędzi |
| `HORIZONTAL_ALIGN_RIGHT` | x od prawej; **ujemne x = przesunięcie w lewo od prawej krawędzi** |
| `VERTICAL_ALIGN_TOP` | y od góry |
| `VERTICAL_ALIGN_BOTTOM` | y od dołu; **ujemne y = przesunięcie w górę od dołu** |
| `..._CENTER` / `..._FULLSCREEN` | od środka / rozciągnięcie na pełny ekran |

Panel przyklejony do rogu **prawego-górnego**, 8px do wewnątrz:
`rect -148 28 140 152 HORIZONTAL_ALIGN_RIGHT VERTICAL_ALIGN_TOP`

> **Rozmiar tekstu:** dokumenty Quake mówią `textscale 1.0` = 48px. W CoD4 fonty HUD są inne - prawdziwy tekst HUD to **`0.25`-`0.35`**. Nie używaj `1.0`, jest gigantyczny.

---

## Twój pierwszy element

Statyczna etykieta tekstowa wewnątrz menu:

```c
itemDef {
    rect        20 20 200 20 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    forecolor   1 1 1 1            // RGBA, kazdy 0..1
    textfont    UI_FONT_DEFAULT
    textscale   0.3
    textalign   ITEM_ALIGN_LEFT    // 0 lewo / 1 srodek / 2 prawo
    textaligny  14                 // offset baseline od gory rect
    text        "Hello World"
    visible     1
    decoration                     // pasywne - brak mouseover, brak klikniecia
}
```

> **Zawsze dodawaj `decoration` do elementów HUD.** Bez tego element gra dźwięk mouseover i łapie kursor. Nakładki HUD są pasywne.

Wypełnione pudełko tła:

```c
itemDef {
    style       WINDOW_STYLE_FILLED   // FILLED = pelny backcolor
    rect        16 16 220 60 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.65            // polprzezroczysta czern
    visible     1
    decoration
}
```

Wartości `style`: `WINDOW_STYLE_EMPTY` (brak wypełnienia), `WINDOW_STYLE_FILLED` (pełny `backcolor`), `WINDOW_STYLE_SHADER` (obraz przez `background "shader"`).

---

## Uczynienie tego dynamicznym: `exp` i `visible when`

Statyczny tekst jest rzadki. Moc `.menu` to **`exp`** - wyrażenia runtime czytające żywe wartości.

```c
itemDef {
    rect        20 20 200 20 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    forecolor   1 0.8 0 1
    textfont    UI_FONT_DEFAULT
    textscale   0.3
    textaligny  14
    exp text( dvarString("ui_status") )         // tekst pochodzi z dvara
    visible when( dvarInt("ui_show") == 1 )      // widoczne tylko gdy dvar == 1
    decoration
}
```

Strona GSC - jedna linia zmienia to, co gracz widzi:

```c
player setClientDvar("ui_status", "^2Bet won!");
player setClientDvar("ui_show", 1);
```

### Funkcje, których możesz użyć wewnątrz `exp`

| Funkcja | Zwraca |
|---|---|
| `dvarInt("n")` `dvarFloat("n")` `dvarString("n")` | wartość dvara |
| `localVarString("n")` `localVarInt("n")` | kliencki local var |
| `stat(N)` | statystyka gracza #N (ranga, xp, ...) |
| `tableLookup("file.csv", keyCol, key, retCol)` | komórka z `.csv` |
| `milliseconds()` | czas silnika (do animacji) |
| `sin(x)` `cos(x)` | trygonometria w radianach (efekty pulsowania/błysku) |
| `+ - * /`, `( )`, string `+` | arytmetyka i konkatenacja stringów |

Pola, którymi `exp` może sterować: `rect X(...)`, `rect Y(...)`, `rect W(...)`, `rect H(...)`, `text(...)`, `material(...)`.

---

## Przepis: panel statusu ze stanami

Częsty wzorzec - jeden panel, kilka wyglądów sterowanych pojedynczym dvarem-integerem (`0=ukryty 1=aktywny 2=wygrany 3=przegrany`). Każda warstwa to własny `itemDef` z `visible when(==N)`. GSC przełącza jeden dvar; silnik pokazuje właściwą warstwę.

```c
// Tlo - widoczne, gdy panel jest w gorze (stan != 0)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        8 28 220 52 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.65
    visible     when( dvarInt("ui_panel_s") != 0 )
    decoration
}
// Zlota ramka - tylko w stanie "aktywny" (1)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        8 28 220 52 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0           // przezroczyste wypelnienie
    border      1                 // pelna ramka (WINDOW_BORDER_FULL)
    bordersize  0.4
    bordercolor 1 0.8 0 1
    visible     when( dvarInt("ui_panel_s") == 1 )
    decoration
}
// Tekst naglowka - czyta swoja etykiete z dvara
itemDef {
    rect        14 34 200 20 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    forecolor   1 0.8 0 1
    textfont    UI_FONT_DEFAULT
    textscale   0.3
    textaligny  14
    exp text( dvarString("ui_panel_h") )
    visible     when( dvarInt("ui_panel_s") != 0 )
    decoration
}
```

GSC: `player setClientDvar("ui_panel_s", 1); player setClientDvar("ui_panel_h", "Round 3");`

---

## Przepis: pasek postępu / głosowania

Szerokość to formuła w `exp rect W(...)`. Dwa pudełka: przygaszony tor i jasne wypełnienie, które rośnie.

```c
// Tor (tlo paska)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        20 60 200 8 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0.2 0.2 0.25 1
    visible     1
    decoration
}
// Wypelnienie - szerokosc = 200 * (glosy / maxGlosy)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        20 60 0 8 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   1 0.8 0 1
    exp rect W( 200 * ( dvarFloat("ui_row1_value") / dvarFloat("ui_row_max") ) )
    visible     1
    decoration
}
```

---

## Przepis: powtarzający się rząd (użyj makra)

Leaderboard albo lista głosowania to ten sam rząd N razy. Napisz go raz jako makro `#define`, wołaj per rząd. Tak też utrzymujesz dziesiątki rzędów pod kontrolą.

```c
// Jeden rzad = tlo + 3 kolumny sterowane dvarami.
// Backslash kontynuuje kazda linie; cale makro to jeden logiczny blok.
#define LB_ROW(x, y, w, h, idx, nameArg, timeArg) \
    itemDef { \
        rect x y w h 0 0  style WINDOW_STYLE_FILLED  backcolor 0.15 0.16 0.20 0.6 \
        visible 1  decoration \
    } \
    itemDef { \
        rect x y 0 0 0 0  exp text(idx)  textfont UI_FONT_NORMAL \
        textscale 0.25  textalignx 8  textaligny (h-2)  forecolor 1 1 1 1  decoration \
    } \
    itemDef { \
        rect (x+80) y 0 0 0 0  exp text(nameArg)  textfont UI_FONT_NORMAL \
        textscale 0.25  textaligny (h-2)  forecolor 1 1 1 1  decoration \
    } \
    itemDef { \
        rect (x+280) y 0 0 0 0  exp text(timeArg)  textfont UI_FONT_NORMAL \
        textscale 0.25  textaligny (h-2)  forecolor 1 1 1 1  decoration \
    }

// Wolaj raz per rzad - kolumny pochodza z dvarow, ktore ustawia twoje GSC:
LB_ROW(25, 120, 330, 15, "01", dvarString("lb_1_name"), dvarString("lb_1_time"))
LB_ROW(25, 140, 330, 15, "02", dvarString("lb_2_name"), dvarString("lb_2_time"))
LB_ROW(25, 160, 330, 15, "03", dvarString("lb_3_name"), dvarString("lb_3_time"))
```

> Kolumny są pozycjonowane przez `(x+80)`, `(x+280)` - arytmetyka jest dozwolona wszędzie w `rect`. Użyj `#idx` (stringify preprocesora) w `name`, by robić unikatowe nazwy per rząd: `name "row"#idx`.

---

## Kompletna powłoka menu

Gdy potrzebujesz całego nowego ekranu (nie tylko panelu HUD), to jest szkielet:

```c
#include "ui/menudef.h"
{
    menuDef {
        name        "menu_example"
        rect        0 0 640 480
        style       WINDOW_STYLE_EMPTY
        focuscolor  1 1 1 1
        onOpen      { execNow "set ui_example 1"; }
        onEsc       { close self; }

        itemDef { /* ... twoje elementy ... */ }
    }
}
```

---

## Ładowanie menu w grze

Dla panelu-nakładki HUD po prostu `#include`ujesz go do swojego trwałego menu HUD w grze i pokazuje się przez `visible when(...)`. Dla **samodzielnego ekranu** (sklep, picker) ładujesz i otwierasz go sam:

1. Umieść plik w `ui_mp/scriptmenus/yourmenu.menu`
2. Zarejestruj go w `mod.csv`: `menufile,ui_mp/scriptmenus/yourmenu.menu`
3. Upewnij się, że build `.bat` kopiuje UI: `xcopy ui_mp ..\..\raw\ui_mp /SY`
4. **Precache'uj plik ORAZ każdą nazwę `menuDef` w środku** (obie liczą się do limitu ~32):

```c
init()
{
    precacheMenu("yourmenu");   // nazwa PLIKU
    precacheMenu("home");       // nazwa menuDef w pliku
}
```

5. Otwórz to na graczu: `player openMenu("home");`

> Jeśli dostajesz "cannot find file", zrób tak, by nazwa `menuDef` pasowała do nazwy pliku.
>
> ⚠️ **`openMenu` zamyka wejście czatu gracza.** Nigdy nie otwieraj menu w trakcie gameplayu jako efekt uboczny - przerywa to każdemu piszącemu. Używaj go tylko dla celowych ekranów, o które gracz poprosił.

---

## Zarządzanie limitem menu

Silnik ogranicza, ile menu istnieje naraz (**~32**, licząc twoje wywołania `precacheMenu` **oraz** menu stockowe). Duże UI (ekrany customizacji, sklepy) uderzają w to szybko. Dwa wzorce trzymają cię poniżej:

**1. Jeden ekran, wiele stron przez dvar (zamiast osobnych menu-stron).**
Częsta pułapka to rozbicie długiej listy na pliki `mymenu_page_2`, `mymenu_page_3` - każdy osobne menu zjadające slot precache. Zamiast tego trzymaj jedno menu i przełączaj strony dvarem:

```c
onOpen { exec "set ui_page 0" }

// Elementy strony 1: visible when( dvarInt("ui_page") == 0 )
// Elementy strony 2: visible when( dvarInt("ui_page") == 1 )
// Przyciski Next / Prev:  action { exec "set ui_page 1"; }   /  { exec "set ui_page 0"; }
```

Trzy "strony", które były trzema menu (3 sloty), stają się jednym menu (1 slot).

**2. Przewijalna lista (`ITEM_TYPE_LISTBOX`)**, gdy silnik może karmić danymi - jedno menu pokazuje nieograniczoną listę bez żadnych stron (zobacz Listboxy niżej).

> Jeśli dodajesz nowe menu i coś przestaje działać, prawdopodobnie jesteś ponad limitem. Zwolnij najpierw slot: zwiń stronicowane menu (wzorzec 1) albo usuń stockowe menu, których twój mod nigdy nie używa, dostarczając własny `menus.txt` (testuj ostrożnie - niektóre są potrzebne klientowi).

---

## Interaktywne menu (przyciski, które odpowiadają do GSC)

Panel HUD jest pasywny. **Ekran** (sklep, głosowanie, picker) ma przyciski, które muszą powiedzieć twojemu skryptowi, co zostało kliknięte. To `scriptMenuResponse`:

```c
// W .menu - klikalny przycisk:
itemDef {
    type        ITEM_TYPE_BUTTON
    rect        20 100 120 24 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "Buy AK-47"
    textscale   0.3
    textaligny  16
    forecolor   1 1 1 1
    onFocus { play "mouse_over"; }
    action  { play "mouse_click"; scriptMenuResponse "buy_ak47"; }
}
```

```c
// W GSC - zlap odpowiedz:
player_menu_listener()
{
    self endon("disconnect");
    while(true)
    {
        self waittill("menuresponse", menu, response);
        if(response == "buy_ak47")
            self give_weapon("ak47_mp");
    }
}
```

> Przyciski (bez `decoration`) to jedyne miejsce, gdzie CHCESZ mouseover/klik. Zachowaj `decoration` dla wszystkiego pasywnego.

---

## Stylowanie przycisków (hover, focus, motyw)

Przycisk to normalnie **dwa itemDefy nałożone** w tym samym rect: pudełko tła (żebyś mógł je pokolorować/obramować i animować na hover) i element tekstowy będący właściwym `ITEM_TYPE_BUTTON`.

```c
// 1) Pudelko tla - nazwane, by skrypty hover mogly je przekolorowac
itemDef {
    name        "btn_bg_play"
    style       WINDOW_STYLE_FILLED
    rect        40 60 160 24 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.4
    border      1
    bordercolor 0.5 0.5 0.5 0.3
    decoration                       // tlo jest pasywne; element tekstowy obsluguje kliki
}
// 2) Tekst + cel klikniecia na wierzchu
itemDef {
    type        ITEM_TYPE_BUTTON
    style       WINDOW_STYLE_EMPTY
    rect        40 60 160 24 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "Play"
    textfont    UI_FONT_NORMAL
    textstyle   ITEM_TEXTSTYLE_SHADOWED
    textalign   ITEM_ALIGN_CENTER
    textaligny  16
    forecolor   1 1 1 1
    mouseEnter  { play "mouse_over"; setitemcolor "btn_bg_play" backcolor 0.2 0.2 0.2 0.6; }
    mouseExit   { setitemcolor "btn_bg_play" backcolor 0 0 0 0.4; }
    action      { play "mouse_click"; scriptMenuResponse "play"; }
}
```

Dwa sposoby na zmianę kolorów na hover:
* **`setitemcolor "name" backcolor R G B A`** - przekoloruj *inny* element po nazwie (użyte wyżej, by rozświetlić pudełko tła).
* **`setColor forecolor R G B A`** / **`setColor bordercolor ...`** - przekoloruj *bieżący* element (przydatne do świecącej ramki na hover).

`menuDef` ma też **`focuscolor R G B A`** - kolor tekstu, który element przyjmuje, gdy jest w focusie (klawiatura/mysz), aplikowany automatycznie bez skryptu.

### Zrób to wielorazowe - jedno makro przycisku

Zdefiniowanie przycisku jako makra `#define` trzyma każdy przycisk identycznym i pozwala przeskórować całe UI edytując jedno miejsce. Parametr `id` (z konkatenacją `#id` lub `"..."id`) daje każdej instancji unikatowe nazwy elementów.

```c
// Kolory motywu w jednym miejscu - zmien je, by przeskorowac kazdy przycisk.
#define BTN_BG        0 0 0 0.4
#define BTN_BG_HOVER  0.2 0.2 0.2 0.6
#define BTN_BORDER    0.5 0.5 0.5 0.3
#define BTN_TEXT      1 1 1 1

#define UI_BUTTON( id, x, y, w, h, label, onClick, vis ) \
    itemDef { \
        name "btnbg"id  style WINDOW_STYLE_FILLED  rect x y w h 0 0 \
        backcolor BTN_BG  border 1  bordercolor BTN_BORDER \
        visible when(vis)  decoration \
    } \
    itemDef { \
        type ITEM_TYPE_BUTTON  style WINDOW_STYLE_EMPTY  rect x y w h 0 0 \
        exp text(label)  textfont UI_FONT_NORMAL  textstyle ITEM_TEXTSTYLE_SHADOWED \
        textalign ITEM_ALIGN_CENTER  textaligny (h - 6)  forecolor BTN_TEXT \
        visible when(vis) \
        mouseEnter { play "mouse_over"; setitemcolor "btnbg"id backcolor BTN_BG_HOVER; } \
        mouseExit  { setitemcolor "btnbg"id backcolor BTN_BG; } \
        action     { play "mouse_click"; onClick } \
    }

// Uzyj tego:
UI_BUTTON( "play", 40, 60, 160, 24, "Play",     scriptMenuResponse "play";,    1 )
UI_BUTTON( "quit", 40, 90, 160, 24, "Quit",     close self;,                   1 )
```

> Trzymaj wszystkie swoje `#define` kolorów w jednym include, a każdy przycisk/panel z nich czyta. Przeskórowanie UI moda oznacza wtedy edycję garstki wartości, a nie polowanie po każdym pliku.

---

## Auto-layout list (deklaratywne makra)

Przepis [powtarzającego się rzędu](#przepis-powtarzający-się-rząd-użyj-makra) nadal kazał ci wpisywać `x` i `y` dla każdego rzędu. Dla prawdziwej listy (menu przycisków, siatka customizacji) chcesz pisać **tylko treść**, a pozycje niech liczą się same z indeksu. To najpotężniejszy wzorzec `.inc`: zbuduj mały zestaw makr layoutu raz, potem zadeklaruj całą listę wołając jedno makro per element.

### Idea: pozycja jest funkcją indeksu

Zdefiniuj geometrię raz, potem wyprowadź rect każdego elementu z jego indeksu `idx`:

```c
// --- stale layoutu (jedno miejsce do strojenia calej listy) ---
#define LIST_X            120
#define LIST_Y            100
#define LIST_W            170
#define LIST_H            25
#define LIST_GAP          (LIST_H + 5)          // krok pionowy
#define LIST_PER_COL      24                     // zawijaj po tylu

// --- indeks -> pozycja (silnik nigdy nie widzi idx; preprocesor go rozwija) ---
#define LIST_ROW( idx )   ( idx % LIST_PER_COL )
#define LIST_YPOS( idx )  ( LIST_Y + LIST_GAP * LIST_ROW( idx ) )
#define LIST_RECT( idx )  LIST_X LIST_YPOS( idx ) LIST_W LIST_H HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
```

Teraz makro elementu, które bierze tylko `idx` + treść:

```c
#define LIST_BUTTON( idx, label, onClick ) \
    itemDef { \
        name "lbg"idx  style WINDOW_STYLE_FILLED  rect LIST_RECT( idx ) \
        backcolor 0 0 0 0.5  decoration \
    } \
    itemDef { \
        type ITEM_TYPE_BUTTON  style WINDOW_STYLE_EMPTY  rect LIST_RECT( idx ) \
        exp text(label)  textfont UI_FONT_NORMAL  textscale 0.3 \
        textalign ITEM_ALIGN_LEFT  textalignx 10  textaligny 19  forecolor 1 1 1 1 \
        mouseEnter { play "mouse_over"; setitemcolor "lbg"idx backcolor 0.2 0.2 0.2 0.6; } \
        mouseExit  { setitemcolor "lbg"idx backcolor 0 0 0 0.5; } \
        action     { play "mouse_click"; onClick } \
    }
```

Cała lista to wtedy tylko deklaracje - żadnych współrzędnych, żadnego kopiuj-wklej:

```c
LIST_BUTTON( 0, "Play",      scriptMenuResponse "play"; )
LIST_BUTTON( 1, "Options",   open "options"; )
LIST_BUTTON( 2, "Customize", open "customize"; )
LIST_BUTTON( 3, "Quit",      close self; )
// dodaj element 4, 5, 6 ... ustawiaja sie automatycznie
```

### Siatka (rzędy + kolumny)

Spraw, by `idx` zawijał się w kolumny, wyprowadzając z niego zarówno rząd, jak i kolumnę:

```c
#define G_COLS            4
#define G_ROW( idx )      ( idx / G_COLS )           // dzielenie calkowite
#define G_COL( idx )      ( idx % G_COLS )
#define G_X( idx )        ( LIST_X + G_COL( idx ) * (LIST_W + 6) )
#define G_Y( idx )        ( LIST_Y + G_ROW( idx ) * (LIST_H + 6) )
#define G_RECT( idx )     G_X( idx ) G_Y( idx ) LIST_W LIST_H HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
```

### Warstw swoje makra (prawdziwa moc)

Dobre pliki `.inc` układają makra w warstwy, tak że każda warstwa dodaje jedną troskę. Częsty układ:

1. **Prymitywy** - malutkie wielorazowe buildery: `CREATE_SHADER(rect, image, color)`, `CREATE_TEXT(rect, str, color, scale, align)`, `CREATE_BUTTON(rect, label, scale, action)`. Każdy to jeden `itemDef`. Daj im warianty `_VIS` / `_EX` (dodatkowe parametry `visible` / dodatkowego kodu) nawarstwione z domyślnymi:
   ```c
   #define CREATE_SHADER(rect, img, col)            CREATE_SHADER_VIS(rect, img, col, 1)
   #define CREATE_SHADER_VIS(rect, img, col, vis)   CREATE_SHADER_EX(rect, img, col, vis, ;)
   #define CREATE_SHADER_EX(rect, img, col, vis, extra) \
       itemDef { rect rect  style WINDOW_STYLE_SHADER  forecolor col \
                 exp material(img)  visible when(vis)  extra }
   ```
2. **Indeks → geometria** - `LIST_RECT(idx)` jak wyżej.
3. **Stylowany widget** - połącz prymitywy na indeksie: motywowany przycisk = shader tła + pasek akcentu + tekst, wszystko z `idx`.
4. **Wysokopoziomowy element** - to, co faktycznie wołasz: `LIST_BUTTON(idx, label, action)`.

Ponieważ każda warstwa to `#define`, silnik widzi zawsze tylko finalne płaskie `itemDef`y. Dostajesz czyste, deklaratywne źródło menu, które trywialnie przestawić, przekolorować lub rozszerzyć - zmień stałą w warstwie 1, a cała lista się przeleje.

> Trzymaj buildery-prymitywy i `#define` kolorów w współdzielonym `.inc` (np. `includes/utility.inc`), a swoje makra list/siatek w innym (np. `includes/mylist.inc`). Menu wtedy `#include`ują oba i czytają się jak lista treści, a nie ściana współrzędnych.

### Widgety elementów ze stanem (zablokowany / wybrany / poziom)

Prawdziwe elementy listy często potrzebują więcej niż etykiety - ikonę kłódki, tag "wymagany poziom", podświetlenie "aktualnie wybrany". Zwiń to wszystko w makro elementu, żeby każde wywołanie zostało jednolinijkowe. Użyj `visible when(...)` na dodatkowych warstwach i czytaj dane przez `tableLookup` / dvar:

```c
// predykaty pomocnicze (zdefiniuj raz)
#define ITEM_LOCKED( table, id )  ( tableLookup(table, 0, id, 3) > stat(2350) )   // wymagana ranga > ranga gracza
#define ITEM_LEVEL( table, id )   tableLookup(table, 0, id, 3)

#define UNLOCK_BUTTON( idx, table, id ) \
    /* tlo + pasek akcentu z idx */ \
    CREATE_SHADER( LIST_RECT(idx), "ui_menu_button", 0 0 0 0.5 ) \
    /* etykieta ciagnieta z tabeli, klik wysyla id elementu do GSC */ \
    CREATE_BUTTON_EX( LIST_RECT(idx), tableLookup(table,0,id,4), 0.3, scriptMenuResponse id, 1, textalignx 10 textaligny 19 ) \
    /* czerwony tag "(poziom)" - tylko gdy zablokowany */ \
    CREATE_TEXT_VIS( UNLOCK_TAG_RECT(idx), "^1(" + ITEM_LEVEL(table,id) + ")", 1 1 1 1, 0.25, 2, ITEM_LOCKED(table,id) ) \
    /* nakladka ikony klodki - tylko gdy zablokowany */ \
    CREATE_SHADER_VIS( UNLOCK_ICON_RECT(idx), "menu_lock", 1 1 1 1, ITEM_LOCKED(table,id) )
```

**Podświetlenie wybranego** to po prostu kolejna warunkowa warstwa porównująca indeks elementu z dvarem:

```c
// normalny akcent vs "wybrany" akcent, zamieniane dvarem
CREATE_SHADER_VIS( FOOTER_RECT(idx), "ui_footer", 0.6 0.6 0.6 1, dvarInt("ui_selected") != idx )
CREATE_SHADER_VIS( FOOTER_RECT(idx), "ui_footer", 1 0.8 0 1,     dvarInt("ui_selected") == idx )
```

GSC ustawia `ui_selected`, gdy gracz wybierze element (przez `scriptMenuResponse`), a podświetlenie przesuwa się bez dodatkowego kodu menu.

> Per-element **obraz** też może pochodzić z indeksu: `exp material( "ui_icon" + idx )` daje elementowi 0 `ui_icon0`, elementowi 1 `ui_icon1` itd. - jedno makro, nieograniczone ikony.

### Nagłówek, stopka i przyciski stron jako makra

To samo podejście skaluje się do całych regionów menu. Zdefiniuj `HEADER` (nazwa gracza, ikona rangi, pasek XP `exp rect W(...)`), `FOOTER` (wiadomość dnia z tekstem `autowrapped`) i przyciski poprzedniej/następnej strony raz, potem upuść je na dowolną stronę:

```c
#define PAGE_NAV( prevMenu, nextMenu ) \
    CREATE_BUTTON_EX( 120 360 50 17 0 0, "@MENU_PAGE_PREVIOUS", 0.26, close self; open prevMenu, 1, ; ) \
    CREATE_BUTTON_EX( 250 360 50 17 0 0, "@MENU_PAGE_NEXT",     0.26, close self; open nextMenu, 1, ; )
```

(`@NAME` to string zlokalizowany z twoich plików językowych.) Zbuduj wielostronicowy ekran, dając każdej stronie ten sam `HEADER` / `FOOTER` / `PAGE_NAV` i zmieniając tylko listę elementów - każda strona wygląda identycznie za darmo.

---

## Skróty klawiszowe (`execKey`)

Wewnątrz `menuDef` możesz przypisać klawisz do akcji - świetne do szybkich menu (naciśnij cyfrę, by wybrać opcję):

```c
execKey "1" { scriptMenuResponse "option1"; close self }
execKey "2" { scriptMenuResponse "option2"; close self }
execKey "r" { exec "cmd callvote map_restart"; close self }
```

Handler uruchamia się w momencie naciśnięcia klawisza, gdy menu jest otwarte. Połącz z `scriptMenuResponse` (zobacz wyżej), żeby GSC wiedziało, który klawisz został wybrany.

---

## Listboxy (listy karmione przez silnik)

Dla długich, przewijalnych list, które silnik może wypełnić (listy map, listy graczy), użyj `ITEM_TYPE_LISTBOX` z `feeder`:

```c
itemDef {
    type          ITEM_TYPE_LISTBOX
    rect          40 60 240 200 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    feeder        FEEDER_ALLMAPS        // silnik dostarcza rzedy
    elementtype   LISTBOX_TEXT          // lub LISTBOX_IMAGE
    elementheight 25
    columns       1 2 190 25            // liczba, potem [offset szerokosc maxZnakow] per kolumna
    forecolor     1 1 1 1
    outlinecolor  1 1 1 0.2             // podswietlenie zaznaczenia - trzymaj bardzo przezroczyste
    doubleclick   { play "mouse_click"; uiScript StartServer; }
}
```

Wartości `feeder` są definiowane przez silnik (np. `FEEDER_ALLMAPS`, `FEEDER_PLAYER_LIST`, `FEEDER_LEADERBOARD`). Silnik jest właścicielem danych i bieżącego zaznaczenia.

---

## Budowanie ekranu ustawień / opcji

Czysty wzorzec na ekran opcji w grze: **jedno menu, kilka zakładek przełączanych dvarem** - żadne dodatkowe menu nie są potrzebne.

```c
// W onOpen wybierz domyslna zakladke:
onOpen { exec "set ui_subtab 0" }

// Naglowki zakladek - klikniecie ustawia dvar:
//   (uzyj wlasnego makra przycisku / itemDef z type ITEM_TYPE_BUTTON)
//   action { exec "set ui_subtab 0"; }   -> "Visual"
//   action { exec "set ui_subtab 1"; }   -> "Binds"

// Opcje pojawiaja sie tylko gdy ich zakladka jest aktywna, przez visible when:
itemDef {
    type        ITEM_TYPE_BUTTON
    rect        70 130 135 23 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "Fullbright"
    textscale   0.3
    textaligny  16
    forecolor   1 1 1 1
    visible     when( dvarInt("ui_subtab") == 0 )
    action      { scriptMenuResponse "toggle_fullbright"; }   // GSC przelacza dvar
}
itemDef {
    type        ITEM_TYPE_BUTTON
    rect        70 130 135 23 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "125 FPS"
    textscale   0.3
    textaligny  16
    visible     when( dvarInt("ui_subtab") == 1 )
    action      { exec "com_maxfps 125"; }                    // bezposrednia komenda konsoli
}
```

Dwa rodzaje przycisku opcji:
* **Przełącz ustawienie** → `action { scriptMenuResponse "name"; }` i pozwól GSC zmienić dvar (działa dla dvarów server-side lub chronionych).
* **Uruchom komendę** → `action { exec "command"; }` dla zwykłych komend klienckich (`com_maxfps`, `toggle ...`).

> **Wykorzystaj ekrany stockowe.** Nie musisz przebudowywać pełnych stron Controls / Options. Ze swojego menu możesz `open "main_controls"` / `open "main_options"`, by przekazać do wbudowanych ekranów, i motywować je nadpisując kolory, które czytają. Buduj własny ekran tylko dla opcji specyficznych dla moda.

Żeby dopasować do wyglądu twojego moda, ustaw swoje kolory raz (np. przez `#define` dla ramki / tła / tekstu) i wykorzystaj je w każdym makrze przycisku, tak by cały ekran był spójny i łatwy do przeskórowania później.

---

## Pułapki

| Pułapka | Skutek | Fix |
|---|---|---|
| `textscale 1.0` (z dokumentów Quake) | tekst jest ogromny | HUD CoD4 używa `0.25`-`0.35` |
| Brak `decoration` | dźwięk mouseover, element łapie focus | dodaj `decoration` |
| `WINDOW_STYLE_FILLED` bez `backcolor` | nic się nie pokazuje | ustaw `backcolor` RGBA |
| `WINDOW_STYLE_SHADER` bez `background` | nic / błąd | ustaw `background "shader"` |
| `itemDef` wewnątrz `itemDef` | błąd parsowania | elementy idą bezpośrednio w `menuDef` |
| Dwa kody koloru z rzędu w tekście (`^8^7`) | tekst zawodzi / pokazuje się dosłownie | buduj string pojedynczymi kodami `^N` |
| Dvar nieustawiony zanim menu się rysuje | `exp` czyta `""` / `0` | ustaw dvar w GSC **przed** pokazaniem panelu |
| Ponad ~32 precache'owanych menu | menu się nie załaduje | usuń/scal nieużywane menu |
| Ponad ~31 `newHudElem` per klient | dodatkowe HUD-y nigdy się nie renderują | przenieś UI do nakładki `.menu` (cała ta strona) |

---

## Most GSC ↔ menu w jednym miejscu

```c
// Serwerowe GSC pcha dane; menu czyta je przez exp / visible when.
player setClientDvar("ui_panel_s", 1);            // przelacz panel  (visible when ==1)
player setClientDvar("ui_panel_h", "Round 3");    // tekst panelu    (exp text)
player setClientDvar("ui_panel_y", 28);           // pozycja panelu  (exp rect y)
// Dla wszystkich: petla po graczach i setClientDvar kazdemu, lub setDvar dla wartosci globalnej.
```

Konwencja: prefiksuj swoje dvary UI przez `ui_` i trzymaj nazwy krótkie, żeby łatwo je wypatrzeć i nie kolidowały.

---

> Ta strona to praktyczny starter. Autorytatywna lista słów kluczowych mieszka w źródle silnika CoD4 (`menu.c`) i na wiki [COD4 Menu Builder](https://github.com/SheepWizard/COD4-MENU-BUILDER) - oba to dobre kolejne przystanki, gdy potrzebujesz właściwości, której ta strona nie pokrywa.
>
> 🏠 [Powrót do strony głównej](/pl/) · [⬅ Dla Modderów](/pl/modding)

---

> ➡️ **Dalej:** [Menu II — wnętrzności silnika, assety i pułapki](/pl/modding-menus-advanced.md) — twarde limity (256 itemDefów!), animacje `exp`, formaty IWI/material, listboxy, nadpisania menu stockowych.
