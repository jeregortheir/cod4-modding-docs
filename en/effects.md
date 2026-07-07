# 🎨 Effects (FX, Sound, HUD)

Visual effects, sound triggers, custom HUD elements, banner announcements, and jump pads.

---

## FX (visual effects: fire, sparks, smoke, blood)

Three-step pattern:

1. **`loadfx()` in `main()`** - precaches the effect (must be in `main`, NOT a per-trigger function, otherwise it crashes the asset loader).
2. **`playfx()`** to spawn a one-shot effect at a position.
3. **`spawnFx()` + `triggerFx()`** for a persistent looping effect.

> FX paths are relative to the `fx/` folder. The `.efx` files live there.

### Setup in `main()`

Add these calls to your `main()` function, **before any thread starts**:

```c
level._effect["fire"]      = loadfx("fire/firelp_med_pm");
level._effect["explosion"] = loadfx("explosions/default_explosion");
level._effect["sparks"]    = loadfx("misc/light_marker_red_blink");
```

Then the helpers below use `level._effect["..."]` to spawn instances.

### One-shot FX at a position

E.g. trap explosion when triggered.

```c
play_fx_explosion_at(origin)
{
    if(!isdefined(level._effect) || !isdefined(level._effect["explosion"])) return;
    playfx(level._effect["explosion"], origin);
}
```

### Persistent looping FX

E.g. eternal flame next to a torch. Place a `script_origin` in Radiant where you want the effect.

```c
spawn_eternal_fire()
{
    pos = getEnt("origin_torch_fire", "targetname");
    if(!isdefined(pos) || !isdefined(level._effect) || !isdefined(level._effect["fire"])) return;

    fx_ent = spawnfx(level._effect["fire"], pos.origin);
    triggerfx(fx_ent);   // start the loop
    // To stop: fx_ent delete();   (engine destroys the FX with the entity)
}
```

---

## Sound: 3D positional, looping ambient, music change

Sound aliases come from your map's `.csv` soundfile. Common patterns:

| Function | Use case |
|---|---|
| `playSoundAtPosition(alias, origin)` | One-shot 3D sound at a coordinate (trap activation) |
| `entity playLoopSound(alias)` | Persistent loop attached to an entity (waterfall, machinery) |
| `ambientPlay(alias)` | Background music (replaces previous) |
| `player playLocalSound(alias)` | One player only (e.g. teleport blink) |

### Examples

```c
// One-shot sound at a brush's center (trap activation):
trap_brush = getEnt("trap_brush", "targetname");
playSoundAtPosition("trap_crusher_smash", trap_brush.origin);

// Looping sound attached to an entity (waterfall, machinery):
waterfall = getEnt("waterfall_sound_origin", "targetname");
waterfall playLoopSound("amb_waterfall");
// To stop: waterfall stopLoopSound();

// Background music (fades out previous, plays new):
ambientStop(2);                    // fade out current music in 2 sec
ambientPlay("music_combat_room");  // start new track

// One player only (does not bother others):
player playLocalSound("teleport_blink");
```

---

## Custom HUD element (countdown timer, banner)

`newHudElem()` creates a level-wide HUD that all players see.
`newClientHudElem(player)` creates a private HUD only that player sees.

> **Warning:** each player has a hard cap of ~31 client HUDs. Going over silently fails (the HUD is created but never renders). If you need a per-player HUD, prefer dvar-driven `.menu` overlays - ask the mod maintainer.

### Countdown banner

```c
show_event_countdown(seconds_left, message)
{
    hud = newHudElem();
    hud.x             = 0;
    hud.y             = 100;
    hud.alignX        = "center";
    hud.alignY        = "middle";
    hud.horzAlign     = "center";
    hud.vertAlign     = "top";
    hud.font          = "objective";
    hud.fontScale     = 2.0;
    hud.color         = (1, 0.7, 0);
    hud.alpha         = 1;
    hud.foreground    = true;

    while(seconds_left > 0)
    {
        hud setText("^3" + message + ": ^7" + seconds_left);
        wait 1;
        seconds_left--;
    }
    hud setText("^2GO!");
    wait 1.5;
    hud destroy();   // ALWAYS destroy when done - HUDs leak otherwise
}
```

