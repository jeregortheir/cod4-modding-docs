# 📖 Fundamentals

Read this whole page **before** you write any GSC. It takes 10 minutes and saves hours.

---

## Glossary - plain English definitions

> If you only remember three things from this page: `self`, `level`, and `level.activ`. Those three concepts cause 80% of beginner crashes.

| Term | Meaning |
|---|---|
| **self** | The entity this function is currently running on. For `player thread X()` → inside `X()`, `self` = player. For `trig thread Y()` → inside `Y()`, `self` = `trig`. |
| **level** | Global shared state. `level.foo` is visible from any function in any file on the server. Use for things shared between players / threads. |
| **entity** | Anything in the 3D world: a player, a brush, a `script_origin` marker, an FX anchor, a trigger. Has `.origin` (position) and `.angles` (rotation). |
| **thread X()** | Start function `X` in the background. Caller keeps going without waiting for `X` to finish. Essential for anything that loops forever (traps, triggers). |
| **waittill("foo")** | Pause this function (not the whole server) until someone calls `notify("foo")` on the same entity/level. Used to react to events: round start, player death, trigger fired, move finished, etc. |
| **notify("foo")** | Send a signal. Any function sitting on `waittill("foo")` on this entity/level wakes up. Any function with `endon("foo")` here gets killed. |
| **endon("foo")** | If `notify("foo")` fires, immediately kill this thread. Use at the top of loops so they stop cleanly on round end / player death / disconnect. |
| **getEnt(name, "targetname")** | Find ONE entity by the `targetname` KVP you set in Radiant. Returns the entity, or `undefined` if none. **Crashes if MORE THAN ONE entity shares the name** - use `getentarray()` + `[0]` in that case. |
| **dvar** | A named server variable (like a Windows environment variable). `setDvar("foo", 1)` / `getDvar("foo")`. Used for config and for client↔server communication. |
| **precache** | Tell the engine "I will use this asset", done **ONCE** at map load in `main()` (or helper called from `main()`). If you use an asset without precaching it crashes. |
| **allies / axis** | Team names. In Deathrun: `allies` = jumpers (green, the majority), `axis` = activator (red, exactly one player). |
| **level.activ** | The player currently on axis team (the activator). **CAN BE THE STRING `"Noactivator"`** when no one is axis - **always** check `isplayer(level.activ)` before using.|
| **module::function** | The `::` is "from file X, call function Y". Example: `maps\mp\_load::main()` means "in file `maps/mp/_load.gsc`, call its `main()` function". |
| **KVP** | Key-Value Pair in Radiant's Entity Inspector (press `N`). You add `targetname` / `classname` / custom keys in Radiant, you read them in GSC via `.targetname` etc. |
| **vector** | Three numbers in parens: `(x, y, z)`. Positions, angles, colors all use this. Example: `(100, 200, 50)`. |

---

## How to debug

