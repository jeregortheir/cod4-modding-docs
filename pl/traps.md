# 💥 Pułapki

Wzorce, których aktywatorzy używają, by zabijać jumperów. Każdy przykład jest **defensywny** - bezpieczny, gdy encji brakuje, gracze się rozłączają albo nie ma aktywatora.

> Pamiętaj, żeby zawołać `addTriggerToList("trig_X")` w `main()` dla każdego naciskanego przez aktywatora triggera stąd. Zobacz [Podstawy](/pl/basics#addtriggertolist---wymagane-dla-triggerow-naciskanych-przez-aktywatora).

---

## Jednorazowy mover brusha (crusher)

Aktywator naciska trigger raz → brush spada z hukiem → pułapka zużyta.

**Wzorzec:** `trigger.delete()` PO pierwszym użyciu, żeby nie mogła odpalić się ponownie.

```c
trap_crusher()
{
    trig  = getEnt("trig_trap_crusher",  "targetname");
    brush = getEnt("brush_trap_crusher", "targetname");
    if(!isdefined(trig) || !isdefined(brush)) return;

    trig setHintString("Press [USE] to crush");

    trig waittill("trigger", user);

    // Opcjonalnie: pozwol odpalic tylko aktywatorom (zablokuj jumperom zabijanie
    // sie wlasna pulapka).
    // Przypomnienie: "axis" = aktywator (czerwony), "allies" = jumperzy (zielony).
    if(!isdefined(user) || !isplayer(user)) return;
    if(user.team != "axis") {
        user iPrintlnBold("^1Only the activator can use this trap");
        return;
    }

    if(isdefined(trig)) trig delete();   // jednorazowe

    brush moveZ(-200, 0.3);
    wait 2;
    brush moveZ(200, 1);
}
```

---

## Ciągła strefa obrażeń (lawa / woda / kolce)

Objętość, która zabija każdego jumpera w środku. Pętla działa w nieskończoność, próbkując co 0.1s każdego gracza dotykającego brusha.

```c
trap_lava()
{
    lava_brush = getEnt("trap_lava_volume", "targetname");
    if(!isdefined(lava_brush)) return;

    while(true)
    {
        // Probkuj wszystkich graczy. Ta petla ZAWSZE czeka, wiec nie moze
        // zawiesic serwera nawet przy zerowej liczbie graczy.
        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            // Defensywnie pomijaj martwych/rozlaczonych graczy.
            if(!isValidPlayer(players[i])) continue;

            // Zabijaj tylko jumperow (allies). Aktywator (axis) przez to przechodzi.
            if(players[i].team != "allies") continue;

            if(players[i] istouching(lava_brush))
                players[i] suicide();
        }
        wait 0.1;
    }
}
```

---

## Cyklicznie kręcąca się / poruszająca przeszkoda

Wzorzec dla pułapek, które ruszają się same bez triggera. Użyj `endon`, żeby czysto zatrzymać je na koniec rundy.

```c
trap_spinner()
{
    obj = getEnt("trap_spinner_obj", "targetname");
    if(!isdefined(obj)) return;

    level endon("endround");  // zatrzymaj petle, gdy runda sie konczy

    while(true)
    {
        if(!isdefined(obj)) return;
        obj rotateYaw(360, 3);  // pelny obrot w 3 sek
        wait 3;
        // Nie trzeba kolejnego wait - rotateYaw blokuje watek na czas swojego
        // trwania. Endon powyzej zabija watek czysto w polowie obrotu,
        // jesli runda sie konczy.
    }
}
```

---

## Pułapka wieloetapowa (złączona sekwencja z timingiem)

Częsty wzorzec: pociągnij dźwignię → grzmot → 2 sek opóźnienia → ściana się wysuwa → kolce spadają → reset po 30 sek.

Każdy etap to osobny ruch, który blokuje aż do zakończenia; użyj `waittill("movedone")` dla dokładnego timingu.

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

        // Etap 1: dzwignia opada
        lever rotatePitch(80, 0.3);
        lever waittill("rotatedone");

        // Etap 2: pauza na grzmot
        wait 1;
        playSoundAtPosition("rumble_low", wall.origin);

        // Etap 3: sciana wsuwa sie w korytarz
        wall moveX(-200, 1.5);
        wall waittill("movedone");

        // Etap 4: kolce spadaja
        spikes moveZ(-100, 0.4);
        spikes waittill("movedone");

        // Etap 5: trzymaj 5 sek, by dac jumperom czas na smierc
        wait 5;

        // Etap 6: reset
        spikes moveZ(100, 1);
        wall   moveX(200, 2);
        lever  rotatePitch(-80, 0.5);
        wait 3;
        // gotowe na kolejna aktywacje
    }
}
```

---

## Pułapka z cooldownem (zapobiega spamowi aktywatora)

Bez cooldownu aktywator może walić `[USE]` i re-odpalać pułapkę co klatkę. Wzorzec: śledź czas ostatniego odpalenia na samej encji triggera, pozwalaj ponownie dopiero po N sekundach.

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

        // helper canUse() - zobacz Podstawy
        if(!canUse(trig, 10)) {
            user iPrintln("^1Trap on cooldown");
            continue;
        }

        // ...tu akcja pulapki...
        iPrintlnBold("^3" + user.name + " ^7fired the trap!");
    }
}
```

