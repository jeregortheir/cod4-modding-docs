# 📖 Podstawy

Przeczytaj całą tę stronę **zanim** napiszesz jakikolwiek kod GSC. Zajmie 10 minut, oszczędzi godziny.

---

## Słownik - definicje po polsku

> Jeśli zapamiętasz tylko trzy rzeczy z tej strony: `self`, `level` i `level.activ`. Te trzy koncepty powodują 80% crashy u początkujących.

| Termin | Znaczenie |
|---|---|
| **self** | Encja na której aktualnie wykonuje się funkcja. Dla `player thread X()` → wewnątrz `X()`, `self` = player. Dla `trig thread Y()` → wewnątrz `Y()`, `self` = `trig`. |
| **level** | Globalny współdzielony stan. `level.foo` jest widoczne z każdej funkcji w każdym pliku na serwerze. Używaj dla rzeczy współdzielonych między graczami / wątkami. |
| **encja (entity)** | Cokolwiek w świecie 3D: gracz, brush, marker `script_origin`, anchor FX, trigger. Ma `.origin` (pozycja) i `.angles` (rotacja). |
| **thread X()** | Uruchom funkcję `X` w tle. Wywołujący kontynuuje bez czekania aż `X` się skończy. Niezbędne dla wszystkiego co ma pętlę nieskończoną (pułapki, triggery). |
| **waittill("foo")** | Wstrzymaj tę funkcję (nie cały serwer) dopóki ktoś nie wywoła `notify("foo")` na tej samej encji/poziomie. Używane do reakcji na zdarzenia: początek rundy, śmierć gracza, trigger, koniec ruchu, etc. |
| **notify("foo")** | Wyślij sygnał. Każda funkcja siedząca na `waittill("foo")` na tej encji/level budzi się. Każda funkcja z `endon("foo")` zostaje zabita. |
| **endon("foo")** | Jeśli `notify("foo")` wystrzeli, natychmiast zabij ten wątek. Używaj na górze pętli żeby kończyły się czysto przy końcu rundy / śmierci gracza / disconnecie. |
| **getEnt(name, "targetname")** | Znajdź JEDNĄ encję po `targetname` ustawionym w Radiancie. Zwraca encję lub `undefined` jeśli brak. **Crashuje jeśli WIĘCEJ NIŻ JEDNA encja ma tę samą nazwę** - wtedy użyj `getentarray()` + `[0]`. |
| **dvar** | Nazwana zmienna serwera (jak zmienna środowiskowa Windows). `setDvar("foo", 1)` / `getDvar("foo")`. Używana do konfiguracji i komunikacji client↔server. |
| **precache** | Powiedz silnikowi "użyję tego asset'a", robi się **RAZ** przy ładowaniu mapy w `main()` (lub w helperze wołanym z `main()`). Jeśli użyjesz asset'a bez precachingu - crash. |
| **allies / axis** | Nazwy drużyn. W Deathrun: `allies` = jumperzy (zieloni, większość), `axis` = aktywator (czerwony, dokładnie jeden gracz). |
| **level.activ** | Gracz który aktualnie jest w drużynie axis (aktywator). **MOŻE BYĆ STRINGIEM `"Noactivator"`** gdy nikt nie jest w axis - **zawsze** sprawdzaj `isplayer(level.activ)` przed użyciem. |
| **module::function** | `::` oznacza "z pliku X, wywołaj funkcję Y". Przykład: `maps\mp\_load::main()` znaczy "w pliku `maps/mp/_load.gsc`, wywołaj jego funkcję `main()`". |
| **KVP** | Key-Value Pair w Entity Inspector w Radiancie (klawisz `N`). Dodajesz `targetname` / `classname` / własne klucze w Radiancie, czytasz je w GSC przez `.targetname` etc. |
| **vector** | Trzy liczby w nawiasach: `(x, y, z)`. Pozycje, kąty, kolory wszystkie używają tego. Przykład: `(100, 200, 50)`. |

---

## Jak debugować

* Dodaj `iprintln("foo")` żeby wypisać coś widocznego dla **wszystkich graczy**. Szybko + brudno ale spamersko.
* Dodaj `println("foo")` żeby wypisać do `qconsole.log` **tylko** (server-only). Cicho + czysto. Dobre do developmentu.
* **Lepiej:** ustaw `level.debug = true;` na górze `main()` i używaj helpera `debugPrint("foo")` (zobacz [Basics](/pl/basics.md)). Jedna linia żeby wyciszyć wszystkie debug printy przed wydaniem: zmień `true` → `false`.

### Jak czytać błędy skryptów

Błędy pojawiają się w `qconsole.log` w formacie:

```
^1******* script runtime error *******
undefined is not a field object: (file 'maps/mp/X.gsc', line 123)
    player.camo_preview.model
          *
^1called from:
(file 'maps/mp/X.gsc', line 80)
    open_camos_menu();
    *
```

* `*` wskazuje na **co było undefined**.
* Stack funkcji który następuje pokazuje **co wywołało tę linię** - prześledź wstecz żeby znaleźć źródło.
* `(file 'maps/mp/X.gsc', line 123)` - skocz do tej linii w edytorze.

### Quick reference częstych błędów

