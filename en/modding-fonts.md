# 🔤 Custom fonts & chat emojis

CoD4 has no emoji system. But you can put **any image inline in chat text** - and every player sees it **without touching their game install**. No client patch, no download instructions, no "install this pack first".

This chapter shows how. It is general CoD4 knowledge and works on any mod.

> **What you get:** `:skull:` typed in chat becomes a real icon. Any size you want, any position, tinted by `^1`/`^2` colour codes like normal text.

---

## How it actually works

CoD4 draws text by looking up each byte in a **glyph table**, which tells it *where* in a shared **texture atlas** to sample and *how big* to draw it.

So an inline image needs three things to agree:

| # | Layer | What it holds | Where it lives | How you ship it |
|---|---|---|---|---|
| 1 | **Pixels** | the drawing | `images/gamefonts_pc.iwi` (512×1024, DXT5) | any `.iwd` in your mod |
| 2 | **Glyph table** | size, position, UV | `raw/english/fonts/*` → `mod.ff` | `mod.csv` + rebuild |
| 3 | **Trigger → byte** | `:skull:` → `0xD0` | your engine / GSC | server-side |

The trick: pick a character **nobody ever types** (like `Ð` or `¼`), repaint its cell in the atlas, and enlarge its glyph entry. When the server sends that byte, the client draws your image.

---

## Prerequisite: you need a server-side substitution

!> **Layers 1 and 2 alone give you nothing.** They make byte `0xD0` *look* like a skull. Something still has to turn the player's typed `:skull:` **into that byte** - and stock CoD4 will not do it for you.

This is the part people miss, so be clear about it before you start:

- The client only ever draws **bytes**. It has no idea what `:skull:` means.
- Vanilla player chat is broadcast straight from the game module. There is no stock hook where you can rewrite the text on its way out.
- So the replacement has to happen **server-side, at send time**, in whatever code path your chat actually travels through.

**In practice that means a custom server build** (or any setup where you control the final send). If your mod already re-emits chat through the server's own `say` path rather than letting it broadcast natively, that is where the substitution belongs.

A minimal substitution is just an in-place string replace, applied right before the message goes out:

```c
/* longest triggers first, or ":)" would eat the prefix of ":)foo:" */
static const char *triggers[] = { ":skull:", ":heart:", ":)" };
static const char  glyphs[]   = { (char)0xD0, (char)0xA9, (char)0xC2 };

while ((p = strstr(s, triggers[m])) != NULL) {
    *p = glyphs[m];
    memmove(p + 1, p + strlen(triggers[m]), strlen(p + strlen(triggers[m])) + 1);
}
```

?> **Keep triggers ASCII all the way through your scripting layer**, and insert the high byte only at the last step. High bytes survive the wire fine - `I_CleanChar` only maps `146 → 39`, and the reliable-command encoder leaves them alone - but the fewer layers they pass through, the fewer surprises.

**Without this layer, players simply see the literal text `:skull:`.** Everything below assumes you have it.

---

## The one thing that makes this possible

> **`mod.ff` overrides the base game's fonts.**

Add this to your `mod.csv`:

```
font,fonts/normalfont
```

Rebuild `mod.ff`, and the client uses **your** glyph table instead of the stock one. Players download `mod.ff` automatically when they join - that is the whole delivery mechanism.

?> Other fastfiles carry fonts too, and some of them load earlier - so they look like the more direct target. They are not: `mod.ff` wins anyway, and it is the only one players fetch on their own. Patch fonts here and nowhere else.

---

## Which font renders what

This is the part that costs people days. CoD4 has seven fonts and the names lie.

| Font | pixelHeight | Renders |
|---|---|---|
| **normalFont** | 16 | **chat**, scoreboard, most HUD text |
| consoleFont | 16 | the console (`~`) - **not** chat |
| smallFont | 10 | small HUD labels |
| boldFont | 16 | |
| bigFont | 24 | |
| objectiveFont | 35 | |
| extraBigFont | 48 | |

**Chat is `normalFont`.** Not `bigFont`, not `consoleFont`.

### How to verify this yourself

Do not guess and do not measure sizes by eye - both fail. Give **each font a different shape** under the same letter, then read the screen:

```
consoleFont : 'a' -> heart
normalFont  : 'a' -> smiley
boldFont    : 'a' -> skull
bigFont     : 'a' -> trophy
```

Type `a` in chat. Whatever shape appears names the font in one shot. This test cannot give an ambiguous answer, which is exactly why it is worth the five minutes.

---

## The glyph table format

`raw/english/fonts/<name>` - a flat binary, no compression:

```
0:   u32  glyphsEnd     (= 16 + glyphCount * 24)
4:   u32  pixelHeight   (line height - chat font: 16)
8:   u32  glyphCount    (254 for consoleFont, 191 for the rest)
12:  u32  stringOffset
16:  glyph entries, 24 bytes each
```

Each glyph:

| Offset | Type | Field |
|---|---|---|
| 0 | u16 | `letter` - character code |
| 2 | s8 | `x0` - horizontal offset from the pen |
| 3 | s8 | **`y0` - top edge, relative to baseline** |
| 4 | s8 | `dx` - advance (how far the pen moves) |
| 5 | u8 | **`pw` - width** |
| 6 | u8 | **`ph` - height** |
| 8..24 | 4× float | UV rect (s0, t0, s1, t1) |

!> **Glyphs are not sorted.** The order is 32..127, then 1..31, then 128..255. Never assume an index - find the table by scanning for `letter == 32` followed by `letter == 33`.

### Two rules you cannot break

**1. `pw`/`ph` must equal the UV span in texels.**
If your cell is 32×32 in the atlas but you set `pw=20`, the engine **crops** instead of scaling - you get torn fragments. Give each font its own cells at its own size.

