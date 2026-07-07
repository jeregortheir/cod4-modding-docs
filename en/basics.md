# 👋 Basics + Hello World

The skeleton every map needs, plus your first working function.

---

## `main()` - the starter kit

Every map MUST have a `main()` function. The engine calls it automatically on map load.

> **Warning:** if you paste a `thread foo();` line but do NOT also define the function `foo()` somewhere in your file, the map **will not compile**.

```c
main()
{
    // ALWAYS first: loads engine systems (spawnpoints, gametype hooks,
    // weapons). Without this call the map will not run at all.
    //   maps\mp\_load is the file maps/mp/_load.gsc
    //   ::main()      means "call its main() function"
    maps\mp\_load::main();

    // Fall damage off (Deathrun convention: falling should only kill via
    // map traps, not the vanilla CoD fall-damage formula).
    SetDvar("bg_falldamagemaxheight", 99999);
    SetDvar("bg_falldamageminheight", 99998);

    // Secret count for the leaderboard system.
    // Set vlct_secret_count to how many secret routes your map has (0-3).
    setDvar("vlct_secret_count", 1);
    setDvar("vlct_secret_1_name", "Cut");
    // setDvar("vlct_secret_2_name", "Hard");
    // setDvar("vlct_secret_3_name", "Pro");

    // Debug toggle. Flip to `true` during development to see debugPrint()
    // messages in qconsole.log. Flip back to `false` before shipping.
    level.debug = false;

    // Threads.
    //   `thread X()` = "start X() in the background, don't wait for it".
    //   Every persistent system (trap loop, trigger watcher) needs its own
    //   thread so it can run forever without blocking others.
    thread simple_door_example();    // Hello World - below
    thread startdoor();              // also below
    // thread trap_crusher();           <- uncomment if you build it
    // thread combat_room_sniper();     <- uncomment if you build it
    // thread secret_easy();
    // thread reset_traps_on_round_end();

    // REGISTER TRAP TRIGGERS - see Section below
    // addTriggerToList("trig_trap_crusher");
    // addTriggerToList("trig_trap_lava_button");
}
```

---

## `addTriggerToList()` - REQUIRED for activator-pressed triggers

This is a **convention helper** - the mod itself does not define it, every map must include this exact function (or copy from any existing map).

```c
addTriggerToList(targetname)
{
    if(!isdefined(level.trapTriggers))
        level.trapTriggers = [];

    ent = getEnt(targetname, "targetname");
    if(!isdefined(ent)) return;       // silently skip typos / removed brushes

    level.trapTriggers[level.trapTriggers.size] = ent;
}
```

**Why every activator-facing trigger must be registered:**

The mod reads `level.trapTriggers[]` in `zec/_main.gsc::_init()` right after your `main()` finishes, then:

1. Builds `level.activator_traps[]` so admins / VIPs can fire the trap remotely from the shop's "Activate Trap" menu.
2. Spawns the per-trigger XP / coin reward thread for the activator.

If you forget to call `addTriggerToList()`, the trap still works for jumpers, but the **activator gets no XP or coins** for using it AND it does not appear in the shop.

> Do NOT register secret triggers, teleporters, or jumper-only buttons.

---

## Utility helpers (copy these verbatim)

These short functions exist to kill the most common boilerplate. Using them makes your map 2x more readable AND harder to screw up.

### `isValidPlayer(p)` - one-call player guard

```c
// Replaces:    if(!isdefined(p) || !isplayer(p) || !isalive(p)) continue;
// With:        if(!isValidPlayer(p)) continue;
isValidPlayer(p)
{
    return isdefined(p) && isplayer(p) && isalive(p);
}
```

Use it on every `waittill("trigger", player)` result, every `level.activ` check, every `level.players[i]` loop iteration.

### `safeGetEnt(name)` - `getEnt` that never crashes on duplicates

```c
// `getEnt("foo", "targetname")` errors if more than one entity in Radiant
// shares that name. This wrapper falls back to `getentarray()[0]`.
// Returns undefined when no entity exists - caller MUST still isdefined-check.
safeGetEnt(targetname)
{
    arr = getentarray(targetname, "targetname");
    if(!isdefined(arr) || arr.size == 0) return undefined;
    return arr[0];
}
```

### `canUse(ent, delay_sec)` - cooldown gate for trap reuse

Anti-spam for activator-controlled traps. First call returns `true` and stamps the entity with `getTime()`. Subsequent calls within `delay_sec` return `false`. After the window expires it resets automatically.

```c
canUse(ent, delay_sec)
{
    if(!isdefined(ent)) return false;
    now = getTime();
    if(isdefined(ent.lastUseTime) && (now - ent.lastUseTime) < (delay_sec * 1000))
        return false;
    ent.lastUseTime = now;
    return true;
}
```

**Typical use:**

