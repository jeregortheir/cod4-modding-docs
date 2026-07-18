# 🚀 Zaawansowane wzorce

Rzadsze, ale wyjątkowo użyteczne. Każdy to prawdziwy wzorzec z wydanych map.

---

## Strefa anty-glitch (zabij graczy, którzy uciekną poza granice mapy)

Umieść duży `trigger_multiple` pokrywający wszystkie obszary poza granicami. Każdy w środku umiera.

> Użyj `trigger_hurt` w Radiancie, jeśli chcesz go zawsze-włączonego. Użyj tego wzorca skryptowego, jeśli chcesz **warunkowego** zabijania (np. tylko jeśli nie w spectatorze).

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

## Śledzenie pozycji gracza (wydarzenie proximity)

Czasem nie możesz użyć triggera (np. brak dostępu do Radianta, dynamiczna strefa). Próbkuj pozycje graczy na timerze i reaguj, gdy któryś jest w zasięgu punktu.

> **Trzymaj timer hojnie (>= 0.5 sek)** - ta pętla działa w nieskończoność i po KAŻDYM graczu.

```c
proximity_watcher()
{
    target_pos = getEnt("origin_proximity_target", "targetname");
    if(!isdefined(target_pos)) return;

    radius_squared = 100 * 100;   // 100 jednostek. Do kwadratu, by pominac sqrt() w petli.

    while(true)
    {
        wait 0.5;

        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            p = players[i];
            if(!isValidPlayer(p)) continue;
            if(p.team != "allies") continue;

            // distance2() to odleglosc do kwadratu - tansze niz distance().
            if(distance2(p.origin, target_pos.origin) < radius_squared)
            {
                if(!isdefined(p.in_proximity_zone))
                {
                    p.in_proximity_zone = true;
                    p iPrintln("^5You feel something nearby...");
                    // Odpal wydarzenie RAZ na gracza na runde.
                }
            }
        }
    }
}
```

---

## Losowy selektor pułapek (inna pułapka każdą rundę)

Na starcie rundy wybierz jeden wariant pułapki z puli. Użyj `randomInt()` i switcha na wyniku. Wariacja utrzymuje mapę świeżą.

```c
random_trap_choice()
{
    level waittill("round_started");

    pick = randomInt(3);   // 0, 1 lub 2

    switch(pick)
    {
        case 0:  thread trap_variant_fire();     break;
        case 1:  thread trap_variant_water();    break;
        case 2:  thread trap_variant_spikes();   break;
    }
}

// Warianty-zaslepki - wypelnij jak normalna pulapke.
trap_variant_fire()   { /* getEnt + thread loop */ }
trap_variant_water()  { /* getEnt + thread loop */ }
trap_variant_spikes() { /* getEnt + thread loop */ }
```

---

## Drzwi tylko dla VIP / mappera

Ogranicz trigger do konkretnych Steam GUID-ów (ciebie, znajomych). Przydatne do ukrytych pokoi tylko-dla-twórcy, które pokazują rzeczy zza kulis.

```c
mapper_only_door()
{
    trig = getEnt("trig_mapper_door", "targetname");
    door = getEnt("door_mapper",      "targetname");
    if(!isdefined(trig) || !isdefined(door)) return;

    // Zastap swoimi prawdziwymi Steam GUID-ami.
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

## Czekaj aż wszyscy jumperzy martwi (hook końca rundy)

Odpal wydarzenie w momencie śmierci OSTATNIEGO jumpera (np. zagraj dźwięk zwycięstwa, zespawnuj FX świętowania dla aktywatora). Zbudowane na próbkowaniu `level.players` + `isalive`.

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
            // Wszyscy jumperzy martwi. Odpal swoje wydarzenie, potem break.
            iPrintlnBold("^1All jumpers eliminated");
            // ...zespawnuj FX, zagraj dzwiek, daj aktywatorowi XP itd.
            return;
        }
    }
}
```

---

## Generyczny helper teleportera (`teleporter_logic`)

Zastępuje ~20 linii kopiuj-wklej boilerplate'u teleportu jedną sparametryzowaną funkcją. Opcjonalny freeze, opcjonalny callback odpalający po teleporcie (wskaźnik funkcji przez `[[ ]]()`).

