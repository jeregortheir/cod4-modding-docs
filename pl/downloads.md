# 📥 Pliki do pobrania

Gotowe do użycia pliki. Kliknij prawym → **Zapisz link jako...**, jeśli przeglądarka otwiera je inline zamiast pobierać.

---

## Szablon dla mappera

Kompletny startowy plik `.gsc` - **30+ gotowych do wklejenia sekcji** obejmujących każdy helper, każdą pułapkę, każdy wzorzec pokoju opisany w tym przewodniku.

<a href="templates/_TEMPLATE_FOR_MAPPERS.gsc" download>
  <strong>⬇️ <code>_TEMPLATE_FOR_MAPPERS.gsc</code></strong>
</a>

| Szczegół | Wartość |
|---|---|
| Nazwa pliku | `_TEMPLATE_FOR_MAPPERS.gsc` |
| Rozmiar | ~80 KB |
| Linie | ~2100 |
| Ostatnia aktualizacja | 2026-04-25 |
| Licencja | Wolno używać, modyfikować, redystrybuować |

### Co jest w środku

Plik jest **opatrzony komentarzami do czytania od góry do dołu** - każda sekcja tłumaczy, *dlaczego* wzorzec wygląda tak jak wygląda, nie tylko *co* robi.

| Sekcje | Temat |
|---|---|
| **Header** | Jak używać tego pliku, konwencje nazewnictwa, anty-wzorce |
| **Section 0** | `addTriggerToList()` (WYMAGANE w każdej mapie) |
| **Utility helpers** | `isValidPlayer`, `safeGetEnt`, `canUse`, `debugPrint`, `freeze_on_tps`, `countdown_timer_string`, lokalny override `GetActivator()` |
| **Sections 1-2** | Hello World + Start Door (zacznij tu) |
| **Sections 3-5** | Podstawy pułapek: crusher, strefa lawy, spinner |
| **Section 6** | Teleporter |
| **Section 7** | Pokój walki (snajper / nóż) |
| **Section 8** | Trasa sekretna z XP |
| **Sections 9-10** | Napisy autora mapy, reset na koniec rundy |
| **Sections 11-14** | FX, dźwięk, HUD, pułapka wieloetapowa, cooldown, strzelany przycisk, jump pad |
| **Section 15** | Pułapka: jednorazowy boost z flagą debounce |
| **Section 16** | Pułapka: ciągły boost podczas dotykania (tunel wiatrowy) |
| **Section 17** | Pułapka: upadek na wiele prób (N żyć) |
| **Section 18** | Pułapka: szturchnięcie anty-utknięcie |
| **Section 19** | Strzałka kierunku pułapki (wizualna podpowiedź, tylko dla graczy w pobliżu) |
| **Section 20** | Generyczny helper teleportera (`teleporter_logic`) |
| **Section 21** | Wzorzec pojedynczej instancji wątku (anulowanie przez notify) |
| **Section 22** | Wyłączność wielu pokoi (jeden pokój PvP naraz) |
| **Section 23** | Baner HUD walki |
| **Section 24** | Dopracowany szablon pokoju walki (używa helperów) |
| **Section 25** | Pokój jump-bounce z progresją checkpointów |
| **Section 26** | Brama, która otwiera się tylko dla oznaczonych graczy |
| **Section 27** | Respawn z detekcją strony (po której stronie spadli?) |
| **Section 28** | Bounce pad warunkowany prędkością |
| **Section 29** | Baner z opóźnieniem lub "czekaj na start rundy" |
| **Reference** | Popularne wzorce wbudowane (ruch, dźwięk, HUD, kody kolorów) |
| **Anti-patterns** | Prawdziwe bugi, na które trafiliśmy w wydanych mapach - NIE POWTARZAJ |

### Jak go użyć

1. **Zapisz plik** do `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` w folderze swojego moda CoD4.
2. **Skopiuj + zmień nazwę** na nazwę swojej mapy: `maps\mp\mp_dr_TWOJANAZWA.gsc`.
3. **Otwórz go.** Przewiń do `main()`. Zakomentuj linie `thread X();` dla funkcji, których **nie** chcesz. Zostaw `maps\mp\_load::main();` na samej górze.
4. **Dla każdej zachowanej funkcji** znajdź jej sekcję, edytuj stringi `targetname` z Radianta (wartości w `getEnt("...")`), żeby pasowały do tego, co faktycznie ustawiłeś w Radiancie.
5. **Skompiluj** `.bsp` w Radiancie (`Compile > BSP + Light + Link`). `.gsc` zostaje wpieczony do `.ff`, gdy uruchamia się `linkMap`.
6. **Testuj:** `/map mp_dr_TWOJANAZWA` w konsoli serwera. Po każdym teście przeskanuj `qconsole.log` w poszukiwaniu `script runtime error` (zobacz [Podstawy → Jak debugować](/pl/fundamentals?id=how-to-debug)).

> **Uwaga:** jeśli wkleisz linię `thread foo();`, ale NIE zdefiniujesz też `foo()` gdzieś w swoim pliku, mapa **się nie skompiluje**. Albo zachowaj ciało funkcji, albo zakomentuj linię `thread`.

---

## Zgłaszanie problemów

Znalazłeś zepsuty wzorzec, nieaktualną nazwę funkcji albo nieistniejącą funkcję wbudowaną CoD4X w szablonie? Zgłoś to na [Discordzie VLCT](https://vlct.mxme.pro/discord) - aktualizujemy szablon **na żywym serwerze**, więc każda poprawka pomaga następnemu mapperowi, który go pobierze.

---

> 🏠 [Powrót do strony głównej](/pl/)
