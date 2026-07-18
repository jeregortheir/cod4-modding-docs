# 🔤 Własne fonty i emoji na czacie

?> **To eksperyment, nie gotowy przepis.** Wszystko poniżej ustaliliśmy metodą prób i błędów na silniku z 2007 roku, bez żadnej dokumentacji. Działa u nas, ale spodziewaj się chropowatości - część kroków może zachowywać się inaczej u ciebie, a kilka "faktów" tutaj było błędnych dwa czy trzy razy, zanim się ustaliły. Traktuj to jak mapę terenu, nie gwarancję. Jak coś nie działa, to normalne - drąż dalej, ściana zwykle jest tam, gdzie nie patrzyłeś.

CoD4 nie ma systemu emoji. Ale możesz wstawić **dowolny obrazek inline w tekst czatu** - i każdy gracz go widzi **bez ruszania swojej instalacji gry**. Bez patcha klienta, bez instrukcji pobierania, bez "najpierw zainstaluj ten pak".

Ten rozdział pokazuje jak. To ogólna wiedza o CoD4 i działa na każdym modzie.

> **Co dostajesz:** `:skull:` wpisane na czacie staje się prawdziwą ikoną. Dowolny rozmiar, dowolna pozycja, barwiona kodami `^1`/`^2` jak zwykły tekst.

---

## Jak to naprawdę działa

CoD4 rysuje tekst, sprawdzając każdy bajt w **tablicy glifów**, która mówi *gdzie* w dzielonym **atlasie tekstur** próbkować i *jak duże* to narysować.

Więc obrazek inline potrzebuje zgody trzech warstw:

| # | Warstwa | Co trzyma | Gdzie żyje | Jak dostarczasz |
|---|---|---|---|---|
| 1 | **Piksele** | rysunek | `images/gamefonts_pc.iwi` (512×1024, DXT5) | dowolny `.iwd` w twoim modzie |
| 2 | **Tablica glifów** | rozmiar, pozycja, UV | `raw/english/fonts/*` → `mod.ff` | `mod.csv` + rebuild |
| 3 | **Trigger → bajt** | `:skull:` → `0xD0` | twój silnik / GSC | po stronie serwera |

Trik: wybierz znak, którego **nikt nigdy nie wpisuje** (jak `Ð` czy `¼`), przemaluj jego celę w atlasie i powiększ jego wpis w glifach. Gdy serwer wyśle ten bajt, klient rysuje twój obrazek.

---

## Warunek wstępny: potrzebujesz podstawienia po stronie serwera

!> **Same warstwy 1 i 2 nie dają nic.** Sprawiają, że bajt `0xD0` *wygląda* jak czaszka. Coś nadal musi zamienić wpisane przez gracza `:skull:` **na ten bajt** - a stockowy CoD4 tego za ciebie nie zrobi.

To część, którą ludzie pomijają, więc miej ją jasną, zanim zaczniesz:

- Klient rysuje wyłącznie **bajty**. Nie ma pojęcia, co znaczy `:skull:`.
- Czat gracza w waniliowej wersji jest broadcastowany prosto z modułu gry. Nie ma stockowego haka, w którym mógłbyś przepisać tekst na wyjściu.
- Więc podmiana musi się dziać **po stronie serwera, w momencie wysyłki**, w tej ścieżce kodu, którą faktycznie przechodzi twój czat.

**W praktyce oznacza to własny build serwera** (albo dowolny setup, w którym kontrolujesz finalną wysyłkę). Jeśli twój mod już re-emituje czat przez własną ścieżkę `say` serwera zamiast pozwalać na natywny broadcast, to tam należy podmiana.

Minimalne podstawienie to zwykły in-place replace stringa, zaaplikowany tuż przed wysyłką:

