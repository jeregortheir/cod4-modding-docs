# 🎨 Efekty (FX, Dźwięk, HUD)

Efekty wizualne, triggery dźwięku, własne elementy HUD, ogłoszenia banerowe i jump pady.

---

## FX (efekty wizualne: ogień, iskry, dym, krew)

Trzyetapowy wzorzec:

1. **`loadfx()` w `main()`** - precache'uje efekt (musi być w `main`, NIE w funkcji per-trigger, inaczej crashuje loader assetów).
2. **`playfx()`** by zespawnować jednorazowy efekt na pozycji.
3. **`spawnFx()` + `triggerFx()`** dla trwałego zapętlonego efektu.

> Ścieżki FX są względne do folderu `fx/`. Pliki `.efx` tam mieszkają.

### Setup w `main()`

Dodaj te wywołania do swojej funkcji `main()`, **przed startem jakiegokolwiek wątku**:

```c
level._effect["fire"]      = loadfx("fire/firelp_med_pm");
level._effect["explosion"] = loadfx("explosions/default_explosion");
level._effect["sparks"]    = loadfx("misc/light_marker_red_blink");
```

Potem helpery poniżej używają `level._effect["..."]`, by spawnować instancje.

### Jednorazowy FX na pozycji

Np. eksplozja pułapki przy odpaleniu.

```c
play_fx_explosion_at(origin)
{
    if(!isdefined(level._effect) || !isdefined(level._effect["explosion"])) return;
    playfx(level._effect["explosion"], origin);
}
```

### Trwały zapętlony FX

Np. wieczny płomień przy pochodni. Ustaw `script_origin` w Radiancie tam, gdzie chcesz efekt.

```c
spawn_eternal_fire()
{
    pos = getEnt("origin_torch_fire", "targetname");
    if(!isdefined(pos) || !isdefined(level._effect) || !isdefined(level._effect["fire"])) return;

    fx_ent = spawnfx(level._effect["fire"], pos.origin);
    triggerfx(fx_ent);   // uruchom petle
    // Zeby zatrzymac: fx_ent delete();   (silnik niszczy FX razem z encja)
}
```

---

## Dźwięk: 3D pozycyjny, zapętlony ambient, zmiana muzyki

Aliasy dźwięku pochodzą z pliku `.csv` soundfile twojej mapy. Częste wzorce:

| Funkcja | Zastosowanie |
|---|---|
| `playSoundAtPosition(alias, origin)` | Jednorazowy dźwięk 3D w koordynacie (aktywacja pułapki) |
| `entity playLoopSound(alias)` | Trwała pętla przypięta do encji (wodospad, maszyneria) |
| `ambientPlay(alias)` | Muzyka w tle (zastępuje poprzednią) |
| `player playLocalSound(alias)` | Tylko jeden gracz (np. mrugnięcie teleportu) |

### Przykłady

```c
// Jednorazowy dzwiek w srodku brusha (aktywacja pulapki):
trap_brush = getEnt("trap_brush", "targetname");
playSoundAtPosition("trap_crusher_smash", trap_brush.origin);

// Zapetlony dzwiek przypiety do encji (wodospad, maszyneria):
waterfall = getEnt("waterfall_sound_origin", "targetname");
waterfall playLoopSound("amb_waterfall");
// Zeby zatrzymac: waterfall stopLoopSound();

// Muzyka w tle (wycisza poprzednia, gra nowa):
ambientStop(2);                    // wycisz obecna muzyke w 2 sek
ambientPlay("music_combat_room");  // uruchom nowy utwor

// Tylko jeden gracz (nie przeszkadza innym):
player playLocalSound("teleport_blink");
```

---

## Własny element HUD (timer odliczania, baner)

`newHudElem()` tworzy HUD na poziomie całego levelu, który widzą wszyscy gracze.
`newClientHudElem(player)` tworzy prywatny HUD widoczny tylko dla tego gracza.

> **Uwaga:** każdy gracz ma twardy limit ~31 klienckich HUD-ów. Przekroczenie zawodzi po cichu (HUD jest tworzony, ale nigdy się nie renderuje). Jeśli potrzebujesz HUD-a per-gracz, preferuj nakładki `.menu` sterowane dvarami - zapytaj opiekuna moda.

