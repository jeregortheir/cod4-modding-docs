# 🚀 Advanced patterns

Less common, but extremely useful. Each is a real pattern from shipped maps.

---

## Anti-glitch zone (kill players who escape map bounds)

Place a big `trigger_multiple` covering all out-of-bounds areas. Anyone inside it dies.

> Use `trigger_hurt` in Radiant if you want it always-on. Use this script pattern if you want **conditional** kill (e.g. only if not in spectator).

```c
anti_glitch_zone()
{
    trig = getEnt("trig_antiglitch", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(player.sessionstate != "playing") continue;

        player iPrintln("^1Out of bounds - respawning");
        player suicide();
    }
}
```

---

## Player position tracking (proximity event)

Sometimes you cannot use a trigger (e.g. no Radiant access, dynamic zone). Sample player positions on a timer and react when one is in range of a point.

> **Keep the timer generous (>= 0.5 sec)** - this loop runs forever and over EVERY player.

```c
proximity_watcher()
{
    target_pos = getEnt("origin_proximity_target", "targetname");
    if(!isdefined(target_pos)) return;

    radius_squared = 100 * 100;   // 100 units. Squared so we skip sqrt() in loop.

    while(true)
    {
        wait 0.5;

        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            p = players[i];
            if(!isValidPlayer(p)) continue;
            if(p.team != "allies") continue;

            // distance2() is the squared distance - cheaper than distance().
            if(distance2(p.origin, target_pos.origin) < radius_squared)
            {
                if(!isdefined(p.in_proximity_zone))
                {
                    p.in_proximity_zone = true;
                    p iPrintln("^5You feel something nearby...");
                    // Trigger the event ONCE per player per round.
                }
            }
        }
    }
}
```

---

## Random trap selector (different trap each round)

At round start, pick one trap variant from a pool. Use `randomInt()` and switch on the result. Variation keeps the map fresh.

```c
random_trap_choice()
{
    level waittill("round_started");

    pick = randomInt(3);   // 0, 1, or 2

    switch(pick)
    {
        case 0:  thread trap_variant_fire();     break;
        case 1:  thread trap_variant_water();    break;
        case 2:  thread trap_variant_spikes();   break;
    }
}

// Stub variants - fill in like a normal trap.
trap_variant_fire()   { /* getEnt + thread loop */ }
trap_variant_water()  { /* getEnt + thread loop */ }
trap_variant_spikes() { /* getEnt + thread loop */ }
```

---

## VIP / mapper-only door

Restrict a trigger to specific Steam GUIDs (yourself, friends). Useful for hidden maker-only rooms that show off behind-the-scenes stuff.

```c
mapper_only_door()
{
    trig = getEnt("trig_mapper_door", "targetname");
    door = getEnt("door_mapper",      "targetname");
    if(!isdefined(trig) || !isdefined(door)) return;

    // Replace with your real Steam GUIDs.
    allowed_guids = strtok("76561198000000001;76561198000000002", ";");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        ok = false;
        for(i = 0; i < allowed_guids.size; i++) {
            if(isdefined(player.guid) && player.guid == allowed_guids[i]) {
                ok = true;
                break;
            }
        }
        if(!ok) {
            player iPrintlnBold("^1Mapper only");
            continue;
        }

        if(isdefined(door)) door moveZ(150, 1);
        wait 5;
        if(isdefined(door)) door moveZ(-150, 1);
    }
}
```

---

## Wait for all jumpers dead (round-end hook)

Fire an event the moment the LAST jumper dies (e.g. play victory sound, spawn a celebration FX for the activator). Built on `level.players` + `isalive` sampling.

```c
last_jumper_watcher()
{
    level endon("endround");

    while(true)
    {
        wait 1;

        alive_jumpers = 0;
        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++) {
            if(!isdefined(players[i])) continue;
            if(players[i].team == "allies" && isalive(players[i]))
                alive_jumpers++;
        }

        if(alive_jumpers == 0) {
            // All jumpers dead. Fire your event, then break.
            iPrintlnBold("^1All jumpers eliminated");
            // ...spawn FX, play sound, give activator XP, etc.
            return;
        }
    }
}
```

---

## Generic teleporter helper (`teleporter_logic`)

Replaces ~20 lines of copy-paste teleport boilerplate with one parametrised function. Optional freeze, optional callback that fires after the teleport (function pointer via `[[ ]]()`).

```c
//   trigger     - the trigger entity to wait on
//   exit_ent    - destination (script_origin)
//   set_angles  - if true, also set the player's view angles to exit_ent.angles
//   freeze      - seconds to freeze controls after teleport (undefined = no freeze)
//   on_arrive   - function pointer to thread on the player after teleport (or undefined)
teleporter_logic(trigger, exit_ent, set_angles, freeze, on_arrive)
{
    if(!isdefined(trigger) || !isdefined(exit_ent)) return;

    while(true)
    {
        trigger waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        player setVelocity((0, 0, 0));
        player setOrigin(exit_ent.origin);
        if(isdefined(set_angles) && set_angles)
            player setPlayerAngles(exit_ent.angles);

        if(isdefined(freeze))
            player freeze_on_tps(freeze);

        if(isdefined(on_arrive))
            player thread [[on_arrive]]();
    }
}
```