```c
while(true) {
    trig waittill("trigger", user);
    if(!isValidPlayer(user)) continue;
    if(!canUse(trig, 10)) {
        user iPrintln("^1Trap on cooldown");
        continue;
    }
    // ...fire trap...
}
```

### `freeze_on_tps(time)` - lock the player briefly after a teleport

After a `setOrigin` the player can keep their pre-teleport velocity and "skid" out of the destination. Freezing controls for a few frames fixes that. Splitting the unfreeze into its own thread means callers do not block.

```c
freeze_on_tps(time)
{
    self freezeControls(true);
    self thread _unfreeze_after(time);
}

_unfreeze_after(time)
{
    self endon("disconnect");
    wait time;
    if(isalive(self))
        self freezeControls(false);
}
```

**Typical use** (after every `setOrigin`):

```c
player setOrigin(dest.origin);
player setPlayerAngles(dest.angles);
player freeze_on_tps(0.05);    // tiny freeze just to kill momentum
```

For PvP rooms use a longer freeze (3-4 sec) that lines up with a countdown.

### `countdown_timer_string(time, end_string, color)` - 3..2..1..GO

Reusable countdown banner. Used by every PvP arena before a fight starts.

```c
countdown_timer_string(time, end_string, color)
{
    if(!isdefined(color)) color = "^3";
    for(i = time; i > 0; i--) {
        iPrintLnBold(color + i);
        wait 1;
    }
    iPrintLnBold(end_string);
}
```

**Typical use:**

```c
player    freeze_on_tps(4);
activator freeze_on_tps(4);
thread countdown_timer_string(4, "^1FIGHT!", "^3");
```

### `GetActivator()` - safe override that never returns the `"Noactivator"` string

`level.activ` (set by the mod's built-in `GetActivator`) is the **string** `"Noactivator"` when no one is on axis. That breaks every `if(isdefined(level.activ)) level.activ setOrigin(...)` call (string passes `isdefined`, then crashes on the method).

This local override iterates `players` and returns `undefined` when no axis player is alive - so a single `if(!isplayer(activator))` guard at the call site is enough.

```c
GetActivator()
{
    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        p = players[i];
        if(isdefined(p) && isplayer(p) && isalive(p) && p.pers["team"] == "axis")
            return p;
    }
    return undefined;
}
```

**Typical use:**

```c
activator = GetActivator();
if(!isplayer(activator)) {
    player iPrintln("^1No activator - room unavailable");
    continue;
}
activator setOrigin(ac_pos.origin);   // safe: activator is a real player
```

> Defining your own `GetActivator()` shadows the built-in **only inside this map's `.gsc`** - other files keep using the original. That is exactly what we want.

### `debugPrint(msg)` - console-only logging

Flip `level.debug = true;` at the top of `main()` to see your messages in `qconsole.log` during playtest. Flip back to `false` before shipping. Uses `println()` which only goes to the server console, not the client.

```c
debugPrint(msg)
{
    if(isdefined(level.debug) && level.debug)
        println("[MAP] " + msg);
}
```

---

## Hello World - the simplest possible example

> Read this first. It is **6 lines of actual code**. Once you understand what each line does, every other section in this guide will make sense.

**What it does:** when a player walks into a trigger named `hello_trig`, print `"Hello, <playername>!"` to everyone.

**In Radiant you need:**
* a brush made into a `trigger_multiple`
* with KVP `targetname` = `hello_trig`

```c
simple_door_example()
{
    // 1. Find the trigger by its Radiant targetname.
    trig = getEnt("hello_trig", "targetname");

    // 2. If the trigger does not exist (wrong targetname / removed brush),
    //    quietly stop. Better than crashing later.
    if(!isdefined(trig)) return;

    // 3. Wait forever, reacting to each trigger fire.
    while(true)
    {
        // 4. Pause until a player walks into the trigger. The player
        //    entity is returned in `player`.
        trig waittill("trigger", player);

        // 5. The player may have disconnected / died between triggering
        //    and us getting the CPU back. `isValidPlayer` catches all
        //    three bad cases (undefined / not-a-player / dead).
        if(!isValidPlayer(player)) continue;

        // 6. Print the greeting to all players.
        iPrintlnBold("^5Hello, " + player.name + "!");
    }
}
```

---

## Start door - the first real pattern

Most Deathrun maps have a barrier that opens when the round actually starts (jumpers and activator placed). Uses `level waittill("round_started")` to react to that engine event.

```c
startdoor()
{
    door = getEnt("startdoor", "targetname");
    if(!isdefined(door)) return;

    // Wait for the round to actually begin.
    level waittill("round_started");

    // Open up by 200 units over 2 seconds.
    door moveZ(200, 2);
}
```

---

> Next: [Traps](/en/traps) - the patterns activators use to kill jumpers.