### Baner odliczania

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
    hud destroy();   // ZAWSZE niszcz po zakonczeniu - inaczej HUD-y wycieka
}
```

---

## Ogłoszenie banerowe (`notifyMessage`)

`notifyMessage` to duży baner, który wyskakuje na górze ekranu z tytułem + podtytułem + czasem trwania. Używaj do ważnych wydarzeń mapy (pierwszy kończący, sekret ukończony, podniesiona specjalna broń).

```c
announce_to_all(title, subtitle, duration)
{
    noti = SpawnStruct();
    noti.titleText  = title;
    noti.notifyText = subtitle;
    noti.glowColor  = (1, 0.5, 0);     // pomaranczowa poswiata
    noti.duration   = duration;
    // Bez ikony: zostaw noti.iconName nieustawione.

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++) {
        if(!isdefined(players[i])) continue;
        players[i] thread maps\mp\gametypes\_hud_message::notifyMessage(noti);
    }
}

// Przyklad uzycia:
//   thread announce_to_all("^3SECRET ROOM", "^7Found by " + player.name, 5);
```

---

## Jump pad (bujający trigger, który wybija gracza w górę)

Dotknij triggera → dodaj prędkość w górę. Helper `braxi\_common::bounce` robi matematykę. Jump pady łączą się (możesz mieć wiele na jednej mapie, wszystkie używają tego samego handlera).

```c
jump_pad()
{
    pads = getentarray("trig_jumppad", "targetname");   // wiele o tej samej nazwie
    for(i = 0; i < pads.size; i++)
        pads[i] thread jump_pad_handler(450);            // 450 = sila odbicia
}

jump_pad_handler(strength)
{
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // Popchnij gracza prosto w gore z dana sila.
        // Kierunek (0,0,1) = czysto pionowo. Dla skosnych padow zmien wektor.
        player braxi\_common::bounce((0, 0, 1), strength);
    }
}
```

### Odbicie warunkowane prędkością (tylko gdy gracz się porusza)

Domyślne jump pady odpalają nawet, gdy gracz po prostu na nich stoi - co może softlockować albo wyglądać glitchowo. Bramkowanie na `getVelocity()[2]` sprawia, że pad reaguje na **spadanie** lub **skok**, nie na stanie.

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

        // vz < -15  = aktualnie spada - odbij go jak trampolina
        // vz >  30  = aktualnie skacze - wzmocnij jego pchniecie w gore
        // -15..30   = mniej wiecej nieruchomy - ignoruj
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

## Ciągła winda / tunel wiatrowy / kolumna antygrawitacyjna

Dla stref, które mają aplikować siłę co klatkę, gdy gracz jest w środku - np. kolumna prądu wznoszącego, w której możesz się unosić. Zobacz [Pułapki → Ciągły boost podczas dotykania](/pl/traps?id=ciągły-boost-podczas-dotykania-utrzymywana-winda-tunel-wiatrowy) po pełny wzorzec.

Różnica względem jump pada: jump pad jest jednorazowy per wejście, tunel wiatrowy jest ciągły, gdy w środku.

---

## Baner z opóźnieniem lub "czekaj na start rundy"

Rozszerzenie `notifyMessage` dla banerów, które mają odpalić w konkretnym czasie:

* `wait_time` - śpij tyle sekund przed pokazaniem banera
* `wait_round_started` - blokuj aż `level notify("round_started")` odpali (zdarzenie silnika, gdy obie drużyny są gotowe i drzwi się otwierają)

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

// Baner powitalny, ktory pokazuje sie 1 sek PO faktycznym starcie rundy:
//   thread notify_message("^3Welcome to Atlantis", "^7Map by YourName", 5, (1, 0.7, 0), 1, true);
```

---

> Dalej: [Zaawansowane](/pl/advanced) - strefy anty-glitch, wydarzenia proximity, losowe pułapki, drzwi VIP, hooki ostatniego jumpera, dynamiczne platformy.