**Wiring it up in `main()`:**

```c
// Plain teleporter, no callback:
trig = getEnt("trig_teleport_skip",   "targetname");
dest = getEnt("origin_teleport_skip", "targetname");
thread teleporter_logic(trig, dest, true, undefined, undefined);

// Teleporter into a secret zone, runs a per-player setup callback after arrival:
trig = getEnt("trig_secret_enter", "targetname");
dest = getEnt("origin_secret",     "targetname");
thread teleporter_logic(trig, dest, true, 0.05, ::on_enter_secret);

on_enter_secret()
{
    self setVelocity((180, 180, 0));      // launch the player into the level
    self.secret_streak = 0;               // init per-player state
    self iPrintln("^5Secret entered");
}
```

> The `::function_name` syntax creates a function pointer; `[[ptr]]()` calls it. Pointers can be passed as parameters - this is how you build reusable abstractions in GSC.

---

## Single-instance thread pattern (notify-cancellation)

When a function should have **at most one instance per entity running at a time** - HUDs, ammo refill loops, status timers - the trick is to start with a `notify` and an `endon` on the same name. Any later call cancels the previous.

```c
single_instance_thread()
{
    self notify("foo_running");      // cancel any prior instance
    self endon("foo_running");        // get cancelled by the next start
    self endon("disconnect");
    self endon("death");

    // ...the actual loop / one-shot work...
    while(true)
    {
        // do thing
        wait 0.5;
    }
}
```

**Real-world example** - keep one weapon's ammo topped up until the player dies or the function is re-called:

```c
keep_ammo_topped(weapon, refresh_sec)
{
    self notify("ammo_topup_active");
    self endon("ammo_topup_active");
    self endon("disconnect");
    self endon("death");

    while(true)
    {
        self setWeaponAmmoStock(weapon, 200);
        wait refresh_sec;
    }
}

// Each call replaces the previous one - safe to call twice in a row.
//   activator thread keep_ammo_topped("h2_m79a_mp", 1);
```

---

## Gate that opens only for tagged players

A brush that becomes walk-through (`notSolid`) only when **at least one** player with a specific flag is touching it. Used for "ghost mode passthrough" doors, secret-route gates, VIP barriers.

```c
flag_gated_door()
{
    door  = getEnt("door_ghost_only",         "targetname");
    sense = getEnt("trig_ghost_sense_volume", "targetname");
    if(!isdefined(door) || !isdefined(sense)) return;

    while(true)
    {
        wait 0.1;
        any_ghost_touching = false;

        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++) {
            p = players[i];
            if(!isValidPlayer(p)) continue;
            if(isdefined(p.is_ghost) && p isTouching(sense)) {
                any_ghost_touching = true;
                break;
            }
        }

        if(any_ghost_touching) door notSolid();
        else                   door solid();
    }
}
```

> Wake-up cycle is 0.1 sec - good enough for a door gate, but do not push it lower without need (every player gets sampled every tick).

---

## Side-detection respawn (which side of the room did they fall on?)

Common in PvP rooms: if the activator's pit teleports them back to acti spawn, jumper's pit to jumper spawn. Use a `script_origin` placed at the dividing line and compare X (or Y, depending on your map's axis).

```c
fall_pit_side_aware()
{
    pit       = getEnt("trig_pvproom_pit",    "targetname");
    midpoint  = getEnt("origin_pvproom_mid",  "targetname");
    acti_pos  = getEnt("origin_pvproom_acti", "targetname");
    jump_pos  = getEnt("origin_pvproom_jump", "targetname");
    if(!isdefined(pit) || !isdefined(midpoint) || !isdefined(acti_pos) || !isdefined(jump_pos)) return;

    while(true)
    {
        pit waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // Compare on whichever axis splits the room (X here).
        if(player.origin[0] > midpoint.origin[0]) {
            player setOrigin(acti_pos.origin);
            player setPlayerAngles(acti_pos.angles);
        } else {
            player setOrigin(jump_pos.origin);
            player setPlayerAngles(jump_pos.angles);
        }
        player freeze_on_tps(0.05);
    }
}
```

> Multi-checkpoint progression (respawn at last reached checkpoint instead of start) lives in [Rooms → Jump-bounce room with checkpoint progression](/en/rooms?id=jump-bounce-room-with-checkpoint-progression).

---

## Script-spawned moving platform (no Radiant needed)

Sometimes you want a moving brush that does not exist in Radiant - e.g. a chase platform that only spawns when a secret is unlocked. Use `spawn()` with classname `"script_model"` + a precached model.

> Model paths come from `xmodel/` in your CoD4 install.

```c
spawn_chase_platform()
{
    // The model MUST be precached in main() with:
    //   precacheModel("ad_sign_diner");

    plat = spawn("script_model", (0, 0, 200));
    plat setModel("ad_sign_diner");
    plat.angles = (0, 90, 0);

    // Move along a path
    plat moveX(500, 4);
    plat waittill("movedone");
    plat moveY(300, 2);
    plat waittill("movedone");

    // Clean up - removes the entity from the world.
    plat delete();
}
```

---

> Next: [Reference](/en/reference) - common builtin patterns and end-of-template footer.