**2. Size and position are independent.**
`pw`/`ph` control how big. `y0` controls where. Confusing them wastes hours (see below).

---

## Positioning: the mistake everyone makes

A glyph is anchored by its **top edge** (`y0`), and text sits on a baseline. If you align an emoji's bottom to the baseline, it grows **upwards only**:

```
letter 'A' :  8x10, y0=-12   ->  spans -12 .. -2
emoji 20px :        y0=-22   ->  spans -22 .. -2     <- sticks 10px above the text
```

The emoji towers over the line with nothing below it. Shrinking it (32 → 26 → 20) only trims the top - the anchor never moves, so it keeps looking wrong and you conclude "nothing changed".

**Fix: centre it on the letters.**

```python
a_top    = glyph['A'].y0            # -12
a_bottom = a_top + glyph['A'].ph    #  -2
center   = (a_top + a_bottom) // 2  #  -7

y0 = center - emoji_height // 2     # emoji centred on the text
```

For a 20px emoji that gives `y0 = -17`, spanning -17..+3 - 5px above the caps, 5px below the baseline. Like a real emoji in a sentence.

---

## Picking bytes

Use characters a player will **never type**:

- Good: `© ¼ ½ ¾ Æ Ð À Á Â Ã Ä` and most of `0xA0-0xFF`
- **Avoid** anything in your players' language. For Polish servers that means CP1250: `ą ć ę ł ń ó ź ż` - a player typing `źle` would fire your emoji.

The byte survives the whole pipeline: `I_CleanChar` only maps `146 → 39`, and the reliable-command encoder does not touch high bytes.

---

## Colour tinting

The engine **multiplies** the text colour by the glyph colour:

| Glyph in atlas | Result |
|---|---|
| **white** | `^1` → red, `^2` → green. **Tintable.** |
| **coloured** (photo emoji) | `^2` × red ≈ black. **Tinting is dead.** |

So: draw tintable emojis **white**, keep dark details dark (they stay dark under any tint - black × colour = black).

### Default colours without losing tintability

Inject a colour code before the glyph, **unless the player supplied one directly before the trigger**:

```c
if (tints[m] && !(p >= s + 2 && p[-2] == '^' && p[-1] >= '0' && p[-1] <= '?')) {
    /* find last active colour to restore afterwards */
    ...
    p[0] = '^'; p[1] = tints[m]; p[2] = glyph; p[3] = '^'; p[4] = restore;
}
```

Result: `<3` is red, `^2<3` is green, and `^2hello <3 world` keeps `world` green.

!> The check is **adjacency**, not presence. `^2 <3` (with a space) still gets the default colour - the code must touch the trigger.

!> This grows the string (2 bytes → 5). Pass the buffer size and degrade to a plain glyph when it would not fit, or you will smash the stack.

---

## The texture atlas

`images/gamefonts_pc.iwi` - 512×1024, **DXT5**, shipped in any mod `.iwd`. Mod IWDs beat the base game's in the search path, so no fastfile rebuild is needed for pixels.

### Three traps

**1. Mips are stored smallest-first.** The offsets in the header are each mip's **end**. The base level starts at `filesize - W*H`, **not** at byte 28. Reading from 28 gives you a small mip and your drawing lands in the wrong glyphs.

**2. Paint every mip.** The GPU picks a level by render size. There are 8 (512×1024 down to 4×8). At mip 3-4 a 32px emoji is 4×4 pixels - a coloured blob. That is normal and unavoidable.

**3. Never change the format.** Keep stock DXT5. ARGB32 destroys the font, because **glyph shape lives in the alpha channel** - the byte order shifts and every letter turns to garbage.

Correct workflow: decode DXT5 → repaint the cells → **re-encode only the 4×4 blocks your cells touch** → byte-identical elsewhere.

### Free space

Roughly **the bottom 40% of the atlas is unused** (`y ≈ 604-1023`) - about 270 cells of 28×28. Verify against every glyph table before claiming a region is free, and align cells to the 4px block grid with a 4px gap: shared DXT5 blocks force two images into one 4-colour palette and both come out dirty.

---

## Step by step

1. **Draw** your emoji (`.webp`, `.png` or `.svg`), square-ish, transparent background
2. **Pick a byte** nobody types
3. **Paint** it into a free atlas cell - all 8 mips, surgical DXT5 re-encode
4. **Patch** the glyph tables in `raw/english/fonts/*` - set `pw`/`ph`/`y0`/`dx`/UV
5. **Add** `font,fonts/normalfont` (and any other font you patched) to `mod.csv`
6. **Rebuild** `mod.ff`
7. **Map** the trigger to the byte, server-side, at send time
8. **Restart** the server, then **fully restart the client**

?> **The font loads once, at process start.** Reconnecting is not enough - the client keeps the font it booted with. Half of all "it didn't work" reports are a client that was never restarted.

---

## Debugging checklist

| Symptom | Cause |
|---|---|
| Raw letters (`Á Ð ¼`) | glyph table not loaded - `mod.ff` not rebuilt, or client not restarted |
| Torn fragments | `pw`/`ph` ≠ UV span |
| Coloured square | atlas has no pixels at that cell, or font/atlas grids drifted apart |
| Right size, looks wrong | `y0` - emoji anchored to baseline, growing upwards |
| Works in console, not chat | you patched `consoleFont`, chat is `normalFont` |
| Nothing changes, ever | server not restarted → stale CRC → client re-downloads the old file over yours |

**Verify the three layers together**, always: does the glyph table point at cells where the atlas actually has pixels? A render straight from the shipped files answers in seconds what an hour of in-game guessing will not.
