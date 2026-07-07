# 🗺️ VLCT Deathrun - Guia para Mappers

Guia defensivo de scripting GSC para criadores de mapas de **CoD4 Deathrun**. Padrões, receitas e regras de sobrevivência que evitam crashes do servidor.

> **Novo aqui?** Comece com o [Início Rápido](#inicio-rapido-5-passos) abaixo, depois leia [Fundamentos](/en/fundamentals.md) (em inglês) - isso te dá tudo para escrever sua primeira armadilha.

---

## Início Rápido (5 passos)

O caminho mais rápido de zero a um mapa funcionando:

1. **Copie o arquivo de modelo**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_SEUNOME.gsc`

2. **Abra-o.** Role até `main()`. Apague as linhas `thread` para os recursos que você **não** quer (ex. remova `thread combat_room_sniper();` se seu mapa não tem sala de sniper). Mantenha `maps\mp\_load::main();` no topo.

3. **Para cada recurso que mantiver,** encontre a sua seção neste guia e edite os `targetname` de Radiant (os valores em `getEnt("...")`) para coincidir com o que você colocou no Radiant.

4. **Compile seu `.bsp`** no Radiant (`Compile > BSP + Light + Link`). Seu `.gsc` será assado no `.ff` quando o `linkMap` rodar.

5. **Teste:** `/map mp_dr_SEUNOME` no console do servidor. Após cada teste verifique `qconsole.log` por `script runtime error`.

---

## Por que este guia existe

O motor GSC do CoD4 tem bordas afiadas - uma única linha sem proteção pode:

* Crashar **o servidor inteiro** (ex. chamar uma builtin inexistente como `setmovespeed()`)
* Spammar milhares de erros por minuto (ex. acessar `level.activ.X` quando ninguém está no time activator)
* Quebrar seu mapa silenciosamente (ex. `targetname` duplicado no Radiant → `getEnt` retorna undefined)

> 🌐 A tradução em português ainda está em construção. [Ajude no Discord](https://vlct.mxme.pro/discord).

> 👉 Conteúdo completo: [English version](/en/)
