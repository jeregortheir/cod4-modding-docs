# 🧪 Menus II — engine internals, assets & pitfalls

Everything on this page was learned the hard way — by shipping menus and
watching them break. Read [Custom menus](/en/modding-menus.md) first for
the basics.

> 💡 Most of what's below is much easier with a live previewer:
> **[CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)** —
> a browser tool that renders `.menu` files like the engine does, validates
> them (Menu Doctor) and exports IWI textures **with** compiled material
> files.

---

## How menus really load

This trips up everyone, so let's be precise:

| Menu kind | How it loads | What you need |
|---|---|---|
| Client menu (main menu, options…) | compiled into `mod.ff` | `menufile,ui_mp/x.menu` in mod.csv |
| Script menu (opened by GSC) | compiled into `mod.ff` **and** precached | `menufile,…` + `precacheMenu()` in GSC |

Key facts:

- **Loose `.menu` files and `menus.txt` edits do nothing by themselves** —
  if your change doesn't show up, it's because the compiled `mod.ff` still
  has the old version. Rebuild the fastfile.
- **Same-name override wins.** If your `mod.ff` contains a `menuDef` named
  `main_text` (or `player_profile`, `quit_popmenu`, …), it replaces the
  stock one. This is how you reskin built-in screens without touching
  anything else.
- Stock menus often declare names **without quotes** (`name pc_join_unranked`).
  If you scan files for menu names, handle both forms.
- Materials referenced by a compiled menu (`background "my_mat"`,
  `exp material(…)`) become **automatic fastfile dependencies** — you do
  *not* need a `material,…` line in mod.csv for them. But if such a
  material is broken or missing at link time, the whole build errors.

---

## Hard engine limits (memorize these)

| Limit | Value | Symptom when exceeded |
|---|---|---|
| itemDefs per menuDef | **256** | item #257: `unknown menu keyword {` + error cascade |
| single `.menu`/`.inc` file | **32 KB** | parse errors at the cut-off point |
| GSC `precacheMenu()` slots | ~32 | later precaches fail; keep script menus lean |
| single image allocation | **~8 MB decoded** | `Needed to allocate at least 8.0 MB to load images` |
| clickable area (standard menuDef) | x ≈ **75–565** | buttons near screen edges have dead zones on 16:9 |

Practical notes:

- Count itemDefs **after macro expansion** — a 12-row list built from an
  18-item row macro is already 216 items.
- The 8 MB image limit means a fullscreen uncompressed background must be
  **split into tiles** (e.g. four 1024×512 pieces drawn as four itemDefs).
- Keep every clickable (`type 2`) item inside x 75–565; decorations may go
  wider.

---

## Text quirks

- `\n` inside a string **does** break lines in-game:
  `text "Line one\nLine two"`.
- **Never use an em-dash (—)** in menu text — the engine font renders it
  as garbage (`â`). Use `-`.
- On CoD4X clients, **`^8` inside menu text renders as the player's
  favorite color** — the only way to get a per-player color in a menu.
  `forecolor` / `bordercolor` are compiled constants and can never be
  per-player.
- `exp forecolor A(…)` (alpha) works; `exp forecolor R/G/B` is a **parse
  error**. Color animation = cross-fading two differently-colored items
  with alpha.

### The button-label pitfall

Text placed directly inside a clickable item often doesn't render at all.
The reliable pattern is: invisible click box + separate decoration label,
recolored on hover via `setitemcolor`:

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

Also: the engine draws a white "focus" glow on the last-clicked item —
kill it with `focusColor 0 0 0 0` in the menuDef.

---

## Animations with `exp` (no GSC needed)

`exp` expressions are evaluated every frame, and the expression language
has a clock: `milliseconds()`, plus `sin`, `cos`, `min`, `max`, `abs`.
Animatable targets: **alpha** (`forecolor A`), **position/size**
(`rect X/Y/W/H`), **text**, **material**.

**Pulse (breathing alpha):**

```menu
exp forecolor A( 0.05 + 0.05 * sin( milliseconds() / 900 ) );
```

**One-way motion** (a sweep that never visibly "returns"): drive position
with `sin`, and hide the return half of the cycle by gating alpha with
`cos` of the same argument:

```menu
exp rect Y( ( ( sin( milliseconds() / 4500 ) + 1 ) / 2 ) * 478 );
exp forecolor A( max( 0, cos( milliseconds() / 4500 ) ) * 0.1 );
```

**Hover-driven animated effects:** `mouseenter`/`mouseexit` can run
`setdvar`, and animated items can be gated on that dvar — so hovering a
button can *enable extra animated layers*:

```menu
mouseenter { setdvar ui_fx_boost 1; }
mouseexit  { setdvar ui_fx_boost 0; }
// on the animated item:
visible when( dvarint( "ui_fx_boost" ) == 1 )
```

### The alpha-blending physics you must know