---

## Jednorazowy per-gracz boost (wzorzec flagi debounce)

Wzorzec "pojedyncze odpalenie póki w triggerze, uzbrój ponownie, gdy gracz wyjdzie". Używany dla każdego boostu / jump-pada / tunelu wiatrowego, który NIE ma spamować co klatkę, gdy gracz jest w środku.

Trik: ostempluj gracza unikatowym atrybutem-flagą, gdy wchodzi, zespawnuj wątek-obserwatora, który czyści flagę, gdy gracz opuszcza objętość triggera.

> **Wybierz nazwę flagi, która raczej się nie zderzy** z niczym innym - albo długi losowy string (`player.boost_active_jzx91`), albo opisowa nazwa z prefiksem (`player.boost_trap_3_active`). Dwie pułapki używające tej samej nazwy flagi będą ze sobą walczyć.

```c
trap_speed_boost()
{
    trig = getEnt("trig_speed_boost", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.boost_speed_active)) continue;   // juz zboostowany

        player.boost_speed_active = true;
        player thread _reset_boost_speed(trig);

        // Wlasciwy jednorazowy efekt:
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

## Ciągły boost podczas dotykania (utrzymywana winda / tunel wiatrowy)

Wariant powyższego dla efektów, które mają być **aplikowane co klatkę**, gdy gracz jest w środku, nie tylko raz. Częste dla szybów w górę, taśmociągów, antygrawitacji.

```c
trap_wind_tunnel()
{
    trig = getEnt("trig_wind_tunnel", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.in_wind_tunnel)) continue;   // juz utrzymywany

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
        self setVelocity((vel[0], vel[1], 600));   // utrzymywane Z w gore
        wait 0.05;
    }
    self.in_wind_tunnel = undefined;
}
```

> `wait 0.05` jest krytyczne - bez niego pętla wpada w zabójcę opcodeów CoD4X.

---

## Pułapka wielokrotnego upadku (N żyć przed samobójstwem)

Przyjaźniejsza niż natychmiastowa śmierć. Gracz dostaje N "prób" - każda porażka teleportuje go z powrotem na bezpieczny origin. Licznik resetuje się przy śmierci.

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

        // Pierwsze wejscie w tym zyciu - przyznaj 2 proby.
        if(!isdefined(player.fall_tries)) {
            player.fall_tries = 2;
            player thread _reset_fall_tries_on_death();
        }

        if(player.fall_tries > 0) {
            player setVelocity((0, 0, 0));   // wybij ped
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

## Szturchnięcie anty-utknięcie (uwolnij gracza zaklinowanego w geometrii)

Gdy złożony collider może zaklinować gracza w miejscu, licz tiki, które spędza dotykając triggera. Po przekroczeniu progu popchnij go w stronę znanego wolnego punktu.

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
            // Policz kierunek pchniecia w strone punktu ucieczki + troche uniesienia.
            dir = vectorNormalize((center.origin + (0, 0, 800)) - self.origin);
            self setVelocity(dir * 600);
            self iPrintln("^3Unstuck");
            wait 1;     // daj predkosci chwile, by opuscic objetosc
            break;
        }
    }
    self.stuck_watch_active = undefined;
}
```

