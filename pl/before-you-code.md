# ⚠️ Zanim napiszesz kod

Prawdziwe bugi, na które trafiliśmy w wydanych mapach. Przeczytaj to raz przed napisaniem pierwszej pułapki, **potem** przejrzyj ponownie przed commitem.

---

## Anty-wzorce - TEGO NIE RÓB

### ❌ Pusta pętla bez `wait` w gałęzi fałszywej

```c
while(isalive(player))
    if(isdefined(level.activ))
        wait 1;
// Gdy level.activ jest undefined, wewnętrzny if jest fałszywy, żaden wait
// się nie wykonuje, CPU kręci się w kółko aż silnik zabije wątek.
```

✅ **Fix:** zawsze miej `wait` w ciele pętli, nawet w gałęzi fałszywej.

```c
while(isalive(player)) {
    if(isdefined(level.activ))
        doActivatorWork();
    wait 1;
}
```

---

### ❌ Wywołanie metody na `level.activ` bez sprawdzenia `isplayer()`

```c
level.activ setOrigin(p.origin);
// Crash gdy nie ma gracza axis - level.activ jest STRINGIEM "Noactivator".
```

✅ **Fix:**

```c
if(isplayer(level.activ))
    level.activ setOrigin(p.origin);
```

---

### ❌ Synchroniczne wywołanie funkcji, która wewnętrznie robi `waittill`

```c
player respawnLater();    // blokuje bieżący wątek aż do śmierci
```

To **prawie zawsze** błąd. Chodziło ci o:

```c
player thread respawnLater();
```

---

### ❌ `getEnt` z duplikatem `targetname`

```c
door = getEnt("door", "targetname");
// Jeśli dwa brushe dzielą targetname "door" -> silnik rzuca błąd, a door jest undefined.
```

✅ **Fix:** użyj helpera `safeGetEnt` (zobacz [Podstawy](/pl/basics#utility-helpers)):

```c
door = safeGetEnt("door");
if(!isdefined(door)) return;
```

---

### ❌ Usunięcie już usuniętej encji

```c
level.trig delete();
// Drugie wywołanie (np. z chain-delete innego pokoju) crashuje.
```

✅ **Fix:**

```c
if(isdefined(level.trig)) level.trig delete();
```

---

### ❌ Polskie / nie-angielskie stringi albo em-dashe w plikach `.gsc`

```c
// Pulapka aktywujaca sie po wejsciu gracza    <- ŹLE (polski)
// Trap that fires when the player enters       <- DOBRZE (angielski)
```

Silnik CoD4X nie renderuje znaków specjalnych spójnie. **Komentarze ORAZ stringi in-game muszą być po angielsku.**

Em-dash `—` (U+2014) renderuje się jako śmieci. Używaj zwykłego `-` (myślnik).

---

### ❌ `&"..."` ze zwykłym stringiem w `setHintString`

```c
trig setHintString( &"Press ^3&&1 ^7to enter" );
// FATALNY przy ładowaniu mapy: "Illegal localized string reference ... must contain
// only alpha-numeric characters and underscores"
```

Prefiks `&` oznacza **referencję do stringa zlokalizowanego** - nazwa po nim musi być poprawnym identyfikatorem (`&"SCRIPT_HINT_ENTER"`), a nie zdaniem ze spacjami, kodami koloru i `&&1`. Ten błąd **kładzie serwer na ładowaniu**, więc kryje się, dopóki mapa nie zostanie faktycznie zagrana.

✅ **Fix:** wywal `&`. Zwykły string obsługuje `&&1` i kody koloru bez problemu:

```c
trig setHintString( "Press ^3&&1 ^7to enter" );
```

---

### ❌ Off-by-one: `i <= array.size`

```c
for(i = 0; i <= players.size; i++)
    players[i] ...;
// Ostatni przebieg to players[players.size] = undefined -> lawina błędów z JEDNEJ linii.
```

`i <= size` zawsze robi jedną iterację za końcem. Nigdy nie jest tym, o co ci chodzi.

✅ **Fix:** `i < players.size`.

---

### ❌ `for` / `if` bez klamer bierze tylko następną linię

```c
for(i = 0; i < parts.size; i++)

    playSound("tick");        // <- JEDYNA rzecz w pętli
    parts[i] thread spin();   // <- wykonuje się RAZ, po pętli, z i poza zakresem
```

`for`/`if` bez klamer bierze dokładnie następną instrukcję. Pusta linia nie pomaga. Daje to **cichą** awarię - bez błędu, feature po prostu nigdy nie działa.

✅ **Fix:** zawsze klamruj ciała pętli i warunków.

---

?> **Wiele z tych błędów wypisuje komunikat i leci dalej** - nie są fatalne, więc zepsuta mapa "działa" latami, aż ktoś włączy `logfile`. Gdy audytujesz mapę, nie ufaj "nigdy nie było problemów": jeśli `.gsc` woła `getEnt("thing")`, a `.bsp` nie ma encji o nazwie `thing` (częste, gdy skrypt pisano pod inną wersję mapy), to zawodzi **za każdym razem**, po cichu. Fixem jest guard (`if(isdefined(...))`), nie wymyślanie brakującej encji.

---

## Częste błędy - checklista na jedną minutę

Przelećże ten skan w głowie przed każdym commitem:

| Objaw | Prawdopodobna przyczyna |
|---|---|
| `Brak wait w ciele pętli` | Wątek zabity / zwis serwera |
| `level.activ setOrigin(...)` bez guarda | Crash gdy nie ma gracza axis |
| `getEnt("name", ...)` na duplikacie | "used with more than one entity" |
| Odwołanie do `.origin` na undefined | "undefined is not a field object" |
| Synchroniczne wywołanie funkcji robiącej `waittill("death")` | Wołający blokuje się do jej powrotu - miało być `thread`? |
| Zapomniany `addTriggerToList(...)` dla triggerów aktywatora | Aktywator nie dostaje nagrody za naciśnięcie twojej pułapki |
| Zahardkodowane polskie / nie-angielskie stringi albo em-dash | Śmieciowe glify + wygląda nieprofesjonalnie |
| `&"..."` ze spacjami/kodami koloru w `setHintString` | FATALNY "illegal localized string reference" na ładowaniu mapy |
| `for(i=0; i<=arr.size; ...)` | Jedna iteracja za końcem - lawina błędów `undefined` |
| Ciało `for`/`if` bez klamer | Tylko następna linia jest w środku - feature po cichu nie działa |

---

## Konwencja nazewnictwa

Trzymaj się jej, żeby inni mapperzy (i ty sam za pół roku) mogli nawigować bez zgadywania.

| Prefiks | Do czego |
|---|---|
| `trig_<co>` | `trigger_multiple` w Radiancie |
| `origin_<co>` | `script_origin` jako marker pozycji |
| `door_<co>` | brushmodel drzwi |
| `brush_<co>` | inny brushmodel (mover, platforma) |
| `fx_<co>` | `script_model` jako kotwica FX |
| `tp_<co>` | cel teleportu |
| `secret_<gdzie>_<co>` | encje trasy sekretnej |
| `lever_<co>` | dźwignia do strzelenia / użycia |

**Przykłady:** `trig_trap_crusher`, `origin_combat_sniper_jumper`, `secret_easy_enter_trig`, `brush_trap_wall`.

---

> Dalej: [Podstawy + Hello World](/pl/basics) - twoja pierwsza działająca funkcja mapy.