```c
/* najdłuższe triggery pierwsze, inaczej ":)" zje prefiks ":)foo:" */
static const char *triggers[] = { ":skull:", ":heart:", ":)" };
static const char  glyphs[]   = { (char)0xD0, (char)0xA9, (char)0xC2 };

while ((p = strstr(s, triggers[m])) != NULL) {
    *p = glyphs[m];
    memmove(p + 1, p + strlen(triggers[m]), strlen(p + strlen(triggers[m])) + 1);
}
```

?> **Trzymaj triggery jako ASCII przez całą warstwę skryptową**, a wysoki bajt wstaw dopiero na ostatnim kroku. Wysokie bajty przeżywają wysyłkę bez problemu - `I_CleanChar` mapuje tylko `146 → 39`, a enkoder reliable-command ich nie rusza - ale im mniej warstw przechodzą, tym mniej niespodzianek.

**Bez tej warstwy gracze widzą po prostu literalny tekst `:skull:`.** Wszystko poniżej zakłada, że ją masz.

---

## Jedna rzecz, która to umożliwia

> **`mod.ff` nadpisuje fonty bazowej gry.**

Dodaj to do `mod.csv`:

```
font,fonts/normalfont
```

Zrebuilduj `mod.ff`, a klient używa **twojej** tablicy glifów zamiast stockowej. Gracze pobierają `mod.ff` automatycznie przy dołączaniu - to cały mechanizm dostawy.

?> Inne fastfile też niosą fonty i część z nich ładuje się wcześniej - więc wyglądają na bardziej bezpośredni cel. Nie są: `mod.ff` i tak wygrywa i jest jedynym, który gracze sami pobierają. Patchuj fonty tutaj i nigdzie indziej.

---

## Który font co renderuje

To część, która kosztuje ludzi całe dni. CoD4 ma siedem fontów, a nazwy kłamią.

| Font | pixelHeight | Renderuje |
|---|---|---|
| **normalFont** | 16 | **czat**, scoreboard, większość tekstu HUD |
| consoleFont | 16 | konsolę (`~`) - **nie** czat |
| smallFont | 10 | małe etykiety HUD |
| boldFont | 16 | |
| bigFont | 24 | |
| objectiveFont | 35 | |
| extraBigFont | 48 | |

**Czat to `normalFont`.** Nie `bigFont`, nie `consoleFont`.

### Jak to sam zweryfikować

Nie zgaduj i nie mierz rozmiarów na oko - jedno i drugie zawodzi. Daj **każdemu fontowi inny kształt** pod tą samą literą, potem odczytaj z ekranu:

```
consoleFont : 'a' -> serce
normalFont  : 'a' -> buźka
boldFont    : 'a' -> czaszka
bigFont     : 'a' -> puchar
```

Wpisz `a` na czacie. Jakikolwiek kształt się pojawi, nazywa font za jednym razem. Ten test nie może dać dwuznacznej odpowiedzi i właśnie dlatego wart jest tych pięciu minut.

---

## Format tablicy glifów

`raw/english/fonts/<nazwa>` - płaska binarka, bez kompresji:

```
0:   u32  glyphsEnd     (= 16 + glyphCount * 24)
4:   u32  pixelHeight   (wysokość linii - font czatu: 16)
8:   u32  glyphCount    (254 dla consoleFont, 191 dla reszty)
12:  u32  stringOffset
16:  wpisy glifów, po 24 bajty
```

Każdy glif:

| Offset | Typ | Pole |
|---|---|---|
| 0 | u16 | `letter` - kod znaku |
| 2 | s8 | `x0` - offset poziomy od pena |
| 3 | s8 | **`y0` - górna krawędź, względem baseline** |
| 4 | s8 | `dx` - advance (o ile pen się przesuwa) |
| 5 | u8 | **`pw` - szerokość** |
| 6 | u8 | **`ph` - wysokość** |
| 8..24 | 4× float | prostokąt UV (s0, t0, s1, t1) |

!> **Glify nie są posortowane.** Kolejność to 32..127, potem 1..31, potem 128..255. Nigdy nie zakładaj indeksu - znajdź tablicę, skanując za `letter == 32`, po którym następuje `letter == 33`.

