# 👋 Podstawy + Hello World

Szkielet, którego potrzebuje każda mapa, plus twoja pierwsza działająca funkcja.

---

## `main()` - zestaw startowy

Każda mapa MUSI mieć funkcję `main()`. Silnik woła ją automatycznie przy ładowaniu mapy.

> **Uwaga:** jeśli wkleisz linię `thread foo();`, ale NIE zdefiniujesz też funkcji `foo()` gdzieś w swoim pliku, mapa **się nie skompiluje**.

```c
main()
{
    // ZAWSZE pierwsze: laduje systemy silnika (spawnpointy, hooki trybu gry,
    // bronie). Bez tego wywolania mapa w ogole nie ruszy.
    //   maps\mp\_load to plik maps/mp/_load.gsc
    //   ::main()      znaczy "wywolaj jego funkcje main()"
    maps\mp\_load::main();

    // Obrazenia od upadku off (konwencja Deathrun: upadek ma zabijac tylko
    // przez pulapki mapy, nie przez waniliowy wzor fall-damage z CoD).
    SetDvar("bg_falldamagemaxheight", 99999);
    SetDvar("bg_falldamageminheight", 99998);

    // Liczba sekretow dla systemu leaderboardu.
    // Ustaw vlct_secret_count na tyle, ile tras sekretnych ma twoja mapa (0-3).
    setDvar("vlct_secret_count", 1);
    setDvar("vlct_secret_1_name", "Cut");
    // setDvar("vlct_secret_2_name", "Hard");
    // setDvar("vlct_secret_3_name", "Pro");

    // Przelacznik debugu. Ustaw na `true` podczas developmentu, zeby widziec
    // wiadomosci debugPrint() w qconsole.log. Ustaw z powrotem na `false` przed wydaniem.
    level.debug = false;

    // Watki.
    //   `thread X()` = "uruchom X() w tle, nie czekaj na nia".
    //   Kazdy trwaly system (petla pulapki, obserwator triggera) potrzebuje
    //   wlasnego watku, zeby moc dzialac w nieskonczonosc bez blokowania innych.
    thread simple_door_example();    // Hello World - nizej
    thread startdoor();              // tez nizej
    // thread trap_crusher();           <- odkomentuj, jesli ja zbudujesz
    // thread combat_room_sniper();     <- odkomentuj, jesli ja zbudujesz
    // thread secret_easy();
    // thread reset_traps_on_round_end();

    // ZAREJESTRUJ TRIGGERY PULAPEK - zobacz sekcje nizej
    // addTriggerToList("trig_trap_crusher");
    // addTriggerToList("trig_trap_lava_button");
}
```

---

## `addTriggerToList()` - WYMAGANE dla triggerów naciskanych przez aktywatora

To **helper konwencji** - sam mod go nie definiuje, każda mapa musi zawierać dokładnie tę funkcję (albo skopiować ją z dowolnej istniejącej mapy).

```c
addTriggerToList(targetname)
{
    if(!isdefined(level.trapTriggers))
        level.trapTriggers = [];

    ent = getEnt(targetname, "targetname");
    if(!isdefined(ent)) return;       // po cichu pomin literowki / usuniete brushe

    level.trapTriggers[level.trapTriggers.size] = ent;
}
```

**Dlaczego każdy trigger zwrócony do aktywatora musi być zarejestrowany:**

Mod czyta `level.trapTriggers[]` w `zec/_main.gsc::_init()` tuż po tym, jak twoje `main()` się zakończy, a następnie:

1. Buduje `level.activator_traps[]`, żeby admini / VIP-y mogli odpalić pułapkę zdalnie z menu "Activate Trap" w sklepie.
2. Spawnuje per-trigger wątek nagrody XP / coinów dla aktywatora.

Jeśli zapomnisz zawołać `addTriggerToList()`, pułapka nadal działa dla jumperów, ale **aktywator nie dostaje XP ani coinów** za jej użycie ORAZ nie pojawia się ona w sklepie.

> NIE rejestruj triggerów sekretów, teleporterów ani przycisków tylko-dla-jumperów.

---

## Helpery narzędziowe (kopiuj je dosłownie)

Te krótkie funkcje istnieją, żeby wybić najczęstszy boilerplate. Ich użycie sprawia, że twoja mapa jest 2x czytelniejsza ORAZ trudniej ją zepsuć.

### `isValidPlayer(p)` - jednowywołaniowy guard gracza

```c
// Zastepuje:   if(!isdefined(p) || !isplayer(p) || !isalive(p)) continue;
// Przez:       if(!isValidPlayer(p)) continue;
isValidPlayer(p)
{
    return isdefined(p) && isplayer(p) && isalive(p);
}
```

Używaj go na każdym wyniku `waittill("trigger", player)`, każdym sprawdzeniu `level.activ`, każdej iteracji pętli `level.players[i]`.

### `safeGetEnt(name)` - `getEnt`, które nigdy nie crashuje na duplikatach

```c
// `getEnt("foo", "targetname")` rzuca blad, jesli wiecej niz jedna encja w Radiancie
// dzieli te nazwe. Ten wrapper spada na `getentarray()[0]`.
// Zwraca undefined, gdy zadna encja nie istnieje - wolajacy MUSI i tak sprawdzic isdefined.
safeGetEnt(targetname)
{
    arr = getentarray(targetname, "targetname");
    if(!isdefined(arr) || arr.size == 0) return undefined;
    return arr[0];
}
```

### `canUse(ent, delay_sec)` - bramka cooldownu dla ponownego użycia pułapki

