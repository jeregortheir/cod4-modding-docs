# 🗺️ VLCT Deathrun - Guía de Mapeo

Guía defensiva de scripting GSC para creadores de mapas de **CoD4 Deathrun**. Patrones, recetas y reglas de supervivencia que evitan crashes del servidor.

> **¿Nuevo aquí?** Empieza con el [Inicio Rápido](#inicio-rapido-5-pasos) abajo, luego lee [Fundamentos](/en/fundamentals.md) (en inglés) - eso te da todo para escribir tu primera trampa.

---

## Inicio Rápido (5 pasos)

El camino más rápido de cero a un mapa funcionando:

1. **Copia el archivo de plantilla**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_TUNOMBRE.gsc`

2. **Ábrelo.** Desplázate hasta `main()`. Borra las líneas `thread` para las funciones que **no** quieras (ej. quita `thread combat_room_sniper();` si tu mapa no tiene sala de francotirador). Mantén `maps\mp\_load::main();` arriba.

3. **Para cada función que mantengas,** encuentra su sección en esta guía y edita los `targetname` de Radiant (los valores dentro de `getEnt("...")`) para que coincidan con lo que pusiste en Radiant.

4. **Compila tu `.bsp`** en Radiant (`Compile > BSP + Light + Link`). Tu `.gsc` será horneado en el `.ff` cuando corra `linkMap`.

5. **Prueba:** `/map mp_dr_TUNOMBRE` en la consola del servidor. Después de cada prueba revisa `qconsole.log` por `script runtime error`.

---

## Por qué existe esta guía

El motor GSC de CoD4 tiene bordes filosos - una sola línea sin protección puede:

* Crashear **el servidor entero** (ej. llamar a una función inexistente como `setmovespeed()`)
* Spamear miles de errores por minuto (ej. acceder a `level.activ.X` cuando nadie está en el equipo activador)
* Romper tu mapa silenciosamente (ej. `targetname` duplicado en Radiant → `getEnt` devuelve undefined)

> 🌐 La traducción al español aún está en construcción. [Ayuda en Discord](https://vlct.mxme.pro/discord).

> 👉 Contenido completo: [English version](/en/)
