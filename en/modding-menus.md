# 🖼️ Custom Menus (.menu UI)

How to build HUD overlays and screens with CoD4's `.menu` system - the dvar-driven UI used for live HUD panels, list screens, and interactive menus. This is general CoD4 knowledge that works in any mod.

> **Why not just use `newHudElem`?** Each player has a hard cap of **~31 HUD elements** (see [Effects → Custom HUD](/en/effects?id=custom-hud-element-countdown-timer-banner)). Server `newHudElem()` and per-player `newClientHudElem()` share that budget. A 12-row grid with 8 widgets each = 96 elements - the engine silently renders only the first ~31 and drops the rest. `.menu` overlays render **engine-side from dvars** and do **not** count against that limit. That is why any rich, multi-panel UI should be a `.menu`.

---

## Quick start — a working panel in 4 steps

Copy this, change two names, and you have a live dvar-driven HUD panel. The rest of the page explains each piece.

**1. Create `ui_mp/scriptmenus/mypanel.menu`:**

```c
#include "ui/menudef.h"
{
    menuDef {
        name        "mypanel"
        fullscreen  0
        rect        0 0 640 480
        visible     1

        // dark box, shows only when GSC sets ui_mypanel = 1
        itemDef {
            style       WINDOW_STYLE_FILLED
            rect        20 20 200 40 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
            backcolor   0 0 0 0.6
            visible     when( dvarInt("ui_mypanel") == 1 )
            decoration
        }
        // text pulled live from a dvar
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

**2. Register it** in `mod.csv`: `menufile,ui_mp/scriptmenus/mypanel.menu`
and make sure the build `.bat` copies UI: `xcopy ui_mp ..\..\raw\ui_mp /SY`

**3. Precache** it once in GSC (file name + every menuDef name):

```c
precacheMenu("mypanel");   // file
precacheMenu("mypanel");   // menuDef (same name here)
```

**4. Drive it from GSC** - the panel reacts, no redraw needed:

```c
player setClientDvar("ui_mypanel_text", "Hello!");
player setClientDvar("ui_mypanel", 1);     // show it
// later: player setClientDvar("ui_mypanel", 0);  // hide it
```

That is the whole loop: **the menu describes the look once, GSC changes dvars, the engine redraws.** For a HUD overlay that is always on screen you `#include` your panel into a persistent HUD menu instead of opening it; for a screen the player opens on demand, use `player openMenu("mypanel")`.