```c
//   trigger     - encja triggera, na ktora czekamy
//   exit_ent    - cel (script_origin)
//   set_angles  - jesli true, ustaw tez katy patrzenia gracza na exit_ent.angles
//   freeze      - sekundy zamrozenia sterowania po teleporcie (undefined = brak freeze)
//   on_arrive   - wskaznik funkcji do wywolania na graczu po teleporcie (lub undefined)
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

**Wpięcie tego w `main()`:**

```c
// Zwykly teleporter, bez callbacku:
trig = getEnt("trig_teleport_skip",   "targetname");
dest = getEnt("origin_teleport_skip", "targetname");
thread teleporter_logic(trig, dest, true, undefined, undefined);

// Teleporter do strefy sekretnej, uruchamia per-gracz callback setupu po przybyciu:
trig = getEnt("trig_secret_enter", "targetname");
dest = getEnt("origin_secret",     "targetname");
thread teleporter_logic(trig, dest, true, 0.05, ::on_enter_secret);

on_enter_secret()
{
    self setVelocity((180, 180, 0));      // wystrzel gracza w level
    self.secret_streak = 0;               // init stanu per-gracz
    self iPrintln("^5Secret entered");
}
```

> Składnia `::function_name` tworzy wskaźnik funkcji; `[[ptr]]()` go wywołuje. Wskaźniki można przekazywać jako parametry - tak buduje się wielorazowe abstrakcje w GSC.

---

## Wzorzec pojedynczej instancji wątku (anulowanie przez notify)

Gdy funkcja powinna mieć **co najwyżej jedną działającą instancję per encja naraz** - HUD-y, pętle uzupełniania amunicji, timery statusu - trik polega na zaczęciu od `notify` i `endon` na tej samej nazwie. Każde późniejsze wywołanie anuluje poprzednie.

```c
single_instance_thread()
{
    self notify("foo_running");      // anuluj kazda wczesniejsza instancje
    self endon("foo_running");        // zostan anulowany przez kolejny start
    self endon("disconnect");
    self endon("death");

    // ...wlasciwa petla / jednorazowa praca...
    while(true)
    {
        // rob cos
        wait 0.5;
    }
}
```

**Przykład z życia** - utrzymuj amunicję jednej broni pełną, aż gracz umrze lub funkcja zostanie wywołana ponownie:

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

// Kazde wywolanie zastepuje poprzednie - bezpieczne do wywolania dwa razy z rzedu.
//   activator thread keep_ammo_topped("h2_m79a_mp", 1);
```

---

## Brama, która otwiera się tylko dla oznaczonych graczy

Brush, który staje się przechodni (`notSolid`) tylko wtedy, gdy **co najmniej jeden** gracz z konkretną flagą go dotyka. Używane do drzwi "przejścia w trybie ducha", bram tras sekretnych, barier VIP.

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

> Cykl przebudzenia to 0.1 sek - wystarczająco dobry dla bramy drzwi, ale nie schodź niżej bez potrzeby (każdy gracz jest próbkowany co tick).

---

## Respawn z detekcją strony (po której stronie pokoju spadli?)

Częste w pokojach PvP: dołek aktywatora teleportuje go z powrotem na spawn acti, dołek jumpera na spawn jumpera. Użyj `script_origin` umieszczonego na linii podziału i porównaj X (lub Y, zależnie od osi twojej mapy).

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

        // Porownaj na tej osi, ktora dzieli pokoj (tu X).
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

> Progresja wielu checkpointów (respawn na ostatnim osiągniętym checkpoincie zamiast na starcie) mieszka w [Pokoje → Pokój jump-bounce z progresją checkpointów](/pl/rooms?id=pokój-jump-bounce-z-progresją-checkpointów).

---

## Platforma ruchoma zespawnowana skryptem (bez Radianta)

Czasem chcesz ruchomy brush, który nie istnieje w Radiancie - np. platforma pościgu, która spawnuje się dopiero, gdy sekret zostanie odblokowany. Użyj `spawn()` z classname `"script_model"` + precache'owanym modelem.

> Ścieżki modeli pochodzą z `xmodel/` w twojej instalacji CoD4.

```c
spawn_chase_platform()
{
    // Model MUSI byc precache'owany w main() przez:
    //   precacheModel("ad_sign_diner");

    plat = spawn("script_model", (0, 0, 200));
    plat setModel("ad_sign_diner");
    plat.angles = (0, 90, 0);

    // Poruszaj sie po sciezce
    plat moveX(500, 4);
    plat waittill("movedone");
    plat moveY(300, 2);
    plat waittill("movedone");

    // Sprzatanie - usuwa encje ze swiata.
    plat delete();
}
```

---

> Dalej: [Wzorce wbudowane](/pl/reference) - popularne wzorce wbudowane i stopka końca szablonu.
