# build-and-battle — contexto del proyecto

Juego de Roblox tipo "construir y luego batallar". Dos bandos: cada uno construye
su fuerte durante la fase Building y se enfrentan en la fase Battle.

**Stack:** Rojo + Wally + Luau (strict en módulos nuevos), React (jsdotlua/react
17) para UI client-side, DataStoreService para persistencia (planeado).

## Diseño del juego (decisiones confirmadas)

- **2 equipos** por ahora. Arquitectura debe permitir expandir a 3-4 sin reescribir.
- **Lobby continuo** — un solo server, el ciclo de fases se repite indefinidamente con los players presentes. NO matchmaking por partida.
- **Tamaño**: empezar con **2v2** hardcoded para testing. Subir a 5v5 cuando todo funcione (config `MAX_PLAYERS_PER_TEAM`).
- **Territorio por team** — cada bando construye en su zona. Validación server impide placear fuera de la zona propia. *(Forma física del territorio: por definir.)*
- **Bloques roleados por color de team** — el bloque del enemigo se ve de su color. Saber visualmente qué construyó cada bando es parte de la información del juego.
- **Catálogo + loadout pre-partida** — el jugador elige sus armas (y bloques?) ANTES de empezar. No hay pickups durante la partida.
- **Win condition (inicial, la más fácil)**: al expirar el timer de Battle, contar bloques sobrevivientes por team. Gana el team con más. Refactorizable a "último team de pie" o "core block" después.
- **Construcción individual con resultado colectivo**: cada player construye su parte, pero los bloques del team comparten el conteo final.
- **Creatividad** como eje principal: el sistema debe permitir variedad de diseños de fuerte, no solo placas estandar. Presets/blueprints son extensión futura, no MVP.

---

## Estado actual

### Implementado
- **Loop de fases** server-authoritative (Intermission → Building → Battle → repeat). El countdown del cliente se sincroniza vía `endTimestamp` absoluto.
- **HUD React** con timer/round/fase. Store + componente App con `useState/useEffect` idiomático.
- **Placement system tipo Minecraft**: Mouse API + algoritmo `centro(bloqueHit) + normal*size`. Grid alineado al suelo. Validación cliente predictiva por `CellKey` + autoridad server.
- **BuildTool** con cooldown único compartido cliente/server.
- **Bloques tipados** (Wood/Stone/Metal) — definidos en `GameConfig.BLOCK_TYPES` con `Color`, `Material`, `Health`.
- **Logger / Result / Maid / Signal** como utilidades compartidas.
- **Owner por UserId** (no por Name) — base para friend-or-foe.

### Falta (en orden de prioridad)
- [ ] **Salud + destrucción de bloques** — el atributo `BlockHealth` se setea pero nadie lo lee. Sin esto Battle no tiene sentido.
- [ ] **Teams (bandos)** — usar `Teams` service nativo. Asignar al join. Color de bloque por team.
- [ ] **Selector de bloque** — cliente puede elegir entre Wood/Stone/Metal. UI mínima (slot bar tipo Minecraft).
- [ ] **Inventario con stack/cantidad** — cada player recibe N bloques por fase Building, contar al placear.
- [ ] **Armas (Battle phase)** — Tool con `damage`, `range`, `fireRate`, `ammo`. Raycast hit a `BlockHealth` y `Humanoid`.
- [ ] **Win condition** — definir y broadcast. Opciones: último team de pie, "core block" destruido, score por bloques sobrevivientes al final.
- [ ] **Persistencia (DataStore)** — currency, wins, unlocks. Después del balance económico estable.
- [ ] **Presets de construcción / blueprints** — guardar layout, reaplicar en partidas futuras.

---

## Arquitectura