---

## Banner announcement (`notifyMessage`)

`notifyMessage` is the big banner that pops up at the top of the screen with title + subtitle + duration. Use for important map events (first finisher, secret completed, special weapon picked up).

```c
announce_to_all(title, subtitle, duration)
{
    noti = SpawnStruct();
    noti.titleText  = title;
    noti.notifyText = subtitle;
    noti.glowColor  = (1, 0.5, 0);     // orange glow
    noti.duration   = duration;
    // No icon: leave noti.iconName unset.

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++) {
        if(!isdefined(players[i])) continue;
        players[i] thread maps\mp\gametypes\_hud_message::notifyMessage(noti);
    }
}

// Example use:
//   thread announce_to_all("^3SECRET ROOM", "^7Found by " + player.name, 5);
```

---

## Jump pad (bouncing trigger that boosts the player up)

Touch trigger → add upward velocity. The `braxi\_common::bounce` helper does the math. Jump pads chain (you can have many on one map, all using the same handler).

```c
jump_pad()
{
    pads = getentarray("trig_jumppad", "targetname");   // multiple by same name
    for(i = 0; i < pads.size; i++)
        pads[i] thread jump_pad_handler(450);            // 450 = bounce strength
}

jump_pad_handler(strength)
{
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // Push the player straight up with given strength.
        // Direction (0,0,1) = pure vertical. For diagonal pads, change vector.
        player braxi\_common::bounce((0, 0, 1), strength);
    }
}
```

### Velocity-conditional bounce (only when player is moving)

Default jump pads fire even when a player is just standing on them - which can softlock or look glitchy. Gating on `getVelocity()[2]` makes the pad react to **falling** or **jumping**, not standing.

```c
bounce_pad_smart()
{
    pad = getEnt("trig_bounce_smart", "targetname");
    if(!isdefined(pad)) return;

    while(true)
    {
        pad waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        vz = player getVelocity()[2];

        // vz < -15  = currently falling - bounce them like a trampoline
        // vz >  30  = currently jumping  - amplify their upward push
        // -15..30   = roughly stationary - ignore
        if(vz < -15) {
            player setVelocity((0, 0, 700));
            player playLocalSound("bounce_sound");
        }
        else if(vz > 30) {
            v = player getVelocity();
            player setVelocity((v[0], v[1], v[2] + 400));
            player playLocalSound("bounce_sound");
        }
    }
}
```

---

## Continuous lift / wind tunnel / antigravity column

For zones that should keep applying force every frame the player is inside - e.g. an updraft column you can hover in. See [Traps → Continuous boost while touching](/en/traps?id=continuous-boost-while-touching-sustained-lift-wind-tunnel) for the full pattern.

Difference vs jump pad: jump pad is one-shot per entry, wind tunnel is continuous while inside.

---

## Banner with delay or "wait for round to start"

Extension of `notifyMessage` for banners that should fire at a specific time:

* `wait_time` - sleep this many seconds before showing the banner
* `wait_round_started` - block until `level notify("round_started")` fires (engine event when both teams are ready and the door opens)

```c
notify_message(title, text, duration, color, wait_time, wait_round_started)
{
    if(isdefined(wait_round_started))
        level waittill("round_started");

    if(isdefined(wait_time))
        wait wait_time;

    noti = SpawnStruct();
    noti.titleText  = title;
    noti.notifyText = text;
    noti.duration   = duration;
    if(isdefined(color)) noti.glowColor = color;

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++) {
        if(!isdefined(players[i])) continue;
        players[i] thread maps\mp\gametypes\_hud_message::notifyMessage(noti);
    }
}

// Welcome banner that shows 1 sec AFTER the round actually starts:
//   thread notify_message("^3Welcome to Atlantis", "^7Map by YourName", 5, (1, 0.7, 0), 1, true);
```

---

> Next: [Advanced](/en/advanced) - anti-glitch zones, proximity events, random traps, VIP doors, last-jumper hooks, dynamic platforms.
