# ⚔️ Pokoje (Walka i Sekret)

Teleportery, pokoje walki na broń i trasy sekretne z nagrodami XP. Wzorzec pokoju walki to **najbardziej podatny na crash kod w mapach Deathrun** - kopiuj ostrożnie i zachowaj każdy guard.

---

## Teleporter

Gracz wchodzi w trigger → teleportuje się do encji `script_origin` ustawionej w Radiancie. `setOrigin` przenosi pozycję, `setPlayerAngles` ustawia kierunek patrzenia.

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

        // Opcjonalnie: mala wizualna informacja zwrotna, by gracz wiedzial, ze sie teleportowal.
        player playLocalSound("teleport_blink");
    }
}
```

---

## Pokój walki (snajper / nóż / AK end-room)

Gracz odpala objętość "pokoju broni" → gracz i aktywator są teleportowani do stref walki, dostają pasujące bronie, są na chwilę zamrożeni na odliczanie, a potem uwolnieni do walki.

> **KRYTYCZNE:** każda linia dotykająca `activator` lub `player` jest zabezpieczona guardem. Gdy to kopiujesz, **NIE** usuwaj guardów. Ten wzorzec spowodował więcej crashy wydanych map niż cokolwiek innego.

### Pokój snajperski

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

        // Guard 1: gracz zniknal miedzy triggerem a teraz.
        if(!isValidPlayer(player)) continue;

        // Guard 2: GetActivator() zwraca string "Noactivator", gdy nikt
        // nie jest na axis. isplayer() zwraca false dla stringow, wiec to
        // lapie oba przypadki (undefined + string Noactivator).
        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintlnBold("^1No activator - room unavailable");
            continue;
        }

        // -- Ustaw obu graczy --
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

        // Odliczanie 3..2..1..GO. Sprawdzaj ponownie isalive/isplayer CO sekunde,
        // bo kazda ze stron moze umrzec podczas odliczania (np. zabicie przez
        // pulapke inna akcja aktywatora).
        for(c = 3; c >= 1; c--) {
            if(isalive(player))                              player    iPrintLnBold("^5" + c);
            if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^5" + c);
            wait 1;
        }
        if(isalive(player))                              player    iPrintLnBold("^7FIGHT!");
        if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^7FIGHT!");

        if(isalive(player))                              player    freezeControls(false);
        if(isplayer(activator) && isalive(activator))    activator freezeControls(false);

        // Czekaj, az gracz umrze lub wyjdzie, zanim pozwolisz na nowe wejscie.
        while(isdefined(player) && isalive(player))
            wait 1;
    }
}
```

### Pokój na nóż (wariant)

Ten sam szkielet, inna broń. Skopiuj pokój snajperski i zmień `m40a3_mp` na `knife_mp` (i usuń linie z amunicją - nóż nie ma amunicji).

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

## Wyłączność wielu pokoi (jeden pokój naraz)

Wiele map ma **kilka** end-roomów (snajper / nóż / jump / launcher) i chce zablokować pozostałe, gdy walka trwa. Wzorzec:

1. Gdy walka się zaczyna, gracz uruchamia na sobie `disable_triggers_untill_death()`.
2. Ten helper wyłącza trigger wejścia każdego innego pokoju przez `triggerOff()`.
3. Następnie usypia na `waittill_any("death", "disconnect")`.
4. Gdy gracz umrze (lub wyjdzie), włącza wszystkie triggery z powrotem.

```c
// Zapisz referencje triggerow raz w main(), zeby kazdy pokoj mogl je widziec.
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

Wepnij to w dowolny pokój walki **po** przejściu guardów aktywatora/gracza:

```c
trig waittill("trigger", player);
if(!isValidPlayer(player)) continue;
activator = GetActivator();
if(!isplayer(activator)) continue;

