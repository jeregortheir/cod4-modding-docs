# 🛠️ For Modders

This section is for **mod makers**, not map makers.

The rest of this guide ([Fundamentals](/en/fundamentals), [Traps](/en/traps), [Rooms](/en/rooms) ...) teaches you how to script a **single map**. This section is different: it covers engine-level systems that sit underneath every map - starting with the **menu (UI) system**.

> **Mapper or modder?**
> If you are writing a map's `.gsc` (`maps\mp\mp_dr_YOURNAME.gsc`), you are a **mapper** - start with [Fundamentals](/en/fundamentals).
> If you are building **UI / menus** or other server-side systems, you are a **modder** - you are in the right place.

This is general CoD4 modding knowledge - it applies to any CoD4 mod, not just one server.

---

## What lives here

| Topic | What it covers |
|---|---|
| [🖼️ Custom menus (.menu UI)](/en/modding-menus) | Building HUD overlays and screens with `.menu` files - the dvar-driven UI system |
| [🧪 Menus II — internals & assets](/en/modding-menus-advanced) | Menu internals, asset limits, IWI/material pipeline |
| [🔤 Custom fonts & chat emojis](/en/modding-fonts) *(experimental)* | Inline images in chat text - glyph tables, the font atlas, and shipping it via `mod.ff` so players need no client patch |

*(more chapters will be added over time)*

---

## Before you touch a live mod

Mod code runs underneath **every** map at once. A bad change here breaks all of them, not just yours.

* **Test on a local server first.** Never push straight to a live server.
* **One system at a time.** Change a thing, test that thing, then move on.
* **English-only in code and comments.** Non-ASCII inside `.gsc`/`.menu` can break the engine.
* **Ask first if unsure.** The [VLCT Discord](https://vlct.mxme.pro/discord) is the place.

---

> Start with [Custom menus (.menu UI)](/en/modding-menus) - the most-requested modder topic.
