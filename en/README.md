# 🗺️ VLCT Deathrun - Mapping Guide

Defensive GSC scripting guide for **CoD4 Deathrun** map makers. Patterns, recipes, and survival rules that prevent server crashes.

> **New here?** Start with [Quick Start](#quick-start-5-steps) below, then read [Fundamentals](/en/fundamentals) - that gives you everything to write your first trap.

---

## 📥 Download the template

<a href="templates/_TEMPLATE_FOR_MAPPERS.gsc" download>
  <strong>⬇️ Download <code>_TEMPLATE_FOR_MAPPERS.gsc</code></strong>
</a>

The complete starting `.gsc` file with **30+ ready-to-paste sections** - every helper, every trap, every room pattern documented in this guide. Copy it to `maps\mp\mp_dr_YOURNAME.gsc` and you have a working map skeleton in 5 minutes.

For the full section index and usage notes see [Downloads](/en/downloads).

---

## Quick Start (5 steps)

The fastest path from zero to a working map:

1. **Download the template** (link above) and rename it
   `_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_YOURNAME.gsc`

2. **Open it.** Scroll to `main()`. Delete the `thread` lines for features you do not want (e.g. remove `thread combat_room_sniper();` if your map has no sniper room). Keep `maps\mp\_load::main();` at the top.

3. **For each feature you keep,** find its section in this guide and edit the Radiant `targetname` strings (the values in `getEnt("...")`) to match what you put in Radiant.

4. **Compile your `.bsp`** in Radiant (`Compile > BSP + Light + Link`). Your `.gsc` will be baked into the `.ff` when `linkMap` runs.

5. **Test:** `/map mp_dr_YOURNAME` in the server console. After every test, scan `qconsole.log` for `script runtime error` (see [How to Debug](/en/fundamentals#how-to-debug)).

---

## Why this guide exists

CoD4's GSC engine has a sharp edge: a single unguarded line can:

* Crash the **whole server** (e.g. calling a non-existent builtin like `setmovespeed()`)
* Spam thousands of errors per minute (e.g. accessing `level.activ.X` when no one is on the activator team)
* Silently break your map (e.g. duplicate `targetname` in Radiant → `getEnt` returns undefined)

Most existing community maps were written years ago without these protections. This guide is **extracted from real bugs we hit on a live server** with thousands of plays per day. Every defensive pattern below has a story behind it.

---

## How to use this guide

| If you are... | Read first |
|---|---|
| **Brand new to GSC** | [Fundamentals](/en/fundamentals) (Glossary + Rules) → [Basics](/en/basics) (Hello World) |
| **Coming from Radiant only** | [Fundamentals](/en/fundamentals#radiant-gsc-bridge) (Radiant ↔ GSC bridge) |
| **Have written maps before** | [Before you code](/en/before-you-code) (Anti-patterns + Common mistakes) |
| **Looking for a recipe** | [Traps](/en/traps), [Rooms](/en/rooms), [Effects](/en/effects), [Advanced](/en/advanced) |
| **Hit an error you do not understand** | [Fundamentals](/en/fundamentals#how-to-debug) (How to Debug) |
| **Want a copy-paste cheat sheet** | [Reference](/en/reference) |
| **Building UI / menus or mod systems** | [For Modders](/en/modding) (engine-level topics) |

---

## Help translate this guide

The guide is **English-first** (server is international) but mappers are global. If your native language is Polish, German, Russian, Spanish, French, or Turkish - you can help by translating any page.

Reach out on the [VLCT Discord](https://vlct.mxme.pro/discord) - we will set you up. Even one translated page helps thousands of mappers.

Missing translations auto-fall back to English, so partial translations are useful from day one.

---

## Conventions in this guide

* **GSC code blocks** are syntax-highlighted as C (closest match to GSC).
* Every code example uses the **defensive helpers** (`isValidPlayer`, `safeGetEnt`, `canUse`, `debugPrint`) defined in [Basics](/en/basics).
* `// English comments only.` Polish/Russian/etc inside `.gsc` files breaks the engine - keep your code English even if your spoken language is not.
* `level.activ` is **always** the activator player slot - and it is **always** suspicious. Treat every reference to it as a potential crash unless wrapped in `isplayer(level.activ)`.

---

> Ready? → [Fundamentals](/en/fundamentals) is the next stop.