* Add `iprintln("foo")` to print something visible to **all players**. Quick + dirty but spammy.
* Add `println("foo")` to print to `qconsole.log` **only** (server-only). Quiet + clean. Good for development.
* **Better:** flip `level.debug = true;` at the top of `main()` and use the `debugPrint("foo")` helper (see [Basics](/en/basics#utility-helpers)). One line to silence all debug output before shipping: change `true` → `false`.

### How to read script errors

Script errors appear in `qconsole.log` looking like:

```
^1******* script runtime error *******
undefined is not a field object: (file 'maps/mp/X.gsc', line 123)
    player.camo_preview.model
          *
^1called from:
(file 'maps/mp/X.gsc', line 80)
    open_camos_menu();
    *
```

* The `*` points at **which thing was undefined**.
* The function stack that follows shows **what called this line** - trace it back to find the root.
* `(file 'maps/mp/X.gsc', line 123)` - jump to that exact line in your editor.

### Quick-reference common errors

| Error | What it means | Fix |
|---|---|---|
| `undefined is not a field object` | You did `.X` on undefined | Check the thing before `.X` is `isdefined()` |
| `undefined is not an entity` | Entity got deleted mid-loop | Re-check `isdefined()` between waits |
| `type string is not an entity` | Used `level.activ` as entity without `isplayer()` check | Wrap in `if(isplayer(level.activ))` |
| `getent used with more than one entity` | Duplicate `targetname` in Radiant | Rename or use `getentarray()[0]` / `safeGetEnt()` |
| `potential infinite loop in script - killing thread` | Loop has no `wait` on some path | Add `wait 0.05;` to every loop iteration |
| `cannot cast undefined to bool` | `if(level.foo == 1)` where `level.foo` is undefined | Init `level.foo` to a default before checking |

---

## Radiant ↔ GSC bridge

How what you place in Radiant maps to what you type in GSC:

```
In Radiant (Entity Inspector):        In GSC code:
-------------------------------       ----------------------------------
trigger_multiple                      getEnt("X", "targetname")
  targetname: X                          - returns the trigger entity

script_origin                         ent = getEnt("X", "targetname");
  targetname: X                       ent.origin  -> (x, y, z) vector
  origin: 100 200 50                  ent.angles  -> (pitch, yaw, roll)
  angles: 0 90 0

script_brushmodel                     door = getEnt("door", ...)
  targetname: door                    door moveZ(200, 2);    // slide
  (select brush + Ctrl-T)             door rotateYaw(90, 1); // rotate

script_model                          fx = getEnt("fx1", ...)
  targetname: fx1                     playfx(level._effect["fire"],
  model: <tag_origin>                        fx.origin);

spawn-point                           (handled by engine automatically)
  classname: mp_jumper_spawn
  classname: mp_activator_spawn
```

**Golden rules:**

* Every `targetname` you type in Radiant must match **exactly** in `getEnt("...")` in GSC - case sensitive, no typos.
* If two things in Radiant have the same `targetname`, `getEnt()` crashes. Use `getentarray()` + `[0]` or the `safeGetEnt()` helper instead.
* New entity in Radiant = **recompile** the map or it will not appear.

---

## Rules of Survival

The 8 rules that prevent 90% of bugs.

### 1. Always guard `getEnt`/`getent` results

```c
ent = getEnt("foo", "targetname");
if(!isdefined(ent)) return;        // <-- this line
```

at the **top of the function**. If a brush is named wrong, the function returns instead of crashing later when you try `.origin` on undefined.

### 2. Always validate the player after a trigger fires

```c
trig waittill("trigger", player);
if(!isValidPlayer(player)) continue;     // <-- this line
```

The player can disconnect or die between firing the trigger and your code running.

### 3. Never call methods on `level.activ` raw

```c
// BAD - crashes when no one is activator
level.activ setOrigin(p.origin);

// GOOD
if(isplayer(level.activ))
    level.activ setOrigin(p.origin);
```

When no one is on the activator team, `GetActivator()` returns the **string** `"Noactivator"`. Calling `level.activ setOrigin(...)` on a string is a runtime error and floods the log.

### 4. Never use `setmovespeed()` or `setgravity()`

```c
// BAD - non-existent CoD4X builtin, crashes the WHOLE SERVER in some builds
player setmovespeed(500);
player setgravity(500);

// GOOD
player setMoveSpeedScale(2.6);  // 2.6x = ~500 effective
```

Use `setMoveSpeedScale(float)` where `1.0` = default speed (210 in this mod), `0.95` = slow (190), `1.5` = fast.

### 5. Never write an empty-body loop without a `wait`

```c
// BAD - when condition is false on inner if, no wait runs -> CPU spins
while(condition)
    if(other)
        wait 1;

// GOOD - always have a wait somewhere in the loop body
while(condition) {
    if(other) doSomething();
    wait 1;
}
```

The CoD4X opcode killer will kill the thread; in a busy moment it can hang the server.

### 6. Never use `getEnt` on duplicate `targetname`

If more than one entity in Radiant has the same `targetname`, `getEnt` errors with `"getent used with more than one entity"`. Use `safeGetEnt("foo")` from [Basics → Utility helpers](/en/basics#utility-helpers), or `getentarray("foo", "targetname")[0]`.

### 7. All player-facing strings in English

`iPrintLn`, `iPrintLnBold`, hint strings, HUD text - **must be English**. The server is international.

### 8. Never use the em-dash character

The CoD4 engine cannot render the em-dash (`U+2014`) - it shows as garbage. Use `-` (hyphen) or `--` (double hyphen) in `.gsc` files instead.

---

> Next: [Before you code](/en/before-you-code) - common mistakes and anti-patterns to avoid.