| Błąd | Co znaczy | Fix |
|---|---|---|
| `undefined is not a field object` | Zrobiłeś `.X` na undefined | Sprawdź że rzecz przed `.X` jest `isdefined()` |
| `undefined is not an entity` | Encja została usunięta w trakcie pętli | Re-sprawdź `isdefined()` między waitami |
| `type string is not an entity` | Użyłeś `level.activ` jako encji bez `isplayer()` checka | Owin w `if(isplayer(level.activ))` |
| `getent used with more than one entity` | Duplikat `targetname` w Radiancie | Zmień nazwę lub użyj `getentarray()[0]` / `safeGetEnt()` |
| `potential infinite loop in script - killing thread` | Pętla bez `wait` na jakimś path | Dodaj `wait 0.05;` do każdej iteracji pętli |
| `cannot cast undefined to bool` | `if(level.foo == 1)` gdzie `level.foo` jest undefined | Init `level.foo` na default przed sprawdzeniem |

---

## Most Radiant ↔ GSC

Jak to co umieszczasz w Radiancie mapuje się na to co piszesz w GSC:

```
W Radiancie (Entity Inspector):       W kodzie GSC:
-------------------------------       ----------------------------------
trigger_multiple                      getEnt("X", "targetname")
  targetname: X                          - zwraca encję trigger'a

script_origin                         ent = getEnt("X", "targetname");
  targetname: X                       ent.origin  -> wektor (x, y, z)
  origin: 100 200 50                  ent.angles  -> (pitch, yaw, roll)
  angles: 0 90 0

script_brushmodel                     door = getEnt("door", ...)
  targetname: door                    door moveZ(200, 2);    // przesuń
  (zaznacz brush + Ctrl-T)            door rotateYaw(90, 1); // obróć

script_model                          fx = getEnt("fx1", ...)
  targetname: fx1                     playfx(level._effect["fire"],
  model: <tag_origin>                        fx.origin);

spawn-point                           (obsługiwane przez engine automatycznie)
  classname: mp_jumper_spawn
  classname: mp_activator_spawn
```

**Złote zasady:**

* Każdy `targetname` który wpisujesz w Radiancie musi pasować **dokładnie** do `getEnt("...")` w GSC - case sensitive, bez literówek.
* Jeśli dwie rzeczy w Radiancie mają ten sam `targetname`, `getEnt()` crashuje. Użyj `getentarray()` + `[0]` lub helpera `safeGetEnt()`.
* Nowa encja w Radiancie = **rekompiluj** mapę albo się nie pojawi.

---

## Zasady przetrwania

8 zasad które zapobiegają 90% bugów.

### 1. Zawsze guarduj wyniki `getEnt`/`getent`

```c
ent = getEnt("foo", "targetname");
if(!isdefined(ent)) return;        // <-- ta linia
```

na **górze funkcji**. Jeśli brush jest źle nazwany, funkcja się kończy zamiast crashować potem przy `.origin` na undefined.

### 2. Zawsze waliduj gracza po wystrzeleniu trigger'a

```c
trig waittill("trigger", player);
if(!isValidPlayer(player)) continue;     // <-- ta linia
```

Gracz może się rozłączyć lub umrzeć między wystrzeleniem trigger'a a wykonaniem twojego kodu.

### 3. Nigdy nie wołaj metod na `level.activ` raw

```c
// ŹLE - crashuje gdy nikt nie jest aktywatorem
level.activ setOrigin(p.origin);

// DOBRZE
if(isplayer(level.activ))
    level.activ setOrigin(p.origin);
```

Gdy nikt nie jest w drużynie aktywatora, `GetActivator()` zwraca **string** `"Noactivator"`. Wywołanie `level.activ setOrigin(...)` na stringu to runtime error i zalewa log.

### 4. Nigdy nie używaj `setmovespeed()` ani `setgravity()`

```c
// ŹLE - nieistniejący CoD4X builtin, crashuje CAŁY SERWER w niektórych buildach
player setmovespeed(500);
player setgravity(500);

// DOBRZE
player setMoveSpeedScale(2.6);  // 2.6x = ~500 efektywnie
```

Używaj `setMoveSpeedScale(float)` gdzie `1.0` = default speed (210 w tym modzie), `0.95` = wolno (190), `1.5` = szybko.

### 5. Nigdy nie pisz pętli z pustym body bez `wait`

```c
// ŹLE - gdy condition jest false na inner if, brak wait -> CPU spinuje
while(condition)
    if(other)
        wait 1;

// DOBRZE - zawsze miej wait gdzieś w body pętli
while(condition) {
    if(other) doSomething();
    wait 1;
}
```

CoD4X opcode killer zabije wątek; w napiętym momencie może zawiesić serwer.

### 6. Nigdy nie używaj `getEnt` na duplikacie `targetname`

Jeśli więcej niż jedna encja w Radiancie ma ten sam `targetname`, `getEnt` zwraca `"getent used with more than one entity"`. Użyj `safeGetEnt("foo")` z [Basics → Utility helpers](/pl/basics.md), lub `getentarray("foo", "targetname")[0]`.

### 7. Wszystkie stringi widoczne dla graczy po angielsku

`iPrintLn`, `iPrintLnBold`, hint stringi, tekst HUD - **muszą być po angielsku**. Serwer jest międzynarodowy.

### 8. Nigdy nie używaj znaku em-dash

CoD4 engine nie potrafi wyrenderować em-dash (`U+2014`) - pokazuje śmieci. Używaj `-` (myślnik) lub `--` (podwójny myślnik) w plikach `.gsc`.

---

> Następne: [Zanim napiszesz kod](/pl/before-you-code.md) - częste błędy i anty-wzorce do unikania.