```
src/
├── client/
│   ├── Controllers/        # Input + red, escriben al store
│   │   ├── Game/Build/     # BuildController + Predictor + Preview + Effects
│   │   └── UI/             # GameUIController + GameStateUIController
│   ├── Network/            # ClientNetwork wrapper
│   └── Presentation/       # React: Components/, Stores/, Views/, Core/Theme
│
├── server/
│   ├── Controllers/        # GameController (orquestador, único owner del GameState)
│   ├── Services/           # BuildService (autoritativo de bloques), GameStateService (broadcast)
│   ├── UseCases/           # PlaceBlock (factory + rate-limit), ChangeGameState (función)
│   ├── Factories/          # BuildTool (factory de Instance Tool)
│   └── Network/            # ServerNetwork wrapper
│
└── shared/
    ├── Config/             # GameConfig (constantes de gameplay)
    ├── Entities/           # Block, GameState (datos inmutables-ish)
    ├── Network/            # Events (single source of truth de RemoteEvent names)
    └── Utils/              # Logger, Maid, Result, Signal, Grid
```

**Reglas de dependencia:** `shared` ← `client`/`server` (nunca al revés).
`Entities` no requieren nada de Roblox excepto tipos básicos. `Services` y `UseCases`
son server-only, no se exponen al cliente.

---

## Decisiones de diseño tomadas

- **Identidad = UserId**, no display name. Player.Name puede colisionar o cambiar.
- **Validación de celda por `Grid.CellKey`** (no por distancia euclidiana ni `Vector3 ==`). Server y cliente comparten `shared/Utils/Grid.luau` para garantizar resultados bit-a-bit idénticos.
- **GameState con `endTimestamp` absoluto** (no contador decreciente). Late-joiners reciben el tiempo restante correcto sin reconciliación.
- **`GameController` único owner del `currentGameState`**. `GameStateService` son funciones de broadcast sin estado propio.
- **UI con React + store** (no manipulación imperativa). Controllers despachan a `HudStore`, el componente `App` suscribe vía `useEffect`.
- **Mouse API para placement** (no raycast manual desde cursor). Tiene mejor desambiguación de caras en bloques apilados.
- **Algoritmo Minecraft auténtico para placement**: si hit es bloque → `centro + normal*size`; si hit es mundo → snap del rawTarget. El cursor sobre cualquier punto de una cara → preview adyacente exacto, sin "saltar" entre celdas vecinas.

---

## Convenciones