### Dwie zasady, których nie wolno łamać

**1. `pw`/`ph` musi równać się rozpiętości UV w texelach.**
Jeśli twoja cela to 32×32 w atlasie, ale ustawisz `pw=20`, silnik **wycina** zamiast skalować - dostajesz poszarpane fragmenty. Daj każdemu fontowi własne cele we własnym rozmiarze.

**2. Rozmiar i pozycja są niezależne.**
`pw`/`ph` sterują jak duże. `y0` steruje gdzie. Mylenie ich to godziny stracone (patrz niżej).

---

## Pozycjonowanie: błąd, który popełnia każdy

Glif jest zakotwiczony **górną krawędzią** (`y0`), a tekst siedzi na baseline. Jeśli wyrównasz dół emotki do baseline, rośnie **tylko w górę**:

```
litera 'A' :  8x10, y0=-12   ->  rozciąga się -12 .. -2
emotka 20px:        y0=-22   ->  rozciąga się -22 .. -2     <- wystaje 10px ponad tekst
```

Emotka góruje nad linią, z niczym pod spodem. Zmniejszanie jej (32 → 26 → 20) tylko przycina górę - kotwica się nie rusza, więc dalej wygląda źle i wyciągasz wniosek "nic się nie zmieniło".

**Fix: wyśrodkuj ją na literach.**

```python
a_top    = glyph['A'].y0            # -12
a_bottom = a_top + glyph['A'].ph    #  -2
center   = (a_top + a_bottom) // 2  #  -7

y0 = center - emoji_height // 2     # emotka wyśrodkowana na tekście
```

Dla emotki 20px daje to `y0 = -17`, rozpiętość -17..+3 - 5px nad wielkimi literami, 5px pod baseline. Jak prawdziwa emotka w zdaniu.

---

## Dobór bajtów

Używaj znaków, których gracz **nigdy nie wpisze**:

- Dobre: `© ¼ ½ ¾ Æ Ð À Á Â Ã Ä` i większość `0xA0-0xFF`
- **Unikaj** czegokolwiek z języka twoich graczy. Dla polskich serwerów to CP1250: `ą ć ę ł ń ó ź ż` - gracz wpisujący `źle` odpaliłby twoją emotkę.

Bajt przeżywa cały pipeline: `I_CleanChar` mapuje tylko `146 → 39`, a enkoder reliable-command nie tyka wysokich bajtów.

---

## Barwienie (tint)

Silnik **mnoży** kolor tekstu przez kolor glifu:

| Glif w atlasie | Wynik |
|---|---|
| **biały** | `^1` → czerwony, `^2` → zielony. **Barwialny.** |
| **kolorowy** (foto-emotka) | `^2` × czerwony ≈ czerń. **Barwienie martwe.** |

Więc: rysuj barwialne emotki na **biało**, ciemne detale trzymaj ciemne (zostają ciemne pod każdym tintem - czerń × kolor = czerń).

### Domyślne kolory bez utraty barwialności

Wstrzyknij kod koloru przed glifem, **chyba że gracz podał go bezpośrednio przed triggerem**:

```c
if (tints[m] && !(p >= s + 2 && p[-2] == '^' && p[-1] >= '0' && p[-1] <= '?')) {
    /* znajdź ostatni aktywny kolor, żeby przywrócić go potem */
    ...
    p[0] = '^'; p[1] = tints[m]; p[2] = glyph; p[3] = '^'; p[4] = restore;
}
```

Wynik: `<3` jest czerwone, `^2<3` zielone, a `^2hello <3 world` trzyma `world` zielony.

!> Sprawdzenie to **przyleganie**, nie obecność. `^2 <3` (ze spacją) i tak dostaje kolor domyślny - kod musi dotykać triggera.

