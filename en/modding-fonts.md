# 🔤 Custom fonts & chat emojis

?> **This is an experiment, not a finished recipe.** Everything below was learned by trial and error on a 2007 engine with no documentation. It works on our setup, but expect rough edges - some steps may not behave the same on yours, and a few of the "facts" here were wrong two or three times before they were right. Treat it as a map of the terrain, not a guarantee. If something doesn't work, that's normal - keep digging, the wall is usually somewhere you didn't look.

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

### Four traps

**1. Mips are stored smallest-first.** The offsets in the header are each mip's **end**. The base level starts at `filesize - W*H`, **not** at byte 28. Reading from 28 gives you a small mip and your drawing lands in the wrong glyphs.

**2. Paint every mip.** The GPU picks a level by render size. There are 8 (512×1024 down to 4×8). At mip 3-4 a 32px emoji is 4×4 pixels - a coloured blob. That is normal and unavoidable.

**3. Never change the format.** Keep stock DXT5. ARGB32 destroys the font, because **glyph shape lives in the alpha channel** - the byte order shifts and every letter turns to garbage.

Correct workflow: decode DXT5 → repaint the cells → **re-encode only the 4×4 blocks your cells touch** → byte-identical elsewhere.

**4. The mip chain must run all the way down to 1×1.** This one is vicious and cost the most time. If you build a *new* atlas (see below) and stop the chain at 4×4, the file is missing the 2×2 and 1×1 levels - each still a full 16-byte DXT5 block. The engine locates every mip by walking **from the smallest**, so a chain that is two levels short shifts *every intermediate offset*. The result: the base (largest) mip is fine because it is found from the file's end, so **large glyphs render perfectly** - but small text samples the shifted mid-chain and comes out as **garbled noise**. The tell is exactly that split: big icons good, small letters scrambled. Match the stock chain length (down to 1×1) exactly.

### Free space - and how much you *really* have

Roughly **the bottom 40% of the atlas is unused** (`y ≈ 604-1023`). Verify against every glyph table before claiming a region is free, and align cells to the 4px block grid with a 4px gap: shared DXT5 blocks force two images into one 4-colour palette and both come out dirty.

But **cell count is not your real ceiling** - two other limits bite first:

- **One byte per emoji.** Your triggers map to single high bytes. After removing your players' language characters, the usable range (`0xA0-0xFF`) leaves on the order of a few dozen free bytes. That is your **hard cap on the number of emojis**, no matter how much atlas you have.
- **A cell in *every* font you patch.** If an emoji must render in chat *and* in bigger HUD fonts, it needs a cell at each of those sizes. So "N emojis" really costs "N × (number of distinct font sizes)" cells. It is easy to overcount free space by forgetting this - a mistake that will happily send you down the wrong path.

If you outgrow the stock 512×1024 atlas, see **Growing beyond the stock atlas** below.

---

## Growing beyond the stock atlas

Once you want many emojis rendered at full size across several fonts, the stock 512×1024 atlas runs out of room. You can point the fonts at a **larger atlas of your own** instead - the stock one stays untouched, so anything else that samples it keeps working.

This is a bigger lift and has sharp edges. The shape of it:

1. **Build a new, larger `.iwi`** (for example 2048×2048, same DXT5 format). Copy the stock letter atlas into one corner - do it by **block-copying the encoded DXT5 blocks per mip level**, so the letters stay pixel-identical, no re-encoding. Paint your emojis into the free area. Remember trap #4: **full mip chain down to 1×1**.

2. **Give the fonts a new material.** A font glyph table references its atlas by a **material name string** stored at the end of the file. Clone a stock *font* material as a donor (the ones with a `2d` techset are the right kind), point it at your new image, and swap the font's material-name string to match.

3. **Rewrite the material's string offsets, don't just overwrite bytes.** A CoD4 material file is a fixed header of pointer offsets followed by NUL-terminated strings. Several `u32` fields point into that string block - and crucially there is **more than one reference to the image name** (a hidden second field beyond the obvious one). Remap **every** offset that pointed at a string, or the engine reads the image name from the middle of another string and reports `image ... is missing`. That single missed field will cost you an afternoon.

4. **Font materials come in pairs - the linker auto-appends `_glow`.** A font that uses material `fonts/myatlas` makes the linker also demand `fonts/myatlas_glow` (the glow-pass material). Build both. They can sample the **same** image.

5. **The linker needs the image in `raw/images/`, not only in your `.iwd`.** The material bakes a copy of the image into `mod.ff` at build time, and it looks for the source there. Put the `.iwi` in both places. Consequence: from now on, **changing the pixels means rebuilding `mod.ff`**, not just re-shipping the iwd.

6. **Scale every glyph's UV** by the ratio of old atlas size to new, so the letters (and any glyph you copied) land exactly on their sub-region of the bigger plane. A letter at normalized UV `(s, t)` in the old 512×1024 becomes `(s × oldW/newW, t × oldH/newH)`.

?> Reserve this for when you actually need it. The stock-atlas path is far simpler and covers most cases. Reach for a custom atlas only when the byte cap is not your limit but the *pixels* are.

---

## One size that looks the same for everyone

Emojis are drawn at a **fixed pixel size**, but chat text **scales with the player's resolution**. So if you size emojis with a flat pixel number, the icon-to-text ratio drifts per resolution: what looks right on your monitor looks huge on a 720p client and vice-versa.

**Fix: size every font's emoji cell as the same multiple of that font's line height** (`pixelHeight`), using one shared multiplier. Then the icon is always, say, 1.6× the surrounding text - on every screen. If instead you cap different fonts at different pixel sizes, the ratio breaks and you get the classic "fine for me, too big for everyone else" report.

---

## A `!emoji` help command that shows the real icons

Handy trick for a list command: you want to show each icon **next to the exact text a player must type** - but if you print `:skull:` it just becomes the icon again.

Break the match without changing what the player sees: **insert a colour code after the first character** of the trigger. `:skull:` written as `:^7skull:` is no longer the contiguous bytes `:skull:`, so the substitution pass skips it - yet the client renders `^7` as a (harmless) colour switch and shows the literal text `:skull:`. Print the real trigger (becomes the icon) followed by this broken copy (stays as text), and the player sees **icon + how to type it**.

Send it through whatever per-player message path already runs your substitution, and stagger the lines with a short wait so you never flood the reliable-command buffer.

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
| Big icons fine, small text garbled | custom atlas with an **incomplete mip chain** - it must run to 1×1 (trap #4) |
| `image ... is missing` at build | material offsets not fully remapped - the hidden second image-name field still points wrong |
| Huge for others, fine for you | fixed-pixel sizing - scale by line height with one shared multiplier instead |
| Nothing changes, ever | server not restarted → stale CRC → client re-downloads the old file over yours |

**Verify the three layers together**, always: does the glyph table point at cells where the atlas actually has pixels? A render straight from the shipped files answers in seconds what an hour of in-game guessing will not.