- **Branch workflow**: `main` estable (releases). Todo el trabajo va en `dev`. Feature branches sale de `dev`, no de `main`.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`).
- **Logger.configure() en init scripts** — no leer GameConfig desde Logger.
- **Use cases como factory functions** o módulos de funciones puras, no clases con `.new()` cuando no hay estado.
- **Result pattern** para errores recuperables (`Result.Ok/Err/IsOk/IsErr/Unwrap*`). `error()` solo para invariantes que no deben pasar nunca.
- **`Maid` para cleanup** — connections, instances, funciones, objetos con `:Destroy()`.
- **Tipos `--!strict`** en módulos nuevos cuando sea trivial. Existentes pueden quedar sin anotar.

---

## Roadmap detallado

### Fase 1 — Combate básico (lo siguiente)

**1.1 Teams (primero — sin esto el resto no se puede testear)**
- Usar `Teams` service nativo de Roblox. 2 teams hardcoded por ahora (Red/Blue).
- Asignar al `Players.PlayerAdded` con balanceo (al team con menos players).
- `Player.TeamColor` refleja el color del bando.
- `GameConfig.MAX_PLAYERS_PER_TEAM = 2` por ahora.
- Spawns separados por team (un `SpawnLocation` por team, con `TeamColor` matching).

**1.2 Territorio por team**
- Definir AABB por team en `GameConfig.TERRITORIES = { Red = {min, max}, Blue = {...} }` (forma física por confirmar con el user).
- `BuildService:PlaceBlock` valida que la celda esté dentro del AABB del team del player → si no, `Result.Err("Out of territory")`.
- Cliente: el `BuildPredictor` reproduce la validación de territorio para colorear preview rojo.

**1.3 Bloques con color de team**
- `Block` entity ya tiene `ownerId`. Agregar `teamId` (o derivarlo de ownerId al placear).
- `BuildService:CreateBlockPart` aplica `BrickColor` según team en lugar del color del material — o mezcla material + tint de team.
- (Decidir si mantenemos el material visual (Wood/Stone/Metal) o lo reemplazamos con color de team. Probablemente: material por tipo, pequeño glow/outline por team.)

**1.4 Daño a bloques (server-side)**
- `BuildService:DamageBlock(blockId, amount)` → resta de `BlockHealth`, broadcast `BlockDamaged(id, newHealth)`, destruye si `<= 0` con `BlockDestroyed(id)`.
- Cliente: visual de salud (color tint según %), partículas/sonido al destruir.
- Friendly fire OFF por defecto: no aplicar daño si `block.teamId == attacker.teamId`.

**1.5 Selector de bloque (HUD)**
- HUD: barra inferior tipo Minecraft con slots (Wood/Stone/Metal). Tecla 1/2/3 o click.
- Cliente envía `PlaceBlockRequest(position, blockType)` — ya soportado.
- Por ahora cantidad ilimitada, después limitada por loadout.

**1.6 Arma básica (Pistol, fase Battle)**
- `server/Factories/Pistol.luau` (Tool similar a BuildTool pero entregada en fase Battle).
- Cliente: input `Tool.Activated` → raycast desde cámara → `Events.WeaponFire(hitInstance, hitPosition)`.
- Server: validar rate-limit + range + line-of-sight → aplicar daño a bloque (vía `BuildService:DamageBlock`) o a Humanoid.

**1.7 Win condition (la más fácil)**
- Al expirar el timer de Battle: contar `BlockHealth` total por team (suma de HPs sobrevivientes, no solo cantidad — premia tanto más bloques como bloques más sanos).
- Broadcast `GameEnded(winningTeamId, scores)`. HUD muestra resultado durante una Intermission extendida (10-15s) antes de la próxima ronda.
- `BuildService:ClearBlocks` ya existe — se llama al final, antes de la próxima ronda.

**1.8 Loadout pre-partida (versión mínima)**
- Durante Intermission, el jugador puede abrir un panel y elegir su arma (de las disponibles — por ahora solo Pistol hardcoded).
- Selección persiste en memoria (no DataStore todavía).
- Se aplica al pasar a Battle (server crea Tool del arma seleccionada).

### Fase 2 — Economía y progresión

- Inventario con cantidades limitadas por fase Building.
- Currency post-partida (más por bloques sobrevivientes, kills, win).
- Persistencia con `ProfileService` o `DataStoreService` raw.
- Unlocks: tipos de bloques o armas que se compran.

### Fase 3 — Profundidad

- Más tipos de bloques (Glass transparente, Spike daño, etc).
- Más armas con counter-play (sniper, escopeta, granada, lanzallamas).
- Presets / blueprints guardados.
- Matchmaking real (no solo single-server loop).

---

## Balance / partes y contrapartes (a definir)

Framework: cada elemento ofensivo tiene un counter defensivo y viceversa.
**Esta matriz hay que poblarla cuando agreguemos armas.** Ejemplo de cómo debería verse:

| Arma \ Bloque | Wood (HP 100) | Stone (HP 200) | Metal (HP 300) |
|---|---|---|---|
| Pistol (dmg X) | ? | ? | ? |
| Rifle (dmg Y) | ? | ? | ? |
| Explosive (AOE) | ? | ? | ? |

Y la cuenta inversa: costo de cada bloque, tiempo de placement, "rareza" en el inventario inicial. **Por definir.**

---

## Cómo trabajar con esta base de código

- Antes de tocar `BuildService` o `GameController`, leer este doc.
- Cualquier evento nuevo va a `shared/Network/Events.luau` con su contrato documentado en comentario.
- Nuevos use cases server-side van en `server/UseCases/` como factory function si tienen estado, módulo de funciones si no.
- UI nueva: componente React en `client/Presentation/Components/`, integración vía `HudStore` (no llamadas imperativas a la view).
- Tests: el proyecto no tiene framework de tests configurado todavía. Cuando llegue el momento, probablemente TestEZ o Jest.luau.

---

*Este archivo está fuera de `src/` y `Packages/`, así que Rojo no lo incluye en el build. Es solo contexto para Claude y para humanos que abran el repo.*