!> To powiększa string (2 bajty → 5). Przekaż rozmiar bufora i degraduj do zwykłego glifu, gdy się nie zmieści, inaczej rozwalisz stack.

---

## Atlas tekstur

`images/gamefonts_pc.iwi` - 512×1024, **DXT5**, dostarczany w dowolnym `.iwd` moda. IWD moda biją bazowe w ścieżce wyszukiwania, więc dla samych pikseli nie trzeba rebuildu fastfile'a.

### Cztery pułapki

**1. Mipy są zapisane od najmniejszej.** Offsety w headerze to **koniec** każdej mipy. Poziom bazowy zaczyna się na `filesize - W*H`, **nie** na bajcie 28. Czytanie od 28 daje małą mipę i twój rysunek ląduje w złych glifach.

**2. Maluj każdą mipę.** GPU wybiera poziom wg rozmiaru renderu. Jest ich 8 (512×1024 do 4×8). Przy mipie 3-4 emotka 32px to 4×4 piksele - kolorowa plama. To normalne i nieuniknione.

**3. Nigdy nie zmieniaj formatu.** Trzymaj stockowy DXT5. ARGB32 niszczy font, bo **kształt glifu żyje w kanale alfa** - kolejność bajtów się przesuwa i każda litera zamienia się w śmieci.

Poprawny workflow: dekoduj DXT5 → przemaluj cele → **przekoduj tylko te bloki 4×4, których dotykają twoje cele** → bajt-w-bajt identyczne gdzie indziej.

**4. Łańcuch mip musi zejść aż do 1×1.** Ta jest złośliwa i kosztowała najwięcej czasu. Jeśli budujesz *nowy* atlas (patrz niżej) i zatrzymasz łańcuch na 4×4, plikowi brakuje poziomów 2×2 i 1×1 - każdy to nadal pełny 16-bajtowy blok DXT5. Silnik lokalizuje każdą mipę, idąc **od najmniejszej**, więc łańcuch krótszy o dwa poziomy przesuwa *każdy pośredni offset*. Wynik: baza (największa mipa) jest OK, bo znajdowana jest od końca pliku, więc **duże glify renderują się idealnie** - ale mały tekst próbkuje przesunięty środek łańcucha i wychodzi jako **rozsypane śmieci**. Objawem jest dokładnie ten rozjazd: duże ikony dobre, małe litery rozsypane. Dopasuj długość łańcucha (do 1×1) dokładnie do stocka.

### Wolne miejsce - i ile masz go *naprawdę*

Z grubsza **dolne 40% atlasu jest nieużywane** (`y ≈ 604-1023`). Zweryfikuj to przeciw każdej tablicy glifów, zanim uznasz region za wolny, i wyrównaj cele do siatki bloków 4px z 4px przerwy: dzielone bloki DXT5 wciskają dwa obrazki w jedną 4-kolorową paletę i oba wychodzą brudne.

Ale **liczba cel to nie twój prawdziwy sufit** - dwa inne limity gryzą pierwsze:

- **Jeden bajt na emotkę.** Twoje triggery mapują się na pojedyncze wysokie bajty. Po usunięciu znaków z języka graczy użyteczny zakres (`0xA0-0xFF`) zostawia rzędu kilkudziesięciu wolnych bajtów. To twój **twardy sufit na liczbę emotek**, niezależnie od tego, ile masz atlasu.
- **Cela w *każdym* patchowanym foncie.** Jeśli emotka musi renderować się na czacie *i* w większych fontach HUD, potrzebuje celi przy każdym z tych rozmiarów. Więc "N emotek" kosztuje naprawdę "N × (liczba różnych rozmiarów fontu)" cel. Łatwo przeliczyć wolne miejsce w górę, zapominając o tym - błąd, który chętnie wyśle cię w złą stronę.

Jeśli wyrośniesz ponad stockowy atlas 512×1024, zobacz **Powiększanie ponad stockowy atlas** niżej.

---

## Powiększanie ponad stockowy atlas

