# 📚 Reference

Quick-lookup cheat sheet for common GSC builtins. Copy-paste straight into your map.

---

## Common builtin patterns

### Wait until ANY of multiple notifies

Whichever fires first wakes the function up.

```c
self common_scripts\utility::waittill_any("death", "disconnect", "spawned");
```

### Make a brush walk-through but still visible

For visual-only fences.

```c
mybrush notsolid();
mybrush solid();    // restore collision
```

### Hide / show a brush (visual only, not collision)

```c
mybrush hide();
mybrush show();
```

### Move / rotate primitives

All are async - return immediately, finish over time.

```c
ent moveZ(distance, time);       // up
ent moveY(distance, time);       // sideways
ent moveX(distance, time);       // forward
ent rotateYaw  (degrees, time);
ent rotatePitch(degrees, time);
ent rotateRoll (degrees, time);
```

To wait for a movement to finish:

```c
ent moveZ(100, 2);
ent waittill("movedone");        // for rotates: "rotatedone"
```

### Sound

```c
playSoundAtPosition("sound_alias", entity.origin);   // 3D one-shot
player playLocalSound("sound_alias");                 // one player only
ambientStop(2);                                       // fade-out 2 sec
ambientPlay("music_alias");                           // start new track
```

### Player movement speed

`1.0` = default 210, `0.95` = 190, `1.5` = fast.

```c
player setMoveSpeedScale(1.5);
```

> ❌ **DO NOT** use `setmovespeed()` or `setgravity()` - those crash the server.

### Spawn a script entity at runtime

Rare, usually use Radiant.

```c
ent = spawn("script_origin", (0, 0, 0));
ent.angles = (0, 90, 0);
```

### Disable / re-enable a trigger from script

```c
trig thread maps\mp\_utility::triggerOff();
trig thread maps\mp\_utility::triggerOn();
```

### Print to all players

```c
iPrintln("plain message");
iPrintlnBold("BIG centered message");
```

### Print to one player only

```c
player iPrintln    ("for you only");
player iPrintlnBold("for you only - bold");
```

---

## Map credits (one-time message at round start)

```c
map_credits()
{
    wait 8;   // let players spawn first
    iPrintln("^3Map by ^5YourName ^7- thanks for playing!");
    wait 5;
    iPrintln("^3Tested by: ^5tester1, tester2");
}
```

---

## Reset traps on round end (best practice)

If your traps mutate brush positions or delete things, on the next round Radiant will RE-create the entities (entities reset every round_restart). But if you have `level.X` variables tracking state, reset them here.

```c
reset_traps_on_round_end()
{
    while(true)
    {
        level waittill("endround");

        // Clear any flags we set during the round.
        // Example:
        // level.crusher_used = undefined;
    }
}
```

---

## Color codes

CoD4 uses `^N` color codes inside any string. Examples:

| Code | Color | Common use |
|---|---|---|
| `^0` | Black | unused / outline |
| `^1` | Red | warnings, danger |
| `^2` | Green | success, jumpers |
| `^3` | Yellow / orange | info, neutral |
| `^4` | Blue | links, hints |
| `^5` | Cyan | feature highlights |
| `^6` | Pink | special events |
| `^7` | White | default text |
| `^8` | Color of player team | team-aware text |
| `^9` | Color of opposing team | enemy-aware text |

Example:

```c
iPrintLnBold("^5" + player.name + " ^7entered the ^1HARD ^7Secret!");
```

---

## Got a snippet to add?

If you have a recipe that works on the live server (and uses the defensive helpers), share it on the [VLCT Discord](https://vlct.mxme.pro/discord) and we will add it to this guide.

* Found this guide useful? Tell other mappers in your language - and help us translate the page you used most.
* Found a bug in an example? Report it on Discord.
* Found a non-existent CoD4X builtin in someone's map (anything like `setmovespeed`)? Tell us so we can add it to [Before you code → Anti-patterns](/en/before-you-code).

---

> 🏠 [Back to Home](/en/)
