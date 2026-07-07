# ⚔️ Rooms (Combat & Secret)

Teleporters, weapon-fight rooms, and secret routes with XP rewards. The combat-room pattern is the **most crash-prone code in Deathrun maps** - copy carefully and keep every guard.

---

## Teleporter

Player walks into trigger → teleports to a `script_origin` entity placed in Radiant. `setOrigin` moves position, `setPlayerAngles` sets view direction.

```c
teleport_skip()
{
    trig = getEnt("trig_teleport_skip",  "targetname");
    dest = getEnt("origin_teleport_skip", "targetname");
    if(!isdefined(trig) || !isdefined(dest)) return;

    trig setHintString("Press [USE] to skip ahead");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        player setOrigin(dest.origin);
        player setPlayerAngles(dest.angles);

        // Optional: small visual feedback so the player knows they teleported.
        player playLocalSound("teleport_blink");
    }
}
```

---

## Combat room (sniper / knife / AK end-room)

Player triggers a "weapon room" volume → player and activator are teleported to fight zones, given matching weapons, frozen briefly for countdown, then released to fight.

> **CRITICAL:** every line that touches `activator` or `player` is guarded. When you copy this, do **NOT** remove the guards. This pattern has caused more shipped-map crashes than anything else.

### Sniper room

```c
combat_room_sniper()
{
    trig    = getEnt("trig_combat_sniper",          "targetname");
    jp_pos  = getEnt("origin_combat_sniper_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_sniper_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Sniper Room");

    while(true)
    {
        trig waittill("trigger", player);

        // Guard 1: player vanished between trigger and now.
        if(!isValidPlayer(player)) continue;

        // Guard 2: GetActivator() returns the string "Noactivator" when no
        // one is on axis. isplayer() returns false for strings, so this
        // catches both cases (undefined + Noactivator string).
        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintlnBold("^1No activator - room unavailable");
            continue;
        }

        // -- Setup both players --
        player    setOrigin       (jp_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setOrigin       (ac_pos.origin);
        activator setPlayerAngles (ac_pos.angles);

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("m40a3_mp");
        activator giveWeapon("m40a3_mp");
        player    giveMaxAmmo("m40a3_mp");
        activator giveMaxAmmo("m40a3_mp");
        player    switchToWeapon("m40a3_mp");
        activator switchToWeapon("m40a3_mp");

        player    freezeControls(true);
        activator freezeControls(true);

        iPrintLnBold("^5" + player.name + " ^7vs ^5" + activator.name + " ^7- Sniper Room");

        // Countdown 3..2..1..GO. Re-check isalive/isplayer EVERY second
        // because either party can die during the countdown (e.g. trap kill
        // by another activator action).
        for(c = 3; c >= 1; c--) {
            if(isalive(player))                              player    iPrintLnBold("^5" + c);
            if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^5" + c);
            wait 1;
        }
        if(isalive(player))                              player    iPrintLnBold("^7FIGHT!");
        if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^7FIGHT!");

        if(isalive(player))                              player    freezeControls(false);
        if(isplayer(activator) && isalive(activator))    activator freezeControls(false);

        // Wait until player dies or leaves before allowing a new entry.
        while(isdefined(player) && isalive(player))
            wait 1;
    }
}
```

### Knife room (variant)

Same skeleton, different weapon. Copy the sniper room and change `m40a3_mp` to `knife_mp` (and remove the ammo lines - knife has no ammo).

```c
combat_room_knife()
{
    trig    = getEnt("trig_combat_knife",          "targetname");
    jp_pos  = getEnt("origin_combat_knife_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_knife_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Knife Room");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintlnBold("^1No activator - room unavailable");
            continue;
        }

        player    setOrigin       (jp_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setOrigin       (ac_pos.origin);
        activator setPlayerAngles (ac_pos.angles);

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("knife_mp");
        activator giveWeapon("knife_mp");
        player    switchToWeapon("knife_mp");
        activator switchToWeapon("knife_mp");

        iPrintLnBold("^6" + player.name + " ^7entered the Knife Room");

        while(isdefined(player) && isalive(player))
            wait 1;
    }
}
```

---

## Multi-room exclusivity (one room at a time)

Many maps have **several** end-rooms (sniper / knife / jump / launcher) and want to lock the others while a fight is in progress. Pattern:

1. When a fight starts, the player runs `disable_triggers_untill_death()` on themselves.
2. That helper turns off every other room's entry trigger using `triggerOff()`.
3. It then sleeps on `waittill_any("death", "disconnect")`.
4. When the player dies (or leaves), it re-enables all triggers.