Gdy chcesz wielu emotek renderowanych w pełnym rozmiarze na kilku fontach, stockowy atlas 512×1024 kończy się. Możesz zamiast tego skierować fonty na **własny większy atlas** - stockowy zostaje nietknięty, więc cokolwiek innego go próbkuje, dalej działa.

To większy wysiłek i ma ostre krawędzie. Kształt tego:

1. **Zbuduj nowy, większy `.iwi`** (na przykład 2048×2048, ten sam format DXT5). Skopiuj stockowy atlas liter w jeden róg - zrób to przez **block-copy zakodowanych bloków DXT5 per poziom mip**, żeby litery zostały pixel-identyczne, bez re-enkodowania. Wmaluj emotki w wolny obszar. Pamiętaj o pułapce #4: **pełny łańcuch mip do 1×1**.

2. **Daj fontom nowy materiał.** Tablica glifów fontu odwołuje się do swojego atlasu przez **string z nazwą materiału** zapisany na końcu pliku. Sklonuj stockowy materiał *fontu* jako donora (te z techsetem `2d` to właściwy rodzaj), skieruj go na swój nowy obraz i podmień string nazwy materiału fontu, żeby pasował.

3. **Przepisz offsety stringów materiału, nie tylko nadpisz bajty.** Plik materiału CoD4 to stały header offsetów-wskaźników, po którym idą stringi zakończone NUL-em. Kilka pól `u32` wskazuje w ten blok stringów - i co kluczowe, jest **więcej niż jedna referencja do nazwy obrazu** (ukryte drugie pole poza tym oczywistym). Zremapuj **każdy** offset, który wskazywał na string, inaczej silnik czyta nazwę obrazu ze środka innego stringa i zgłasza `image ... is missing`. To jedno przeoczone pole kosztuje cię popołudnie.

4. **Materiały fontów chodzą parami - linker sam dokleja `_glow`.** Font używający materiału `fonts/myatlas` sprawia, że linker żąda też `fonts/myatlas_glow` (materiał passu glow). Zbuduj oba. Mogą próbkować **ten sam** obraz.

5. **Linker potrzebuje obrazu w `raw/images/`, nie tylko w twoim `.iwd`.** Materiał wypieka kopię obrazu do `mod.ff` przy buildzie i szuka źródła tam. Włóż `.iwi` w oba miejsca. Konsekwencja: od teraz **zmiana pikseli oznacza rebuild `mod.ff`**, nie tylko ponowne dostarczenie iwd.

6. **Przeskaluj UV każdego glifu** o stosunek starego rozmiaru atlasu do nowego, żeby litery (i każdy skopiowany glif) wylądowały dokładnie na swoim podregionie większej płaszczyzny. Litera przy znormalizowanym UV `(s, t)` w starym 512×1024 staje się `(s × oldW/newW, t × oldH/newH)`.

?> Zostaw to na moment, gdy naprawdę tego potrzebujesz. Ścieżka stockowego atlasu jest dużo prostsza i pokrywa większość przypadków. Sięgaj po własny atlas tylko, gdy twoim limitem nie jest sufit bajtów, lecz *piksele*.

---

## Jeden rozmiar, który u wszystkich wygląda tak samo

Emotki są rysowane w **stałym rozmiarze pikselowym**, ale tekst czatu **skaluje się z rozdzielczością gracza**. Więc jeśli wymiarujesz emotki płaską liczbą pikseli, stosunek ikony do tekstu dryfuje per rozdzielczość: co u ciebie wygląda dobrze, u klienta na 720p jest ogromne i odwrotnie.

**Fix: wymiaruj celę emotki każdego fontu jako tę samą wielokrotność wysokości linii tego fontu** (`pixelHeight`), jednym wspólnym mnożnikiem. Wtedy ikona jest zawsze, powiedzmy, 1,6× otaczającego tekstu - na każdym ekranie. Jeśli zamiast tego capujesz różne fonty na różne rozmiary pikselowe, stosunek pęka i dostajesz klasyczne "u mnie dobrze, u wszystkich za duże".

