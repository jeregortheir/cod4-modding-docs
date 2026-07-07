# 💥 Traps

Patterns activators use to kill jumpers. Every example is **defensive** - safe when entities are missing, players disconnect, or there is no activator.

> Remember to call `addTriggerToList("trig_X")` in `main()` for every activator-pressed trigger here. See [Basics](/en/basics#addtriggertolist---required-for-activator-pressed-triggers).

---

## One-shot brush mover (crusher)

Activator hits trigger once → brush slams down → trap consumed.

**Pattern:** `trigger.delete()` AFTER first use so it cannot fire again.

```c
trap_crusher()
{
    trig  = getEnt("trig_trap_crusher",  "targetname");
    brush = getEnt("brush_trap_crusher", "targetname");
    if(!isdefined(trig) || !isdefined(brush)) return;

    trig setHintString("Press [USE] to crush");

    trig waittill("trigger", user);

    // Optional: only let activators trigger it (block jumpers from killing
    // themselves with their own trap).
    // Reminder: "axis" = activator (red), "allies" = jumpers (green).
    if(!isdefined(user) || !isplayer(user)) return;
    if(user.team != "axis") {
        user iPrintlnBold("^1Only the activator can use this trap");
        return;
    }

    if(isdefined(trig)) trig delete();   // single-use

    brush moveZ(-200, 0.3);
    wait 2;
    brush moveZ(200, 1);
}
```

---

## Continuous damage zone (lava / water / spikes)

A volume that kills any jumper inside it. Loop runs forever, sampling every 0.1s for any player touching the brush.

```c
trap_lava()
{
    lava_brush = getEnt("trap_lava_volume", "targetname");
    if(!isdefined(lava_brush)) return;

    while(true)
    {
        // Sample all players. This loop ALWAYS waits, so it cannot hang
        // the server even if there are zero players.
        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            // Skip dead/disconnected players defensively.
            if(!isValidPlayer(players[i])) continue;

            // Only kill jumpers (allies). Activator (axis) walks through it.
            if(players[i].team != "allies") continue;

            if(players[i] istouching(lava_brush))
                players[i] suicide();
        }
        wait 0.1;
    }
}
```

---

## Periodic spinning / moving obstacle

Pattern for traps that move on their own without trigger. Use `endon` to cleanly stop them at round end.

```c
trap_spinner()
{
    obj = getEnt("trap_spinner_obj", "targetname");
    if(!isdefined(obj)) return;

    level endon("endround");  // stop loop when round ends

    while(true)
    {
        if(!isdefined(obj)) return;
        obj rotateYaw(360, 3);  // full spin in 3 sec
        wait 3;
        // No need for another wait - rotateYaw blocks the thread for its
        // duration. The endon above kills the thread cleanly mid-rotation
        // if round ends.
    }
}
```

---

## Multi-stage trap (chained sequence with timing)

Common pattern: pull lever → rumble → 2 sec delay → wall slides → spikes drop → reset after 30 sec.

Each stage is a separate move that blocks until done; use `waittill("movedone")` for accurate timing.

```c
trap_chain_sequence()
{
    trig    = getEnt("trig_trap_chain",   "targetname");
    lever   = getEnt("lever_trap_chain",  "targetname");
    wall    = getEnt("wall_trap_chain",   "targetname");
    spikes  = getEnt("spikes_trap_chain", "targetname");
    if(!isdefined(trig) || !isdefined(lever) || !isdefined(wall) || !isdefined(spikes)) return;

    trig setHintString("Press [USE] to start the chain trap");

    while(true)
    {
        trig waittill("trigger", user);
        if(!isValidPlayer(user)) continue;
        if(user.team != "axis") continue;

        // Stage 1: lever pulls down
        lever rotatePitch(80, 0.3);
        lever waittill("rotatedone");

        // Stage 2: rumble pause
        wait 1;
        playSoundAtPosition("rumble_low", wall.origin);

        // Stage 3: wall slides into corridor
        wall moveX(-200, 1.5);
        wall waittill("movedone");

        // Stage 4: spikes drop
        spikes moveZ(-100, 0.4);
        spikes waittill("movedone");

        // Stage 5: hold for 5 sec to give jumpers time to die
        wait 5;

        // Stage 6: reset
        spikes moveZ(100, 1);
        wall   moveX(200, 2);
        lever  rotatePitch(-80, 0.5);
        wait 3;
        // ready for next activation
    }
}
```

---

## Trap with cooldown (prevent activator spam)

Without a cooldown, an activator can mash `[USE]` and re-fire a trap every frame. Pattern: track last-fired time on the trigger entity itself, only re-allow after N seconds.

```c
trap_with_cooldown()
{
    trig = getEnt("trig_trap_cooldown", "targetname");
    if(!isdefined(trig)) return;
    trig setHintString("Press [USE] to fire (10s cooldown)");

    while(true)
    {
        trig waittill("trigger", user);
        if(!isValidPlayer(user)) continue;

        // canUse() helper - see Basics
        if(!canUse(trig, 10)) {
            user iPrintln("^1Trap on cooldown");
            continue;
        }

        // ...do the trap action here...
        iPrintlnBold("^3" + user.name + " ^7fired the trap!");
    }
}
```

---

## One-shot per-player boost (debounce flag pattern)

The "single fire while inside the trigger, re-arm when player leaves" pattern. Used for any boost / jump-pad / wind-tunnel that should NOT spam every frame the player is inside.

The trick: stamp the player with a unique flag attribute when they enter, spawn a watcher thread that clears the flag when the player leaves the trigger volume.

> **Pick a flag name unlikely to collide** with anything else - either a long random string (`player.boost_active_jzx91`) or a descriptive prefixed name (`player.boost_trap_3_active`). Two traps using the same flag name will fight each other.

```c
trap_speed_boost()
{
    trig = getEnt("trig_speed_boost", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.boost_speed_active)) continue;   // already boosted

        player.boost_speed_active = true;
        player thread _reset_boost_speed(trig);

        // The actual one-shot effect:
        vel = player getVelocity();
        player setVelocity((vel[0] * 1.5, vel[1] * 1.5, vel[2]));
        player playLocalSound("speed_boost");
    }
}

_reset_boost_speed(trigger)
{
    self endon("disconnect");
    while(self isTouching(trigger))
        wait 0.05;
    self.boost_speed_active = undefined;
}
```

---

## Continuous boost while touching (sustained lift / wind tunnel)

Variant of the above for effects that should be **applied every frame** the player is inside, not just once. Common for upward shafts, conveyor belts, antigravity.

```c
trap_wind_tunnel()
{
    trig = getEnt("trig_wind_tunnel", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.in_wind_tunnel)) continue;   // already maintaining

        player.in_wind_tunnel = true;
        player thread _wind_tunnel_maintain(trig);
    }
}

_wind_tunnel_maintain(trigger)
{
    self endon("disconnect");
    while(self isTouching(trigger))
    {
        vel = self getVelocity();
        self setVelocity((vel[0], vel[1], 600));   // sustained upward Z
        wait 0.05;
    }
    self.in_wind_tunnel = undefined;
}
```

> The `wait 0.05` is critical - without it the loop trips the CoD4X opcode killer.

---

## Multi-try fall trap (N lives before suicide)

Friendlier than instant death. Player gets N "tries" - each fail teleports them back to a safe origin. Counter resets on death.

```c
trap_fall_with_lives()
{
    trig    = getEnt("trig_fall_zone",    "targetname");
    safe_at = getEnt("origin_safe_spawn", "targetname");
    if(!isdefined(trig) || !isdefined(safe_at)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // First entry this life - grant 2 tries.
        if(!isdefined(player.fall_tries)) {
            player.fall_tries = 2;
            player thread _reset_fall_tries_on_death();
        }

        if(player.fall_tries > 0) {
            player setVelocity((0, 0, 0));   // kill momentum
            player setOrigin(safe_at.origin);
            player setPlayerAngles(safe_at.angles);
            player iPrintln("Tries left: ^2" + player.fall_tries);
            player.fall_tries--;
        } else {
            player iPrintln("^1No more tries");
            player suicide();
            player.fall_tries = undefined;
        }
    }
}

_reset_fall_tries_on_death()
{
    self endon("disconnect");
    self waittill("death");
    self.fall_tries = undefined;
}
```

---

## Anti-stuck nudge (free a player wedged in geometry)

When a complex collider can wedge a player in place, count ticks they spend touching the trigger. After a threshold, push them toward a known clear point.

```c
trap_antistuck_zone()
{
    trig   = getEnt("trig_stuck_zone",     "targetname");
    center = getEnt("origin_stuck_escape", "targetname");
    if(!isdefined(trig) || !isdefined(center)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.stuck_watch_active)) continue;

        player.stuck_watch_active = 1;
        player thread _stuck_watcher(trig, center);
    }
}

_stuck_watcher(trigger, center)
{
    self endon("disconnect");

    while(self isTouching(trigger))
    {
        wait 0.1;
        self.stuck_watch_active++;
        if(self.stuck_watch_active > 10)
        {
            // Compute push direction toward the escape point + a bit of lift.
            dir = vectorNormalize((center.origin + (0, 0, 800)) - self.origin);
            self setVelocity(dir * 600);
            self iPrintln("^3Unstuck");
            wait 1;     // give the velocity a moment to clear the volume
            break;
        }
    }
    self.stuck_watch_active = undefined;
}
```

---

## Trap-direction arrow (visual hint that follows trigger zone)

Many maps spawn floating arrows pointing at the trap button. Showing them only to players currently inside the trigger zone keeps the screen clean for everyone else.

**In Radiant:** create one or more `script_model` entities (any arrow model) named `<trap_name>_arrow` near the trigger. They will be hidden by default, then `ShowToPlayer` per touching player.

```c
arrow_logic(trap_name, trigger)
{
    // Stops the per-frame loop the moment the trap fires - see arrow_kill_notify.
    level endon(trap_name);

    arrows = getentarray(trap_name + "_arrow", "targetname");
    for(i = 0; i < arrows.size; i++)
        arrows[i] thread _arrow_bob();

    while(true)
    {
        wait 0.05;
        players = getentarray("player", "classname");
        touching = [];
        for(i = 0; i < players.size; i++) {
            if(isValidPlayer(players[i]) && players[i] isTouching(trigger))
                touching[touching.size] = players[i];
        }
        for(j = 0; j < arrows.size; j++) {
            if(!isdefined(arrows[j])) continue;
            arrows[j] hide();
            for(k = 0; k < touching.size; k++)
                arrows[j] showToPlayer(touching[k]);
        }
    }
}

// Gentle up-and-down bob so the arrow reads as alive.
_arrow_bob()
{
    self endon("death");
    forward    = anglesToForward(self.angles);
    initial    = self.origin;
    moveto_pos = self.origin + (forward * 30);
    while(true) {
        self moveTo(moveto_pos, 1.5, 0.5, 0.5);   wait 1.6;
        self moveTo(initial,    1.5, 0.5, 0.5);   wait 1.6;
    }
}

// When the trap fires, kill the arrow loop AND delete the arrow models.
arrow_kill_notify(trap_name)
{
    level notify(trap_name);

    arrows = getentarray(trap_name + "_arrow", "targetname");
    for(i = 0; i < arrows.size; i++)
        if(isdefined(arrows[i])) arrows[i] delete();
}
```

**Wiring it into a trap:**

```c
trap_crusher()
{
    trig  = getEnt("trig_trap_crusher",  "targetname");
    brush = getEnt("brush_trap_crusher", "targetname");
    if(!isdefined(trig) || !isdefined(brush)) return;

    thread arrow_logic("trap_crusher", trig);   // <-- shows arrows

    trig waittill("trigger", user);
    if(!isValidPlayer(user)) return;

    arrow_kill_notify("trap_crusher");          // <-- hides + deletes arrows

    brush moveZ(-200, 0.3);
    // ...rest of crusher logic
}
```

---

## Shoot-to-activate (button you fire at, not press)

For shootable buttons, breakable glass, hidden secrets. Use `waittill("damage", ...)` instead of `"trigger"`. The damage hook fires when the brush takes ANY damage above threshold.

**In Radiant:** brush must be a `script_brushmodel` with `health` set to a positive number (e.g. 100). When health reaches 0 it fires `"damage"`.

```c
shootable_secret_button()
{
    btn = getEnt("button_shoot_secret", "targetname");
    if(!isdefined(btn)) return;

    btn waittill("damage", amount, attacker);
    if(!isValidPlayer(attacker)) return;

    iPrintlnBold("^5" + attacker.name + " ^7found the shootable secret!");
    btn delete();   // remove the button so it cannot be re-shot

    // Open hidden door
    door = getEnt("door_shoot_secret", "targetname");
    if(isdefined(door)) door moveZ(150, 1.5);
}
```

---

> Next: [Rooms](/en/rooms) - combat rooms (sniper / knife) and secret routes.
