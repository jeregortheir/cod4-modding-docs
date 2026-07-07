# 📥 Downloads

Ready-to-use files. Right-click → **Save link as...** if your browser opens them inline instead of downloading.

---

## Mapper template

The complete starting `.gsc` file - **30+ ready-to-paste sections** covering every helper, every trap, every room pattern documented in this guide.

<a href="templates/_TEMPLATE_FOR_MAPPERS.gsc" download>
  <strong>⬇️ <code>_TEMPLATE_FOR_MAPPERS.gsc</code></strong>
</a>

| Detail | Value |
|---|---|
| Filename | `_TEMPLATE_FOR_MAPPERS.gsc` |
| Size | ~80 KB |
| Lines | ~2100 |
| Last update | 2026-04-25 |
| License | Free to use, modify, redistribute |

### What is inside

The file is **annotated for reading top-to-bottom** - every section explains *why* the pattern looks the way it does, not just *what* it does.

| Sections | Topic |
|---|---|
| **Header** | How to use this file, naming conventions, anti-patterns |
| **Section 0** | `addTriggerToList()` (REQUIRED in every map) |
| **Utility helpers** | `isValidPlayer`, `safeGetEnt`, `canUse`, `debugPrint`, `freeze_on_tps`, `countdown_timer_string`, local `GetActivator()` override |
| **Sections 1-2** | Hello World + Start Door (start here) |
| **Sections 3-5** | Trap basics: crusher, lava zone, spinner |
| **Section 6** | Teleporter |
| **Section 7** | Combat room (sniper / knife) |
| **Section 8** | Secret route with XP |
| **Sections 9-10** | Map credits, reset on round end |
| **Sections 11-14** | FX, sound, HUD, multi-stage trap, cooldown, shootable button, jump pad |
| **Section 15** | Trap: one-shot boost with debounce flag |
| **Section 16** | Trap: continuous boost while touching (wind tunnel) |
| **Section 17** | Trap: multi-try fall (N lives) |
| **Section 18** | Trap: anti-stuck nudge |
| **Section 19** | Trap-direction arrow (visual hint, only for nearby players) |
| **Section 20** | Generic teleporter helper (`teleporter_logic`) |
| **Section 21** | Single-instance thread pattern (notify-cancellation) |
| **Section 22** | Multi-room exclusivity (one PvP room at a time) |
| **Section 23** | Fight HUD banner |
| **Section 24** | Polished combat-room template (uses helpers) |
| **Section 25** | Jump-bounce room with checkpoint progression |
| **Section 26** | Gate that opens only for tagged players |
| **Section 27** | Side-detection respawn (which side did they fall on?) |
| **Section 28** | Velocity-conditional bounce pad |
| **Section 29** | Banner with delay or "wait for round to start" |
| **Reference** | Common builtin patterns (movement, sound, HUD, color codes) |
| **Anti-patterns** | Real bugs we have hit on shipped maps - DO NOT REPEAT |

### How to use it

1. **Save the file** to `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` in your CoD4 mod folder.
2. **Copy + rename** to your map name: `maps\mp\mp_dr_YOURNAME.gsc`.
3. **Open it.** Scroll to `main()`. Comment out the `thread X();` lines for features you do **not** want. Keep `maps\mp\_load::main();` at the very top.
4. **For each kept feature**, find its section, edit the Radiant `targetname` strings (the values in `getEnt("...")`) so they match what you actually placed in Radiant.
5. **Compile** the `.bsp` in Radiant (`Compile > BSP + Light + Link`). The `.gsc` gets baked into the `.ff` when `linkMap` runs.
6. **Test:** `/map mp_dr_YOURNAME` in the server console. After every test, scan `qconsole.log` for `script runtime error` (see [Fundamentals → How to debug](/en/fundamentals?id=how-to-debug)).

> **Warning:** if you paste a `thread foo();` line but do NOT also define `foo()` somewhere in your file, the map **will not compile**. Either keep the function body or comment out the `thread` line.

---

## Reporting issues

Found a broken pattern, an outdated function name, or a non-existent CoD4X builtin in the template? Report it on the [VLCT Discord](https://vlct.mxme.pro/discord) - we update the template **on the live server** so every fix benefits the next mapper who downloads it.

---

> 🏠 [Back to Home](/en/)