---

## Komenda pomocy `!emoji`, która pokazuje prawdziwe ikony

Przydatny trik do komendy-listy: chcesz pokazać każdą ikonę **obok dokładnego tekstu, który gracz musi wpisać** - ale jeśli wypiszesz `:skull:`, znów zamieni się w ikonę.

Złam dopasowanie bez zmiany tego, co gracz widzi: **wstaw kod koloru po pierwszym znaku** triggera. `:skull:` zapisane jako `:^7skull:` to już nie ciągłe bajty `:skull:`, więc pass podstawienia je pomija - a klient renderuje `^7` jako (nieszkodliwe) przełączenie koloru i pokazuje literalny tekst `:skull:`. Wypisz prawdziwy trigger (staje się ikoną), a za nim tę złamaną kopię (zostaje tekstem), i gracz widzi **ikonę + jak ją wpisać**.

Wyślij to przez tę ścieżkę wiadomości do jednego gracza, którą już przechodzi twoje podstawienie, i rozłóż linie krótkim waitem, żeby nigdy nie zalać bufora reliable-command.

---

## Krok po kroku

1. **Narysuj** emotkę (`.webp`, `.png` lub `.svg`), mniej więcej kwadratową, z przezroczystym tłem
2. **Wybierz bajt**, którego nikt nie wpisuje
3. **Wmaluj** ją w wolną celę atlasu - wszystkie 8 mip, chirurgiczne re-enkodowanie DXT5
4. **Zapatchuj** tablice glifów w `raw/english/fonts/*` - ustaw `pw`/`ph`/`y0`/`dx`/UV
5. **Dodaj** `font,fonts/normalfont` (i każdy inny patchowany font) do `mod.csv`
6. **Zrebuilduj** `mod.ff`
7. **Zmapuj** trigger na bajt, po stronie serwera, w momencie wysyłki
8. **Zrestartuj** serwer, potem **w pełni zrestartuj klienta**

?> **Font ładuje się raz, przy starcie procesu.** Ponowne połączenie nie wystarczy - klient trzyma font, z którym wystartował. Połowa wszystkich zgłoszeń "nie zadziałało" to klient, którego nigdy nie zrestartowano.

---

## Checklista debugowania

| Objaw | Przyczyna |
|---|---|
| Surowe litery (`Á Ð ¼`) | tablica glifów nie załadowana - `mod.ff` nie zrebuildowany albo klient nie zrestartowany |
| Poszarpane fragmenty | `pw`/`ph` ≠ rozpiętość UV |
| Kolorowy kwadrat | atlas nie ma pikseli w tej celi, albo siatki fontu/atlasu się rozjechały |
| Dobry rozmiar, wygląda źle | `y0` - emotka zakotwiczona do baseline, rosnąca w górę |
| Działa w konsoli, nie na czacie | zapatchowałeś `consoleFont`, czat to `normalFont` |
| Duże ikony OK, mały tekst rozsypany | własny atlas z **niepełnym łańcuchem mip** - musi zejść do 1×1 (pułapka #4) |
| `image ... is missing` przy buildzie | offsety materiału nie w pełni zremapowane - ukryte drugie pole nazwy obrazu dalej wskazuje źle |
| Za duże u innych, u ciebie dobrze | wymiarowanie stałym pikselem - skaluj wg wysokości linii jednym wspólnym mnożnikiem |
| Nic się nigdy nie zmienia | serwer nie zrestartowany → nieświeży CRC → klient re-pobiera stary plik na twój |

**Weryfikuj trzy warstwy razem**, zawsze: czy tablica glifów wskazuje cele, w których atlas faktycznie ma piksele? Render prosto z dostarczanych plików odpowiada w sekundy na to, na co godzina zgadywania in-game nie odpowie.