```c
// Save trigger refs once in main() so any room can see them.
//   level.knife_trigger    = getEnt("trig_combat_knife",  "targetname");
//   level.sniper_trigger   = getEnt("trig_combat_sniper", "targetname");
//   level.jump_trigger     = getEnt("trig_combat_jump",   "targetname");
//   level.launcher_trigger = getEnt("trig_combat_rpg",    "targetname");

disable_triggers_untill_death()
{
    if(isdefined(level.knife_trigger))    level.knife_trigger    thread maps\mp\_utility::triggerOff();
    if(isdefined(level.sniper_trigger))   level.sniper_trigger   thread maps\mp\_utility::triggerOff();
    if(isdefined(level.jump_trigger))     level.jump_trigger     thread maps\mp\_utility::triggerOff();
    if(isdefined(level.launcher_trigger)) level.launcher_trigger thread maps\mp\_utility::triggerOff();

    self common_scripts\utility::waittill_any("death", "disconnect");

    if(isdefined(level.knife_trigger))    level.knife_trigger    thread maps\mp\_utility::triggerOn();
    if(isdefined(level.sniper_trigger))   level.sniper_trigger   thread maps\mp\_utility::triggerOn();
    if(isdefined(level.jump_trigger))     level.jump_trigger     thread maps\mp\_utility::triggerOn();
    if(isdefined(level.launcher_trigger)) level.launcher_trigger thread maps\mp\_utility::triggerOn();
}
```

Wire it into any combat room **after** the activator/player guards pass:

```c
trig waittill("trigger", player);
if(!isValidPlayer(player)) continue;
activator = GetActivator();
if(!isplayer(activator)) continue;

player thread disable_triggers_untill_death();    // <-- locks other rooms
// ...rest of combat room setup...
```

---

## Fight HUD banner ("Player vs Activator - Sniper Room")

Big top-of-screen banner shown for ~3 sec when a fight starts. Self-cancelling - if a second fight starts before the first banner times out, the new banner replaces the old one (notify-cancellation pattern).

```c
fightHUD(room_name, jumper, activ)
{
    self endon("disconnect");
    self notify("fightHUD_active");      // cancel any prior banner
    self endon("fightHUD_active");        // get cancelled by the next start

    jumper_name = "?";
    activ_name  = "?";
    if(isplayer(jumper)) jumper_name = jumper.name;
    if(isplayer(activ))  activ_name  = activ.name;

    duration = 3;

    if(isdefined(level.hud_fight))  level.hud_fight  destroy();
    if(isdefined(level.hud_fight2)) level.hud_fight2 destroy();

    level.hud_fight = newHudElem();
    level.hud_fight.x = 0;            level.hud_fight.y = 85;
    level.hud_fight.alignX = "center";  level.hud_fight.alignY = "top";
    level.hud_fight.horzAlign = "center"; level.hud_fight.vertAlign = "top";
    level.hud_fight.font = "objective"; level.hud_fight.fontScale = 1.5;
    level.hud_fight.alpha = 1;
    level.hud_fight setText("^3" + room_name);

    level.hud_fight2 = newHudElem();
    level.hud_fight2.x = 0;            level.hud_fight2.y = 100;
    level.hud_fight2.alignX = "center";  level.hud_fight2.alignY = "top";
    level.hud_fight2.horzAlign = "center"; level.hud_fight2.vertAlign = "top";
    level.hud_fight2.font = "objective"; level.hud_fight2.fontScale = 1.5;
    level.hud_fight2.alpha = 1;
    level.hud_fight2 setText("^3" + jumper_name + " ^7VS ^3" + activ_name);

    wait duration;

    if(isdefined(level.hud_fight))  level.hud_fight  destroy();
    if(isdefined(level.hud_fight2)) level.hud_fight2 destroy();
}
```

> The `level.hud_fight` and `level.hud_fight2` slots are **shared** across all rooms - that is intentional. Two fights cannot show their banner simultaneously (the second cancels the first). If you want per-room HUDs, use unique level slot names per room.

---

## Polished combat-room template (with helpers)

Tighter version of the sniper room above using the helpers from [Basics → Utility helpers](/en/basics?id=utility-helpers). Behavior is identical, the body is half the size.

```c
combat_room_sniper_v2()
{
    trig    = getEnt("trig_combat_sniper",          "targetname");
    jp_pos  = getEnt("origin_combat_sniper_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_sniper_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Sniper Room");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintln("^1No Activator Detected");
            continue;
        }
        if(player == activator) {
            player iPrintln("^1Activator Can't Enter Room");
            continue;
        }

        player thread disable_triggers_untill_death();
        thread fightHUD("Sniper Room", player, activator);

        player    setOrigin       (jp_pos.origin);
        activator setOrigin       (ac_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setPlayerAngles (ac_pos.angles);

        player    freeze_on_tps(4);
        activator freeze_on_tps(4);
        thread countdown_timer_string(4, "^1FIGHT!", "^3");

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("m40a3_mp");
        activator giveWeapon("m40a3_mp");
        player    switchToWeapon("m40a3_mp");
        activator switchToWeapon("m40a3_mp");

        player.health    = player.maxhealth;
        activator.health = activator.maxhealth;

        while(isdefined(player) && isalive(player))
            wait 0.05;
    }
}
```