Anty-spam dla pułapek sterowanych przez aktywatora. Pierwsze wywołanie zwraca `true` i stempluje encję przez `getTime()`. Kolejne wywołania w ciągu `delay_sec` zwracają `false`. Po wygaśnięciu okna resetuje się automatycznie.

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

**Typowe użycie:**

```c
while(true) {
    trig waittill("trigger", user);
    if(!isValidPlayer(user)) continue;
    if(!canUse(trig, 10)) {
        user iPrintln("^1Trap on cooldown");
        continue;
    }
    // ...odpal pulapke...
}
```

### `freeze_on_tps(time)` - zablokuj gracza na chwilę po teleporcie

Po `setOrigin` gracz może zachować prędkość sprzed teleportu i "wyślizgnąć się" z celu. Zamrożenie sterowania na kilka klatek to naprawia. Rozbicie odmrożenia na osobny wątek sprawia, że wołający się nie blokują.

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

**Typowe użycie** (po każdym `setOrigin`):

```c
player setOrigin(dest.origin);
player setPlayerAngles(dest.angles);
player freeze_on_tps(0.05);    // maly freeze tylko po to, by wybic pęd
```

Dla pokoi PvP używaj dłuższego freeze (3-4 sek), który zgrywa się z odliczaniem.

### `countdown_timer_string(time, end_string, color)` - 3..2..1..GO

Wielorazowy baner odliczania. Używany przez każdą arenę PvP przed startem walki.

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

**Typowe użycie:**

```c
player    freeze_on_tps(4);
activator freeze_on_tps(4);
thread countdown_timer_string(4, "^1FIGHT!", "^3");
```

### `GetActivator()` - bezpieczny override, który nigdy nie zwraca stringa `"Noactivator"`

`level.activ` (ustawiane przez wbudowane `GetActivator` moda) to **string** `"Noactivator"`, gdy nikt nie jest na axis. To psuje każde wywołanie `if(isdefined(level.activ)) level.activ setOrigin(...)` (string przechodzi `isdefined`, potem crashuje na metodzie).

Ten lokalny override iteruje po `players` i zwraca `undefined`, gdy żaden żywy gracz axis nie istnieje - więc pojedynczy guard `if(!isplayer(activator))` w miejscu wywołania wystarczy.

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

**Typowe użycie:**

```c
activator = GetActivator();
if(!isplayer(activator)) {
    player iPrintln("^1No activator - room unavailable");
    continue;
}
activator setOrigin(ac_pos.origin);   // bezpieczne: activator to prawdziwy gracz
```

> Zdefiniowanie własnego `GetActivator()` przesłania wbudowane **tylko wewnątrz `.gsc` tej mapy** - inne pliki dalej używają oryginału. To dokładnie to, czego chcemy.

### `debugPrint(msg)` - logowanie tylko do konsoli

Ustaw `level.debug = true;` na górze `main()`, żeby widzieć swoje wiadomości w `qconsole.log` podczas playtestu. Ustaw z powrotem na `false` przed wydaniem. Używa `println()`, które idzie tylko do konsoli serwera, nie do klienta.

```c
debugPrint(msg)
{
    if(isdefined(level.debug) && level.debug)
        println("[MAP] " + msg);
}
```

---

## Hello World - najprostszy możliwy przykład

> Przeczytaj to najpierw. To **6 linii faktycznego kodu**. Gdy zrozumiesz, co robi każda linia, każda inna sekcja tego przewodnika nabierze sensu.

**Co robi:** gdy gracz wejdzie w trigger o nazwie `hello_trig`, wypisuje `"Hello, <nazwagracza>!"` do wszystkich.

**W Radiancie potrzebujesz:**
* brusha przerobionego na `trigger_multiple`
* z KVP `targetname` = `hello_trig`

```c
simple_door_example()
{
    // 1. Znajdz trigger po jego targetname z Radianta.
    trig = getEnt("hello_trig", "targetname");

    // 2. Jesli trigger nie istnieje (zly targetname / usuniety brush),
    //    po cichu przerwij. Lepsze niz crash pozniej.
    if(!isdefined(trig)) return;

    // 3. Czekaj w nieskonczonosc, reagujac na kazde odpalenie triggera.
    while(true)
    {
        // 4. Pauza az gracz wejdzie w trigger. Encja gracza
        //    zwracana jest w `player`.
        trig waittill("trigger", player);

        // 5. Gracz mogl sie rozlaczyc / umrzec miedzy odpaleniem triggera
        //    a tym, gdy odzyskamy CPU. `isValidPlayer` lapie wszystkie
        //    trzy zle przypadki (undefined / nie-gracz / martwy).
        if(!isValidPlayer(player)) continue;

        // 6. Wypisz powitanie do wszystkich graczy.
        iPrintlnBold("^5Hello, " + player.name + "!");
    }
}
```

---

## Start door - pierwszy prawdziwy wzorzec

Większość map Deathrun ma barierę, która otwiera się, gdy runda faktycznie się zaczyna (jumperzy i aktywator ustawieni). Używa `level waittill("round_started")`, żeby zareagować na to zdarzenie silnika.

```c
startdoor()
{
    door = getEnt("startdoor", "targetname");
    if(!isdefined(door)) return;

    // Czekaj, az runda faktycznie sie zacznie.
    level waittill("round_started");

    // Otworz o 200 jednostek w ciagu 2 sekund.
    door moveZ(200, 2);
}
```

---

> Dalej: [Pułapki](/pl/traps) - wzorce, których aktywatorzy używają, by zabijać jumperów.
