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

### ❌ `&"..."` with a normal string in `setHintString`

```c
trig setHintString( &"Press ^3&&1 ^7to enter" );
// FATAL at map load: "Illegal localized string reference ... must contain
// only alpha-numeric characters and underscores"
```

The `&` prefix means a **localized string reference** - the name after it must be a valid identifier (`&"SCRIPT_HINT_ENTER"`), not a sentence with spaces, colour codes and `&&1`. This one **kills the server on load**, so it hides until the map is actually played.

✅ **Fix:** drop the `&`. A plain string supports `&&1` and colour codes fine:

```c
trig setHintString( "Press ^3&&1 ^7to enter" );
```

---

### ❌ Off-by-one: `i <= array.size`

```c
for(i = 0; i <= players.size; i++)
    players[i] ...;
// Last pass is players[players.size] = undefined -> a burst of errors from ONE line.
```

`i <= size` always runs one iteration past the end. It is never what you want.

✅ **Fix:** `i < players.size`.

---

### ❌ `for` / `if` without braces eats only the next line

```c
for(i = 0; i < parts.size; i++)

    playSound("tick");        // <- the ONLY thing in the loop
    parts[i] thread spin();   // <- runs ONCE, after the loop, with i out of range
```

A brace-less `for`/`if` takes exactly the next statement. A blank line does not help. This produces a **silent** failure - no error, the feature just never runs.

✅ **Fix:** always brace loop and conditional bodies.

---

?> **Many of these print an error and keep going** - they are not fatal, so a broken map still "works" for years until someone turns on `logfile`. When you audit a map, don't trust "it never had problems": if a `.gsc` calls `getEnt("thing")` but the `.bsp` has no entity named `thing` (common when a script was written for a different version of the map), it fails **every time**, silently. The fix is a guard (`if(isdefined(...))`), not inventing the missing entity.

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
| `&"..."` with spaces/colour codes in `setHintString` | FATAL "illegal localized string reference" on map load |
| `for(i=0; i<=arr.size; ...)` | One pass past the end - burst of `undefined` errors |
| `for`/`if` body without braces | Only the next line is inside - feature silently never runs |

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