> Want it to look good fast? Skip ahead to [Styling buttons](#styling-buttons-hover-focus-theming) and [Auto-layout lists](#auto-layout-lists-declarative-macros) - those two patterns cover 90% of a polished menu.

---

## How it works (the big picture)

A `.menu` file describes the UI **layout** once. Your GSC code feeds it **data** by setting dvars. The engine redraws every frame, reading the current dvar values.

```
GSC (server)                    .menu (client, engine-drawn)
------------                    ----------------------------
setClientDvar("ui_x", "Hello")  -->  exp text( dvarString("ui_x") )   shows "Hello"
setClientDvar("ui_s", 1)        -->  visible when( dvarInt("ui_s") == 1 )   shows panel
```

You never "redraw" from GSC. You change a dvar; the menu reacts. **Zero HUD-element budget used.**

---

## File structure

* **`.menu`** files hold one or more `menuDef { }` blocks. Top-level.
* **`.inc`** files are fragments pulled in with `#include` - usually `itemDef`s or `#define` macros. They have no `menuDef` of their own (they get included into one).
* Menu files live under `ui_mp/`. A common setup is one persistent in-game HUD menu that `#include`s several panel fragments (`.inc`), so each panel is maintained in its own small file.

> **Loading limit:** the server can `precacheMenu` only **~32 menus**. If you add a new standalone menu and hit the cap, an old/unused one has to be removed first. HUD panels added as `#include` fragments inside an existing `menuDef` do **not** cost a precache slot - prefer that.

---

## The coordinate system

Everything is on a virtual **640 × 480** screen, always - no matter the real resolution. `(320, 240)` is screen center. `0 0 640 480` is fullscreen.

```c
rect [x] [y] [width] [height] [HORIZONTAL_ALIGN] [VERTICAL_ALIGN]
```

| Align keyword | Meaning |
|---|---|
| `HORIZONTAL_ALIGN_LEFT` | x measured from the left edge |
| `HORIZONTAL_ALIGN_RIGHT` | x from the right; **negative x = offset left from right edge** |
| `VERTICAL_ALIGN_TOP` | y from the top |
| `VERTICAL_ALIGN_BOTTOM` | y from the bottom; **negative y = offset up from bottom** |
| `..._CENTER` / `..._FULLSCREEN` | from center / stretch full screen |

A panel hugging the **top-right** corner, 8px in:
`rect -148 28 140 152 HORIZONTAL_ALIGN_RIGHT VERTICAL_ALIGN_TOP`

> **Text size:** Quake docs say `textscale 1.0` = 48px. In CoD4 the HUD fonts are different - real HUD text is **`0.25`-`0.35`**. Do not use `1.0`, it is gigantic.

---

## Your first element

A static text label inside a menu:

```c
itemDef {
    rect        20 20 200 20 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    forecolor   1 1 1 1            // RGBA, each 0..1
    textfont    UI_FONT_DEFAULT
    textscale   0.3
    textalign   ITEM_ALIGN_LEFT    // 0 left / 1 center / 2 right
    textaligny  14                 // baseline offset from top of rect
    text        "Hello World"
    visible     1
    decoration                     // passive - no mouseover, no click
}
```

> **Always add `decoration` to HUD elements.** Without it, the item plays a mouseover sound and grabs the cursor. HUD overlays are passive.

A filled background box:

```c
itemDef {
    style       WINDOW_STYLE_FILLED   // FILLED = solid backcolor
    rect        16 16 220 60 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.65            // semi-transparent black
    visible     1
    decoration
}
```

`style` values: `WINDOW_STYLE_EMPTY` (no fill), `WINDOW_STYLE_FILLED` (solid `backcolor`), `WINDOW_STYLE_SHADER` (image via `background "shader"`).

---

## Making it dynamic: `exp` and `visible when`

Static text is rare. The power of `.menu` is **`exp`** - runtime expressions that read live values.

```c
itemDef {
    rect        20 20 200 20 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    forecolor   1 0.8 0 1
    textfont    UI_FONT_DEFAULT
    textscale   0.3
    textaligny  14
    exp text( dvarString("ui_status") )         // text comes from a dvar
    visible when( dvarInt("ui_show") == 1 )      // only visible when dvar == 1
    decoration
}
```

GSC side - one line changes what the player sees:

```c
player setClientDvar("ui_status", "^2Bet won!");
player setClientDvar("ui_show", 1);
```

### Functions you can use inside `exp`

| Function | Returns |
|---|---|
| `dvarInt("n")` `dvarFloat("n")` `dvarString("n")` | a dvar value |
| `localVarString("n")` `localVarInt("n")` | a client local var |
| `stat(N)` | player stat #N (rank, xp, ...) |
| `tableLookup("file.csv", keyCol, key, retCol)` | a cell from a `.csv` |
| `milliseconds()` | engine time (for animation) |
| `sin(x)` `cos(x)` | trig in radians (pulsing/flash effects) |
| `+ - * /`, `( )`, string `+` | arithmetic and string concat |

Fields `exp` can drive: `rect X(...)`, `rect Y(...)`, `rect W(...)`, `rect H(...)`, `text(...)`, `material(...)`.

---

## Recipe: a status panel with states

A common pattern - one panel, several looks driven by a single integer dvar (`0=hidden 1=active 2=won 3=lost`). Each layer is its own `itemDef` with a `visible when(==N)`. GSC flips one dvar; the engine shows the right layer.

```c
// Background - visible whenever the panel is up (state != 0)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        8 28 220 52 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.65
    visible     when( dvarInt("ui_panel_s") != 0 )
    decoration
}
// Gold border - only in "active" state (1)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        8 28 220 52 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0           // transparent fill
    border      1                 // full border (WINDOW_BORDER_FULL)
    bordersize  0.4
    bordercolor 1 0.8 0 1
    visible     when( dvarInt("ui_panel_s") == 1 )
    decoration
}
// Header text - reads its label from a dvar
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

## Recipe: a progress / vote bar

Width is a formula in `exp rect W(...)`. Two boxes: a dim track and a bright fill that grows.

```c
// Track (background of the bar)
itemDef {
    style       WINDOW_STYLE_FILLED
    rect        20 60 200 8 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0.2 0.2 0.25 1
    visible     1
    decoration
}
// Fill - width = 200 * (votes / maxVotes)
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

## Recipe: a repeating row (use a macro)

A leaderboard or vote list is the same row N times. Write it once as a `#define` macro, call it per row. This is also how you keep dozens of rows manageable.

```c
// One row = a background + 3 dvar-driven columns.
// Backslash continues every line; the whole macro is one logical block.
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

// Call it once per row - columns come from dvars your GSC sets:
LB_ROW(25, 120, 330, 15, "01", dvarString("lb_1_name"), dvarString("lb_1_time"))
LB_ROW(25, 140, 330, 15, "02", dvarString("lb_2_name"), dvarString("lb_2_time"))
LB_ROW(25, 160, 330, 15, "03", dvarString("lb_3_name"), dvarString("lb_3_time"))
```

> Columns are positioned with `(x+80)`, `(x+280)` - arithmetic is allowed anywhere in a `rect`. Use `#idx` (preprocessor stringify) in a `name` to make unique names per row: `name "row"#idx`.

---

## A complete menu shell

When you need a whole new screen (not just a HUD panel), this is the skeleton:

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

        itemDef { /* ... your items ... */ }
    }
}
```

---

## Loading a menu in-game

For a HUD overlay panel you just `#include` it into your persistent in-game HUD menu and it shows via `visible when(...)`. For a **standalone screen** (shop, picker) you load and open it yourself:

1. Put the file in `ui_mp/scriptmenus/yourmenu.menu`
2. Register it in `mod.csv`: `menufile,ui_mp/scriptmenus/yourmenu.menu`
3. Make sure the build `.bat` copies UI: `xcopy ui_mp ..\..\raw\ui_mp /SY`
4. **Precache the file AND every `menuDef` name inside it** (both count toward the ~32 limit):

```c
init()
{
    precacheMenu("yourmenu");   // the FILE name
    precacheMenu("home");       // a menuDef name inside the file
}
```

5. Open it on a player: `player openMenu("home");`

> If you get "cannot find file", make the `menuDef` name match the file name.
>
> ⚠️ **`openMenu` closes the player's chat input.** Never open a menu mid-gameplay as a side effect - it interrupts anyone typing. Use it only for deliberate screens the player asked for.

---

## Managing the menu limit

The engine caps how many menus exist at once (**~32**, counting your `precacheMenu` calls **and** the stock menus). Big UIs (customization screens, shops) hit this fast. Two patterns keep you under it:

**1. One screen, many pages via a dvar (instead of separate page menus).**
A common trap is splitting a long list into `mymenu_page_2`, `mymenu_page_3` files - each one a separate menu that eats a precache slot. Instead, keep one menu and switch pages with a dvar:

```c
onOpen { exec "set ui_page 0" }

// Page 1 items: visible when( dvarInt("ui_page") == 0 )
// Page 2 items: visible when( dvarInt("ui_page") == 1 )
// Next / Prev buttons:  action { exec "set ui_page 1"; }   /  { exec "set ui_page 0"; }
```

Three "pages" that were three menus (3 slots) become one menu (1 slot).

**2. A scrollable list (`ITEM_TYPE_LISTBOX`)** when the engine can feed the data - one menu shows an unlimited list with no pages at all (see List boxes below).

> If you are adding a new menu and something stops working, you are probably over the limit. Free a slot first: collapse paginated menus (pattern 1), or remove stock menus your mod never uses by shipping your own `menus.txt` (test carefully - some are needed by the client).

---

## Interactive menus (buttons that talk back to GSC)

A HUD panel is passive. A **screen** (shop, vote, picker) has buttons that need to tell your script what was clicked. That is `scriptMenuResponse`:

```c
// In the .menu - a clickable button:
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
// In GSC - catch the response:
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

> Buttons (no `decoration`) are the one place you DO want mouseover/click. Keep `decoration` for everything passive.

---

## Styling buttons (hover, focus, theming)

A button is normally **two itemDefs stacked** in the same rect: a background box (so you can color/border it and animate it on hover) and a text item that is the actual `ITEM_TYPE_BUTTON`.

```c
// 1) Background box - named so hover scripts can recolor it
itemDef {
    name        "btn_bg_play"
    style       WINDOW_STYLE_FILLED
    rect        40 60 160 24 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    backcolor   0 0 0 0.4
    border      1
    bordercolor 0.5 0.5 0.5 0.3
    decoration                       // bg is passive; the text item handles clicks
}
// 2) Text + click target on top
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

Two ways to change colors on hover:
* **`setitemcolor "name" backcolor R G B A`** - recolor *another* item by name (used above to light up the bg box).
* **`setColor forecolor R G B A`** / **`setColor bordercolor ...`** - recolor *the current* item (handy for a glowing border on hover).