- Overlaying an image **on itself** with alpha does *nothing*:
  `c*(1-a) + c*a = c`. A "brightening" copy of the same texture is
  mathematically invisible.
- **Brightening** requires a *different* source: a brighter variant of the
  image (cross-fade two images), a white/tinted fill, or an additive
  material.
- **Darkening always works**: a black fill with animated alpha.

---

## Textures: the IWI format

An `.iwi` (CoD4, version 6) is a tiny header + pixel data:

| Offset | Size | Meaning |
|---|---|---|
| 0 | 3 | magic `IWi` |
| 3 | 1 | version = **6** |
| 4 | 1 | format: `0x01` RGBA32, `0x0B` DXT1, `0x0C` DXT3, `0x0D` DXT5 |
| 5 | 1 | flags: `0x02` = no mipmaps |
| 6 | 2+2+2 | width, height, depth (u16 LE) |
| 12 | 4×4 | sizes per picmip: `[0]` = whole file, `[1..3]` = data size |
| 28 | … | pixel data (RGBA32 = BGRA byte order, top-down) |

Gotchas that produce "file won't load in game":

- flags `0x00` with no mipmap data present — the engine expects mips and
  reads garbage. For UI art always write `0x02`.
- Uncompressed RGBA32 looks best for menu gradients (DXT1 causes banding),
  but respect the **8 MB decode limit** — tile big backgrounds.
- Non-power-of-two sizes work for UI images on CoD4X.

---

## Materials without Asset Manager

The compiled material files the linker consumes (`materials/<name>`,
no extension) are small binaries with a fixed 76-byte header followed by
strings. The useful facts:

- Header holds **string offsets** (`@0` = material name, `@4` = image
  name, `@64` = the literal `colorMap`, `@52/@60` = techset `2d`), so any
  name length is fine if you recompute them.
- **Blend mode is two bytes at offset 26–27**: `00 01` = normal blend,
  `40 00` = additive.
- No image dimensions are stored — one template fits any texture size.
- `material_properties/` files are **not needed** for 2D materials.
- Cheapest route by hand: copy a known-good 2D material and patch the two
  name strings (keep lengths identical). Or let
  [CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)
  generate the IWI **and** the material in one click.

---

## Listboxes & feeders (server list, profiles…)

The engine's scrollable lists are driven by *feeders*. The constants live
in `ui/menudefinition.h` (included by `ui/menudef.h`): `FEEDER_SERVERS`,
`FEEDER_PLAYER_PROFILES`, `FEEDER_MODS`, ownerdraws like `UI_NETSOURCE`,
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

- `columns N` then N triples of `x width maxChars` (x relative to the
  listbox).
- `elementwidth` controls the **selection bar width** — set it to the
  inner width or the highlight won't line up.
- Per-element `textalign` centering is ignored; design for left-aligned
  text with `textalignx` padding.
- `noscrollbars` does **not** exist in PC CoD4 — the stock scrollbar
  always draws. Hide it by covering that strip with a solid decoration
  drawn *after* the listbox (draw order = file order), then draw your
  frame lines on top. Mouse-wheel scrolling still works.
- Conditional buttons around lists use `dvarTest` + `hideDvar`/`showDvar`.

When you reskin stock screens (profile select, server browser…), keep
every `uiScript` call **verbatim** — that's the functionality; you're only
changing the chrome. And keep every popup the engine opens **by name**
(e.g. `profile_create_popmenu`, `password_popmenu`) defined somewhere, or
those flows dead-end.

---

## Assorted engine facts

- **`open X` inside the main menu's `onOpen` does not work at boot** —
  the engine is still activating `main_text`; don't build "bounce"
  redirects there. (`close self` there is even worse: black screen.)
- A menu used both in-game and out-of-game can gate items on the engine
  dvar **`cl_ingame`** (`1` only while connected).
- `cg_fov` / `cg_fovscale` are cheat-protected — menu-side `setdvar`/
  `exec` on them silently fails; only server-side GSC `setclientdvar`
  works. (`cg_thirdperson*` is fine menu-side.)
- On CoD4X clients, the main-menu branding text and build number
  (bottom-right) are drawn by the client, anchored to the build-number
  position. You can push the whole block off-screen from your menu:

  ```menu
  onOpen { setdvar ui_buildSize 0; setdvar ui_buildLocation "-1000 -1000"; }
  ```

- Macros: inside a `#define`, keywords with optional trailing values (like
  `rect`) must list **all six** values (`rect x y w h halign valign`) —
  the preprocessor joins lines, so the parser can't rely on line ends.
- Macro arguments can't contain commas; multi-statement actions separated
  by `;` are fine.

---

*Want to verify any of this quickly? Load your menu into
[CoD4 Menu Builder](https://github.com/jeregortheir/cod4-menu-builder)
and run the Menu Doctor.*
