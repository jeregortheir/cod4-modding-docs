# 🗺️ VLCT Deathrun - Guide pour Mappers

Guide défensif de scripting GSC pour créateurs de cartes **CoD4 Deathrun**. Modèles, recettes et règles de survie qui évitent les crashes du serveur.

> **Nouveau ici ?** Commence par le [Démarrage Rapide](#demarrage-rapide-5-etapes) ci-dessous, puis lis [Fondamentaux](/en/fundamentals.md) (en anglais) - ça te donne tout pour écrire ton premier piège.

---

## Démarrage Rapide (5 étapes)

Le chemin le plus rapide de zéro à une carte qui fonctionne :

1. **Copie le fichier modèle**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_TONNOM.gsc`

2. **Ouvre-le.** Défile jusqu'à `main()`. Supprime les lignes `thread` pour les fonctionnalités que tu **ne veux pas** (ex. enlève `thread combat_room_sniper();` si ta carte n'a pas de salle de sniper). Garde `maps\mp\_load::main();` en haut.

3. **Pour chaque fonctionnalité que tu gardes,** trouve sa section dans ce guide et édite les `targetname` de Radiant (les valeurs dans `getEnt("...")`) pour qu'elles correspondent à ce que tu as mis dans Radiant.

4. **Compile ton `.bsp`** dans Radiant (`Compile > BSP + Light + Link`). Ton `.gsc` sera intégré au `.ff` lors de `linkMap`.

5. **Test :** `/map mp_dr_TONNOM` dans la console serveur. Après chaque test vérifie `qconsole.log` pour `script runtime error`.

---

## Pourquoi ce guide existe

Le moteur GSC de CoD4 a des bords tranchants - une seule ligne non protégée peut :

* Crasher **le serveur entier** (ex. appeler une fonction inexistante comme `setmovespeed()`)
* Spammer des milliers d'erreurs par minute (ex. accéder à `level.activ.X` quand personne n'est dans l'équipe activateur)
* Casser silencieusement ta carte (ex. `targetname` dupliqué dans Radiant → `getEnt` retourne undefined)

> 🌐 La traduction française est encore en construction. [Aide sur Discord](https://vlct.mxme.pro/discord).

> 👉 Contenu complet : [English version](/en/)