player thread disable_triggers_untill_death();    // <-- blokuje inne pokoje
// ...reszta setupu pokoju walki...
```

---

## Baner HUD walki ("Player vs Activator - Sniper Room")

Duży baner na górze ekranu pokazywany przez ~3 sek, gdy walka się zaczyna. Samoanulujący się - jeśli druga walka zacznie się, zanim pierwszy baner wygaśnie, nowy baner zastępuje stary (wzorzec anulowania przez notify).

```c
fightHUD(room_name, jumper, activ)
{
    self endon("disconnect");
    self notify("fightHUD_active");      // anuluj kazdy wczesniejszy baner
    self endon("fightHUD_active");        // zostan anulowany przez kolejny start

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

> Sloty `level.hud_fight` i `level.hud_fight2` są **współdzielone** przez wszystkie pokoje - to celowe. Dwie walki nie mogą pokazać swojego banera jednocześnie (druga anuluje pierwszą). Jeśli chcesz HUD-y per pokój, użyj unikatowych nazw slotów level per pokój.

---

## Dopracowany szablon pokoju walki (z helperami)

Zwięźlejsza wersja pokoju snajperskiego powyżej, używająca helperów z [Podstawy → Helpery narzędziowe](/pl/basics?id=helpery-narzędziowe-kopiuj-je-dosłownie). Zachowanie jest identyczne, ciało jest o połowę mniejsze.

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

Żeby zrobić wariant Knife / RPG / SMG tego samego pokoju, skopiuj tę funkcję i zmień string broni + nazwę pokoju.

---

## Pokój jump-bounce z progresją checkpointów

Pokój ze skokami-łamigłówką, gdzie gracz respawnuje się na **ostatnim osiągniętym checkpoincie** zamiast na starcie. Zrealizowany z per-gracz progresją (`player.jump_room_pos`) i dynamicznym lookupem targetname.

**W Radiancie:**
* Cele bounce-padów o nazwach `bounce_jumper_1`, `bounce_jumper_2`, `bounce_jumper_3`, ... (encje `script_origin` znaczące pozycję respawnu)
* Triggery checkpointów o nazwach `bounce_jumper_2_trig`, `bounce_jumper_3_trig`, ... przy wejściu na każdy wyższy poziom
* Trigger porażki `bounce_fail_jumper` pokrywający dołek śmierci

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

jump_room_fail(side)        // side = "jumper" lub "acti"
{
    fallback = getEnt("bounce_" + side + "_1", "targetname");
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(!isdefined(player.jump_room_pos)) player.jump_room_pos = 1;

        // Znajdz spawn dla aktualnego checkpointu gracza.
        ent = getEnt("bounce_" + side + "_" + player.jump_room_pos, "targetname");
        if(!isdefined(ent)) ent = fallback;     // siatka bezpieczenstwa na brakujace encje
        if(!isdefined(ent)) continue;

        player setVelocity((0, 0, 0));
        player setOrigin(ent.origin);
        player setPlayerAngles(ent.angles);
        player freeze_on_tps(0.05);
    }
}
```

> Linia `if(!isdefined(ent)) ent = fallback` to to, co cię ratuje, jeśli encja z Radianta zostanie przemianowana albo skasowana - gracz nadal respawnuje się gdzieś, zamiast żeby funkcja po cichu zawiodła.

---

## Trasa sekretna z nagrodą XP

Gracz znajduje sekretne wejście, odpala je raz → teleport do startu sekretu + oznaczenie dla leaderboardu. Dotarcie do końca sekretu daje bonusowe XP.

```c
secret_easy()
{
    enter_trig = getEnt("trig_secret_enter",    "targetname");
    enter_pos  = getEnt("origin_secret_start",  "targetname");
    end_trig   = getEnt("trig_secret_end",      "targetname");
    end_pos    = getEnt("origin_secret_end",    "targetname");
    if(!isdefined(enter_trig) || !isdefined(enter_pos)) return;

    // Zespawnuj watek obslugujacy trigger KONCA osobno (zeby wielu
    // graczy moglo byc w sekrecie jednoczesnie).
    if(isdefined(end_trig) && isdefined(end_pos))
        thread secret_easy_end(end_trig, end_pos);

    while(true)
    {
        enter_trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(player.team != "allies") continue;   // tylko jumperzy

        player setOrigin(enter_pos.origin);
        player setPlayerAngles(enter_pos.angles);

        // tagSecret(N) oznacza run gracza jako przejscie trasy sekretnej N.
        // Wymagane dla leaderboardu per-trasa. N = 1, 2 lub 3 (pasuje do
        // vlct_secret_count i vlct_secret_N_name ustawionych w main()).
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
        player braxi\_rank::giveRankXP("", 500);   // 500 XP za ukonczenie
        iPrintlnBold("^5" + player.name + " ^7completed the easy secret!");
    }
}
```

---

> Dalej: [Efekty](/pl/effects) - FX, dźwięk, własne HUD-y, ogłoszenia banerowe, jump pady.
