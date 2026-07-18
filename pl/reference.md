# 📚 Wzorce wbudowane

Ściągawka do szybkiego podglądu popularnych wbudowanych funkcji GSC. Wklejaj prosto do swojej mapy.

---

## Popularne wzorce wbudowane

### Czekaj aż ZADZIAŁA KTÓRYKOLWIEK z kilku notify

Budzi funkcję ten, który zadziała pierwszy.

```c
self common_scripts\utility::waittill_any("death", "disconnect", "spawned");
```

### Zrób brush przechodny, ale nadal widoczny

Do płotków tylko-wizualnych.

```c
mybrush notsolid();
mybrush solid();    // przywroc kolizje
```

### Ukryj / pokaż brush (tylko wizualnie, nie kolizja)

```c
mybrush hide();
mybrush show();
```

### Przesuwanie / obracanie prymitywów

Wszystkie są asynchroniczne - wracają natychmiast, kończą się w czasie.

```c
ent moveZ(distance, time);       // w gore
ent moveY(distance, time);       // na boki
ent moveX(distance, time);       // do przodu
ent rotateYaw  (degrees, time);
ent rotatePitch(degrees, time);
ent rotateRoll (degrees, time);
```

Żeby poczekać na zakończenie ruchu:

```c
ent moveZ(100, 2);
ent waittill("movedone");        // dla obrotow: "rotatedone"
```

### Dźwięk

```c
playSoundAtPosition("sound_alias", entity.origin);   // 3D jednorazowo
player playLocalSound("sound_alias");                 // tylko jeden gracz
ambientStop(2);                                       // wyciszenie 2 sek
ambientPlay("music_alias");                           // start nowego utworu
```

### Prędkość ruchu gracza

`1.0` = domyślne 210, `0.95` = 190, `1.5` = szybko.

```c
player setMoveSpeedScale(1.5);
```

> ❌ **NIE UŻYWAJ** `setmovespeed()` ani `setgravity()` - to crashuje serwer.

### Zespawnuj encję skryptową w runtime

Rzadkie, zwykle używaj Radianta.

```c
ent = spawn("script_origin", (0, 0, 0));
ent.angles = (0, 90, 0);
```

### Wyłącz / włącz trigger ze skryptu

```c
trig thread maps\mp\_utility::triggerOff();
trig thread maps\mp\_utility::triggerOn();
```

### Wypisz do wszystkich graczy

```c
iPrintln("plain message");
iPrintlnBold("BIG centered message");
```

### Wypisz tylko do jednego gracza

```c
player iPrintln    ("for you only");
player iPrintlnBold("for you only - bold");
```

---

## Napisy autora mapy (jednorazowa wiadomość na starcie rundy)

```c
map_credits()
{
    wait 8;   // niech gracze najpierw sie zespawnuja
    iPrintln("^3Map by ^5YourName ^7- thanks for playing!");
    wait 5;
    iPrintln("^3Tested by: ^5tester1, tester2");
}
```

---

## Reset pułapek na koniec rundy (dobra praktyka)

Jeśli twoje pułapki zmieniają pozycje brushy albo kasują rzeczy, to w następnej rundzie Radiant PONOWNIE utworzy encje (encje resetują się przy każdym round_restart). Ale jeśli masz zmienne `level.X` śledzące stan, zresetuj je tutaj.

```c
reset_traps_on_round_end()
{
    while(true)
    {
        level waittill("endround");

        // Wyczysc flagi ustawione w trakcie rundy.
        // Przyklad:
        // level.crusher_used = undefined;
    }
}
```

---

## Kody kolorów

CoD4 używa kodów `^N` wewnątrz dowolnego stringa. Przykłady:

| Kod | Kolor | Typowe użycie |
|---|---|---|
| `^0` | Czarny | nieużywany / obrys |
| `^1` | Czerwony | ostrzeżenia, niebezpieczeństwo |
| `^2` | Zielony | sukces, jumperzy |
| `^3` | Żółty / pomarańczowy | info, neutralne |
| `^4` | Niebieski | linki, podpowiedzi |
| `^5` | Cyjan | wyróżnienia funkcji |
| `^6` | Różowy | wydarzenia specjalne |
| `^7` | Biały | tekst domyślny |
| `^8` | Kolor drużyny gracza | tekst świadomy drużyny |
| `^9` | Kolor drużyny przeciwnej | tekst świadomy wroga |

Przykład:

```c
iPrintLnBold("^5" + player.name + " ^7entered the ^1HARD ^7Secret!");
```

---

## Masz snippet do dodania?

Jeśli masz przepis, który działa na żywym serwerze (i używa defensywnych helperów), podziel się nim na [Discordzie VLCT](https://vlct.mxme.pro/discord), a dodamy go do tego przewodnika.

* Ten przewodnik ci pomógł? Powiedz o nim innym mapperom w swoim języku - i pomóż nam przetłumaczyć stronę, z której korzystałeś najczęściej.
* Znalazłeś błąd w przykładzie? Zgłoś na Discordzie.
* Znalazłeś nieistniejącą funkcję wbudowaną CoD4X w czyjejś mapie (coś jak `setmovespeed`)? Powiedz nam, żebyśmy dodali to do [Zanim napiszesz kod → Anty-wzorce](/pl/before-you-code).

---

> 🏠 [Powrót do strony głównej](/pl/)