---

## Strzałka kierunku pułapki (wizualna podpowiedź podążająca za strefą triggera)

Wiele map spawnuje unoszące się strzałki wskazujące na przycisk pułapki. Pokazywanie ich tylko graczom aktualnie w strefie triggera utrzymuje czysty ekran dla wszystkich innych.

**W Radiancie:** utwórz jedną lub więcej encji `script_model` (dowolny model strzałki) o nazwie `<trap_name>_arrow` blisko triggera. Będą domyślnie ukryte, a potem `ShowToPlayer` per dotykający gracz.

```c
arrow_logic(trap_name, trigger)
{
    // Zatrzymuje petle per-klatka w momencie, gdy pulapka odpala - zobacz arrow_kill_notify.
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

// Lagodne bujanie gora-dol, zeby strzalka czytala sie jako zywa.
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

// Gdy pulapka odpala, zabij petle strzalek ORAZ skasuj modele strzalek.
arrow_kill_notify(trap_name)
{
    level notify(trap_name);

    arrows = getentarray(trap_name + "_arrow", "targetname");
    for(i = 0; i < arrows.size; i++)
        if(isdefined(arrows[i])) arrows[i] delete();
}
```

**Wpięcie tego w pułapkę:**

```c
trap_crusher()
{
    trig  = getEnt("trig_trap_crusher",  "targetname");
    brush = getEnt("brush_trap_crusher", "targetname");
    if(!isdefined(trig) || !isdefined(brush)) return;

    thread arrow_logic("trap_crusher", trig);   // <-- pokazuje strzalki

    trig waittill("trigger", user);
    if(!isValidPlayer(user)) return;

    arrow_kill_notify("trap_crusher");          // <-- ukrywa + kasuje strzalki

    brush moveZ(-200, 0.3);
    // ...reszta logiki crushera
}
```

---

## Strzel-by-aktywować (przycisk, do którego strzelasz, nie naciskasz)

Dla strzelanych przycisków, tłukącego się szkła, ukrytych sekretów. Użyj `waittill("damage", ...)` zamiast `"trigger"`. Hook obrażeń odpala, gdy brush przyjmie JAKIEKOLWIEK obrażenia powyżej progu.

**W Radiancie:** brush musi być `script_brushmodel` z ustawionym `health` na liczbę dodatnią (np. 100). Gdy health osiągnie 0, odpala `"damage"`.

```c
shootable_secret_button()
{
    btn = getEnt("button_shoot_secret", "targetname");
    if(!isdefined(btn)) return;

    btn waittill("damage", amount, attacker);
    if(!isValidPlayer(attacker)) return;

    iPrintlnBold("^5" + attacker.name + " ^7found the shootable secret!");
    btn delete();   // usun przycisk, zeby nie mozna bylo do niego znowu strzelic

    // Otworz ukryte drzwi
    door = getEnt("door_shoot_secret", "targetname");
    if(isdefined(door)) door moveZ(150, 1.5);
}
```

---

> Dalej: [Pokoje](/pl/rooms) - pokoje walki (snajper / nóż) i trasy sekretne.