To make a Knife / RPG / SMG variant of the same room, copy this function and change the weapon string + room name.

---

## Jump-bounce room with checkpoint progression

A jump-puzzle room where the player respawns at the **last checkpoint they reached** instead of the start. Implemented with per-player progress (`player.jump_room_pos`) and dynamic targetname lookup.

**In Radiant:**
* Bounce-pad targets named `bounce_jumper_1`, `bounce_jumper_2`, `bounce_jumper_3`, ... (`script_origin` entities marking respawn pos)
* Checkpoint triggers named `bounce_jumper_2_trig`, `bounce_jumper_3_trig`, ... at the entrance to each higher level
* A fail trigger `bounce_fail_jumper` covering the death pit

```c
jump_room_setup()
{
    cp_2 = getEnt("bounce_jumper_2_trig", "targetname");
    cp_3 = getEnt("bounce_jumper_3_trig", "targetname");
    cp_4 = getEnt("bounce_jumper_4_trig", "targetname");
    if(isdefined(cp_2)) cp_2 thread jump_room_checkpoint(2);
    if(isdefined(cp_3)) cp_3 thread jump_room_checkpoint(3);
    if(isdefined(cp_4)) cp_4 thread jump_room_checkpoint(4);

    fail = getEnt("bounce_fail_jumper", "targetname");
    if(isdefined(fail)) fail thread jump_room_fail("jumper");
}

jump_room_checkpoint(index)
{
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(!isdefined(player.jump_room_pos)) player.jump_room_pos = 1;

        if(player.jump_room_pos < index) {
            player iPrintln("^3Checkpoint ^2" + (index - 1));
            player.jump_room_pos = index;
        }
    }
}

jump_room_fail(side)        // side = "jumper" or "acti"
{
    fallback = getEnt("bounce_" + side + "_1", "targetname");
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(!isdefined(player.jump_room_pos)) player.jump_room_pos = 1;

        // Look up the spawn for the player's current checkpoint.
        ent = getEnt("bounce_" + side + "_" + player.jump_room_pos, "targetname");
        if(!isdefined(ent)) ent = fallback;     // safety net for missing entities
        if(!isdefined(ent)) continue;

        player setVelocity((0, 0, 0));
        player setOrigin(ent.origin);
        player setPlayerAngles(ent.angles);
        player freeze_on_tps(0.05);
    }
}
```

> The `if(!isdefined(ent)) ent = fallback` line is what saves you if a Radiant entity gets renamed or deleted - the player still respawns somewhere instead of the function silently failing.

---

## Secret route with XP reward

Player finds the secret entrance, triggers it once → teleport to secret start + tag for the leaderboard. Reaching the secret end gives bonus XP.

```c
secret_easy()
{
    enter_trig = getEnt("trig_secret_enter",    "targetname");
    enter_pos  = getEnt("origin_secret_start",  "targetname");
    end_trig   = getEnt("trig_secret_end",      "targetname");
    end_pos    = getEnt("origin_secret_end",    "targetname");
    if(!isdefined(enter_trig) || !isdefined(enter_pos)) return;

    // Spawn a thread that handles the END trigger separately (so multiple
    // players can be in the secret simultaneously).
    if(isdefined(end_trig) && isdefined(end_pos))
        thread secret_easy_end(end_trig, end_pos);

    while(true)
    {
        enter_trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(player.team != "allies") continue;   // only jumpers

        player setOrigin(enter_pos.origin);
        player setPlayerAngles(enter_pos.angles);

        // tagSecret(N) marks the player's run as having taken secret route N.
        // Required for the per-route leaderboard. N = 1, 2, or 3 (matches
        // vlct_secret_count and vlct_secret_N_name set in main()).
        player zec\_secrets::tagSecret(1);

        iPrintlnBold("^5" + player.name + " ^7entered the easy secret");
    }
}

secret_easy_end(end_trig, end_pos)
{
    while(true)
    {
        end_trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        player setOrigin(end_pos.origin);
        player setPlayerAngles(end_pos.angles);
        player braxi\_rank::giveRankXP("", 500);   // 500 XP for completing
        iPrintlnBold("^5" + player.name + " ^7completed the easy secret!");
    }
}
```

---

> Next: [Effects](/en/effects) - FX, sound, custom HUDs, banner announcements, jump pads.