`menuDef` also has **`focuscolor R G B A`** - the text color an item takes while focused (keyboard/mouse), applied automatically without a script.

### Make it reusable - one button macro

Defining a button as a `#define` macro keeps every button identical and lets you re-skin the whole UI by editing one place. The `id` param (with `#id` or `"..."id` concatenation) gives each instance unique element names.

```c
// Theme colors in one spot - change these to re-skin every button.
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

// Use it:
UI_BUTTON( "play", 40, 60, 160, 24, "Play",     scriptMenuResponse "play";,    1 )
UI_BUTTON( "quit", 40, 90, 160, 24, "Quit",     close self;,                   1 )
```

> Keep all your color `#define`s in one include and every button/panel reads from them. Re-skinning the mod's UI then means editing a handful of values, not hunting through every file.

---

## Auto-layout lists (declarative macros)

The [repeating row](#recipe-a-repeating-row-use-a-macro) recipe still made you type `x` and `y` for every row. For a real list (a menu of buttons, a customization grid) you want to write **only the content** and have positions compute themselves from an index. This is the most powerful `.inc` pattern: build a small set of layout macros once, then declare the whole list by calling one macro per item.

### The idea: position is a function of the index

Define the geometry once, then derive each item's rect from its index `idx`:

```c
// --- layout constants (one place to tune the whole list) ---
#define LIST_X            120
#define LIST_Y            100
#define LIST_W            170
#define LIST_H            25
#define LIST_GAP          (LIST_H + 5)          // vertical step
#define LIST_PER_COL      24                     // wrap after this many

// --- index -> position (the engine never sees idx; the preprocessor expands it) ---
#define LIST_ROW( idx )   ( idx % LIST_PER_COL )
#define LIST_YPOS( idx )  ( LIST_Y + LIST_GAP * LIST_ROW( idx ) )
#define LIST_RECT( idx )  LIST_X LIST_YPOS( idx ) LIST_W LIST_H HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
```

Now an item macro that takes only `idx` + content:

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

The entire list is then just declarations - no coordinates, no copy-paste:

```c
LIST_BUTTON( 0, "Play",      scriptMenuResponse "play"; )
LIST_BUTTON( 1, "Options",   open "options"; )
LIST_BUTTON( 2, "Customize", open "customize"; )
LIST_BUTTON( 3, "Quit",      close self; )
// add item 4, 5, 6 ... they place themselves automatically
```

### Grid (rows + columns)

Make `idx` wrap into columns by deriving both row and column from it:

```c
#define G_COLS            4
#define G_ROW( idx )      ( idx / G_COLS )           // integer divide
#define G_COL( idx )      ( idx % G_COLS )
#define G_X( idx )        ( LIST_X + G_COL( idx ) * (LIST_W + 6) )
#define G_Y( idx )        ( LIST_Y + G_ROW( idx ) * (LIST_H + 6) )
#define G_RECT( idx )     G_X( idx ) G_Y( idx ) LIST_W LIST_H HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
```

### Layer your macros (the real power)

Good `.inc` files stack macros so each layer adds one concern. A common arrangement:

1. **Primitives** - tiny reusable builders: `CREATE_SHADER(rect, image, color)`, `CREATE_TEXT(rect, str, color, scale, align)`, `CREATE_BUTTON(rect, label, scale, action)`. Each is one `itemDef`. Give them `_VIS` / `_EX` variants (extra `visible` / extra-code params) layered with defaults:
   ```c
   #define CREATE_SHADER(rect, img, col)            CREATE_SHADER_VIS(rect, img, col, 1)
   #define CREATE_SHADER_VIS(rect, img, col, vis)   CREATE_SHADER_EX(rect, img, col, vis, ;)
   #define CREATE_SHADER_EX(rect, img, col, vis, extra) \
       itemDef { rect rect  style WINDOW_STYLE_SHADER  forecolor col \
                 exp material(img)  visible when(vis)  extra }
   ```
2. **Index → geometry** - `LIST_RECT(idx)` as above.
3. **Styled widget** - combine primitives at an index: a themed button = background shader + accent strip + text, all from `idx`.
4. **High-level item** - what you actually call: `LIST_BUTTON(idx, label, action)`.

Because every layer is a `#define`, the engine only ever sees the final flat `itemDef`s. You get clean, declarative menu source that is trivial to reorder, recolor, or extend - change a constant in layer 1 and the whole list reflows.

> Keep the primitive builders and color `#define`s in a shared `.inc` (e.g. `includes/utility.inc`) and your list/grid macros in another (e.g. `includes/mylist.inc`). Menus then `#include` both and read like a list of content, not a wall of coordinates.

### Item widgets with state (locked / selected / level)

Real list items often need more than a label - a lock icon, a "level required" tag, a "currently selected" highlight. Fold all of it into the item macro so each call stays a one-liner. Use `visible when(...)` on the extra layers and read the data with `tableLookup` / a dvar:

```c
// helper predicates (define once)
#define ITEM_LOCKED( table, id )  ( tableLookup(table, 0, id, 3) > stat(2350) )   // required rank > player rank
#define ITEM_LEVEL( table, id )   tableLookup(table, 0, id, 3)

#define UNLOCK_BUTTON( idx, table, id ) \
    /* bg + accent strip from idx */ \
    CREATE_SHADER( LIST_RECT(idx), "ui_menu_button", 0 0 0 0.5 ) \
    /* label pulled from the table, click sends the item id to GSC */ \
    CREATE_BUTTON_EX( LIST_RECT(idx), tableLookup(table,0,id,4), 0.3, scriptMenuResponse id, 1, textalignx 10 textaligny 19 ) \
    /* red "(level)" tag - only when locked */ \
    CREATE_TEXT_VIS( UNLOCK_TAG_RECT(idx), "^1(" + ITEM_LEVEL(table,id) + ")", 1 1 1 1, 0.25, 2, ITEM_LOCKED(table,id) ) \
    /* lock icon overlay - only when locked */ \
    CREATE_SHADER_VIS( UNLOCK_ICON_RECT(idx), "menu_lock", 1 1 1 1, ITEM_LOCKED(table,id) )
```

**Selected highlight** is just another conditional layer comparing the item's index to a dvar:

```c
// normal accent vs "selected" accent, swapped by a dvar
CREATE_SHADER_VIS( FOOTER_RECT(idx), "ui_footer", 0.6 0.6 0.6 1, dvarInt("ui_selected") != idx )
CREATE_SHADER_VIS( FOOTER_RECT(idx), "ui_footer", 1 0.8 0 1,     dvarInt("ui_selected") == idx )
```

GSC sets `ui_selected` when the player picks an item (via the `scriptMenuResponse`), and the highlight moves with no extra menu code.

> A per-item **image** can come from the index too: `exp material( "ui_icon" + idx )` gives item 0 `ui_icon0`, item 1 `ui_icon1`, etc. - one macro, unlimited icons.

### Header, footer, and page buttons as macros

The same approach scales to whole menu regions. Define `HEADER` (player name, rank icon, an `exp rect W(...)` XP bar), `FOOTER` (message-of-the-day with `autowrapped` text), and prev/next page buttons once, then drop them into any page:

```c
#define PAGE_NAV( prevMenu, nextMenu ) \
    CREATE_BUTTON_EX( 120 360 50 17 0 0, "@MENU_PAGE_PREVIOUS", 0.26, close self; open prevMenu, 1, ; ) \
    CREATE_BUTTON_EX( 250 360 50 17 0 0, "@MENU_PAGE_NEXT",     0.26, close self; open nextMenu, 1, ; )
```

(`@NAME` is a localized string from your language files.) Build a multi-page screen by giving each page the same `HEADER` / `FOOTER` / `PAGE_NAV` and only changing the item list - every page looks identical for free.

---

## Keyboard shortcuts (`execKey`)

Inside a `menuDef` you can bind a key to actions - great for quick-menus (press a number to pick an option):

```c
execKey "1" { scriptMenuResponse "option1"; close self }
execKey "2" { scriptMenuResponse "option2"; close self }
execKey "r" { exec "cmd callvote map_restart"; close self }
```

The handler runs the moment the key is pressed while the menu is open. Combine with `scriptMenuResponse` (see above) so GSC knows which key was chosen.

---

## List boxes (engine-fed lists)

For long, scrollable lists the engine can fill (map lists, player lists), use `ITEM_TYPE_LISTBOX` with a `feeder`:

```c
itemDef {
    type          ITEM_TYPE_LISTBOX
    rect          40 60 240 200 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    feeder        FEEDER_ALLMAPS        // engine supplies the rows
    elementtype   LISTBOX_TEXT          // or LISTBOX_IMAGE
    elementheight 25
    columns       1 2 190 25            // count, then [offset width maxChars] per column
    forecolor     1 1 1 1
    outlinecolor  1 1 1 0.2             // selection highlight - keep it very transparent
    doubleclick   { play "mouse_click"; uiScript StartServer; }
}
```

`feeder` values are engine-defined (e.g. `FEEDER_ALLMAPS`, `FEEDER_PLAYER_LIST`, `FEEDER_LEADERBOARD`). The engine owns the data and the current selection.

---

## Building a settings / options screen

A clean pattern for an in-game options screen: **one menu, several tabs switched by a dvar** - no extra menus needed.

```c
// In onOpen pick a default tab:
onOpen { exec "set ui_subtab 0" }

// Tab headers - clicking sets the dvar:
//   (use your own button macro / itemDef with type ITEM_TYPE_BUTTON)
//   action { exec "set ui_subtab 0"; }   -> "Visual"
//   action { exec "set ui_subtab 1"; }   -> "Binds"

// Options appear only when their tab is active, via visible when:
itemDef {
    type        ITEM_TYPE_BUTTON
    rect        70 130 135 23 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "Fullbright"
    textscale   0.3
    textaligny  16
    forecolor   1 1 1 1
    visible     when( dvarInt("ui_subtab") == 0 )
    action      { scriptMenuResponse "toggle_fullbright"; }   // GSC flips the dvar
}
itemDef {
    type        ITEM_TYPE_BUTTON
    rect        70 130 135 23 HORIZONTAL_ALIGN_LEFT VERTICAL_ALIGN_TOP
    text        "125 FPS"
    textscale   0.3
    textaligny  16
    visible     when( dvarInt("ui_subtab") == 1 )
    action      { exec "com_maxfps 125"; }                    // direct console command
}
```

Two kinds of option button:
* **Toggle a setting** → `action { scriptMenuResponse "name"; }` and let GSC change the dvar (works for server-side or protected dvars).
* **Run a command** → `action { exec "command"; }` for plain client commands (`com_maxfps`, `toggle ...`).

> **Reuse the stock screens.** You do not have to rebuild the full Controls / Options pages. From your menu you can `open "main_controls"` / `open "main_options"` to hand off to the built-in screens, and theme them by overriding the colors they read. Build a custom screen only for mod-specific options.

To match your mod's look, set your colors once (e.g. with `#define` for border / background / text) and reuse them across every button macro, so the whole screen is consistent and easy to re-skin later.

---

## Pitfalls

| Pitfall | Result | Fix |
|---|---|---|
| `textscale 1.0` (from Quake docs) | text is huge | CoD4 HUD uses `0.25`-`0.35` |
| Missing `decoration` | mouseover sound, item grabs focus | add `decoration` |
| `WINDOW_STYLE_FILLED` with no `backcolor` | nothing shows | set `backcolor` RGBA |
| `WINDOW_STYLE_SHADER` with no `background` | nothing / error | set `background "shader"` |
| `itemDef` inside `itemDef` | parse error | items go directly in `menuDef` |
| Two color codes back-to-back in text (`^8^7`) | text fails / shows literally | build the string with single `^N` codes |
| dvar not set before the menu draws | `exp` reads `""` / `0` | set the dvar in GSC **before** showing the panel |
| Over ~32 precached menus | menu will not load | remove/merge an unused menu |
| Over ~31 `newHudElem` per client | extra HUDs never render | move the UI to a `.menu` overlay (this whole page) |

---

## The GSC ↔ menu bridge in one place

```c
// Server-side GSC pushes data; the menu reads it via exp / visible when.
player setClientDvar("ui_panel_s", 1);            // toggle a panel  (visible when ==1)
player setClientDvar("ui_panel_h", "Round 3");    // panel text      (exp text)
player setClientDvar("ui_panel_y", 28);           // panel position  (exp rect y)
// For everyone: loop over players and setClientDvar each, or setDvar for a global value.
```

Convention: prefix your UI dvars with `ui_` and keep names short, so they are easy to spot and do not clash.

---

> This page is the practical starter. The authoritative keyword list lives in CoD4's engine source (`menu.c`) and the [COD4 Menu Builder](https://github.com/SheepWizard/COD4-MENU-BUILDER) wiki - both good next stops when you need a property this page does not cover.
>
> 🏠 [Back to Home](/en/) · [⬅ For Modders](/en/modding)

---

> ➡️ **Next:** [Menus II — engine internals, assets & pitfalls](/en/modding-menus-advanced.md) — hard limits (256 itemDefs!), `exp` animations, IWI/material formats, listboxes, stock-menu overrides.
