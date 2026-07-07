# 🗺️ VLCT Deathrun - Mapping Guide

Defensiver GSC-Skripting-Leitfaden für **CoD4 Deathrun** Map-Maker. Muster, Rezepte und Überlebensregeln, die Server-Crashes verhindern.

> **Neu hier?** Beginne mit dem [Schnellstart](#schnellstart-5-schritte) unten, dann lies [Grundlagen](/en/fundamentals.md) (auf Englisch) - das gibt dir alles, um deine erste Falle zu schreiben.

---

## Schnellstart (5 Schritte)

Der schnellste Weg von Null zu einer funktionierenden Map:

1. **Kopiere die Template-Datei**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_DEINNAME.gsc`

2. **Öffne sie.** Scrolle zu `main()`. Lösche die `thread`-Zeilen für Features, die du **nicht** willst (z. B. entferne `thread combat_room_sniper();`, wenn deine Map keinen Sniper-Raum hat). Behalte `maps\mp\_load::main();` oben.

3. **Für jedes Feature, das du behältst,** finde seinen Abschnitt in dieser Anleitung und passe die Radiant-`targetname`-Strings (die Werte in `getEnt("...")`) an das an, was du in Radiant platziert hast.

4. **Kompiliere deine `.bsp`** in Radiant (`Compile > BSP + Light + Link`). Deine `.gsc` wird beim `linkMap`-Lauf in die `.ff` eingebacken.

5. **Test:** `/map mp_dr_DEINNAME` in der Server-Konsole. Nach jedem Test prüfe `qconsole.log` auf `script runtime error`.

---

## Warum dieser Leitfaden existiert

Die GSC-Engine von CoD4 hat scharfe Kanten - eine einzige ungeschützte Zeile kann:

* Den **gesamten Server** crashen (z. B. Aufruf einer nicht existierenden Built-in-Funktion wie `setmovespeed()`)
* Tausende Fehler pro Minute spammen (z. B. Zugriff auf `level.activ.X`, wenn niemand im Aktivator-Team ist)
* Deine Map still kaputt machen (z. B. doppelter `targetname` in Radiant → `getEnt` gibt undefined zurück)

> 🌐 Die deutsche Übersetzung ist noch im Aufbau. [Hilf mit auf Discord](https://vlct.mxme.pro/discord) - selbst eine übersetzte Seite hilft tausenden Mappern.

> 👉 Vollständiger Inhalt: [English version](/en/)
