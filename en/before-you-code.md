# ⚠️ Before you code

Real bugs we have hit in shipped maps. Read these once before writing your first trap, **then** scan again before you commit.

---

## Anti-patterns - DO NOT do these

### ❌ Empty-body loop without a `wait` on the false branch

```c
while(isalive(player))
    if(isdefined(level.activ))
        wait 1;
// When level.activ is undefined the inner if is false, no wait runs,
// CPU spins until the engine kills the thread.
```

✅ **Fix:** always have a `wait` inside the loop body, even on the false branch.

```c
while(isalive(player)) {
    if(isdefined(level.activ))
        doActivatorWork();
    wait 1;
}
```

---

### ❌ `level.activ` method call without `isplayer()` check

```c
level.activ setOrigin(p.origin);
// Crashes when no axis player - level.activ is the STRING "Noactivator".
```

✅ **Fix:**

```c
if(isplayer(level.activ))
    level.activ setOrigin(p.origin);
```

---

### ❌ Synchronous call to a function that `waittill`s internally

```c
player respawnLater();    // blocks current thread until death
```

This is **almost always** a mistake. You meant:

```c
player thread respawnLater();
```

---

### ❌ `getEnt` with duplicate `targetname`

```c
door = getEnt("door", "targetname");
// If two brushes share targetname "door" -> engine errors and door is undefined.
```

✅ **Fix:** use the `safeGetEnt` helper (see [Basics](/en/basics#utility-helpers)):

```c
door = safeGetEnt("door");
if(!isdefined(door)) return;
```

---

### ❌ Delete an already-deleted entity

```c
level.trig delete();
// Second call (e.g. from another room's chain delete) crashes.
```

✅ **Fix:**

```c
if(isdefined(level.trig)) level.trig delete();
```

---

### ❌ Use Polish / non-English strings or em-dashes in `.gsc` files

```c
// Pulapka aktywujaca sie po wejsciu gracza    <- WRONG (Polish)
// Trap that fires when the player enters       <- RIGHT (English)
```

CoD4X engine cannot render special characters consistently. **Comments AND in-game strings must be English.**

The em-dash `—` (U+2014) renders as garbage. Use plain `-` (hyphen).

---

## Common Mistakes - one-minute scan checklist

Run this scan in your head before every commit:

| Symptom | Likely cause |
|---|---|
| `Missing wait in a loop body` | Thread killed / server hang |
| `level.activ setOrigin(...)` raw | Crash when no axis player |
| `getEnt("name", ...)` on duplicate | "used with more than one entity" |
| Accessing `.origin` on undefined | "undefined is not a field object" |
| Calling a function synchronously that does `waittill("death")` | Caller blocks until it returns - meant it as `thread` call? |
| Forgetting `addTriggerToList(...)` for activator triggers | Activator gets no reward for pressing your trap's button |
| Hardcoded Polish / non-English strings or em-dash | Garbage glyphs + looks unprofessional to players |

---

## Naming convention

Follow this so other mappers (and your future self reviewing your map 6 months later) can navigate without guessing.

| Prefix | Used for |
|---|---|
| `trig_<what>` | `trigger_multiple` in Radiant |
| `origin_<what>` | `script_origin` used as a position marker |
| `door_<what>` | brushmodel door |
| `brush_<what>` | misc brushmodel (mover, platform) |
| `fx_<what>` | `script_model` used for FX anchor |
| `tp_<what>` | teleporter destination |
| `secret_<where>_<what>` | secret-route entities |
| `lever_<what>` | shootable / usable lever |

**Examples:** `trig_trap_crusher`, `origin_combat_sniper_jumper`, `secret_easy_enter_trig`, `brush_trap_wall`.

---

> Next: [Basics + Hello World](/en/basics) - your first working map function.
