# Ingeniería inversa de *Subway Surfers Web* (Poki) y port a SIMS

> Documento de investigación técnica. No se han copiado assets, modelos, audio ni
> código propietario: se ha estudiado el comportamiento del build público y se ha
> reimplementado en GDScript con el arte, el personaje 3D y la escala de SIMS.

## 1. Objetivo y alcance

El objetivo era entender cómo está construido el *Subway Surfers* que Poki sirve en
navegador y trasladar sus mecánicas al minijuego **«Salir a correr» / PARK RUSH 3D**
del proyecto, manteniendo el personaje 3D del Sim como protagonista.

La investigación se hizo sobre el build público cargado en Firefox:

- Página: `https://poki.com/es/g/subway-surfers`
- Iframe del juego: `https://games.poki.com/5dd312fa-015f-11ea-ad56-9cb6d0d995f7`
- Build: `https://5dd312fa-015f-11ea-ad56-9cb6d0d995f7.gdn.poki.com/ec5c789a-69d7-476d-aa4e-1a0064850d79/`
- Bundle principal: `assets/index-DP5nq4Ec.js`
- Motor 3D: `assets/three-dhrglqPP.js`
- UI 2D: `assets/pixi-CrfqOQ4G.js`
- Puente de recursos: `assets/ResourceBridge-CKwMWwZ0.js`
- Datos de nivel: `assets/data/chunks-basic.json`, `chunks-full.json`

Hashes de las copias de trabajo:

| Archivo | SHA-256 |
|---|---|
| `index-DP5nq4Ec.js` | `3059f489b7cfe7d5b22792326e1b775c6689c0c39e88bc89e4c79f21508fda5a` |
| Bundle deobfuscado | `38fb66467b39aededc8ca8520919c941760122cdf40324d702f5fc52284ea637` |
| `chunks-basic.json` | `b82fe8479f10763013ceaa52a38c00135f468b0dac0177446f93d0a7fb7aace0` |
| `chunks-full.json` | `c41d3e0138a51308e5c3ba4e3bbaa1b49c30869428dacb1dbd815190397b59d1` |

## 2. Arquitectura observada

El juego **no es Unity WebGL ni un canvas monolítico**. Es un juego JavaScript
propio, con una arquitectura de entidades y sistemas:

- `window.game` expone el estado vivo: `hero`, `controller`, `level`, `route`,
  `camera`, `physics`, `hud`, `stats`, `missions`, `pickup`, `guard`, `pool`,
  `environment`, `tutorial`, `intro`, `leaderboard`.
- Render 3D con **Three.js** y HUD 2D con **PixiJS**.
- Entidades con componentes (`jump`, `roll`, `lane`, `hoverboard`, `jetpack`,
  `pogo`, `sneakers`, `magnet`, `multiplier`, `player`, `collider`…).
- Recursos empaquetados en `.pk` (geometría, texturas y animaciones) cargados por
  un `ResourceBridge`; los chunks de nivel se describen en JSON.
- El bundle principal está ofuscado con *string array* + control flow flattening.
  Se deobfuscó con `webcrack` y se formateó con Prettier para leerlo (1,79 MB,
  ~69.400 líneas). No se modificó el build original.

## 3. Constantes de diseño extraídas

La configuración global vive en el objeto exportado por `ResourceBridge` (en la
copia de trabajo, `rb.pretty.js`, líneas 1420-1520). Las más relevantes:

| Parámetro | Valor original | Equivalencia en SIMS |
|---|---:|---:|
| Ancho de carril | `20` unidades | `2,7 m` (`ANCHO_CARRIL`) |
| Bloque de nivel | `90` unidades | chunks de `32 m` |
| Altura del héroe | `11` unidades | `1,75 m` |
| Anchura del héroe | `4` unidades | ~`0,036 m` de radio de colisión |
| Gravedad | `0.055` por ms² | `42 m/s²` |
| Velocidad base | `110 → 220` unidades/s en 180 s | `22 → 46 m/s` por distancia |
| Salto normal | altura `20`, subida `0.41 s` | `14,2 m/s`, gravedad propia |
| Súper zapatillas | altura `40`, longitud `160` | `19,6 m/s` |
| Rodar | altura `5`, 30 frames (`0,5 s`) | `0,78 m`, `0,62 s` |
| Hoverboard | `30 s` | `30 s` |
| Imán / x2 / zapatillas | `10 s` + `5 s` por mejora permanente | `11 / 13 / 11 s` |
| Jetpack | `1000 + velocidad·200` unidades | `9 s`, altura `7,8 m` |
| Pogo | salto de `300` unidades, altura `160` | `4,6 s`, arco de `78 m` y `8,5 m` |
| Vagón | `18 × 29 × 58` unidades | `13,5 × 3,05 m` |
| Grupo de trenes | 1-3 vagones cada `60` unidades | 1 vagón por obstáculo |
| Tren en movimiento | `0.5 / 1 / 1.5 / 2` de velocidad relativa | `-8 … +10 m/s` |
| Cámara | `y=33.8`, `z=33`, `rotX=-0.375`, FOV `68` | `y≈4,55`, `z≈8,15`, FOV `66` |
| Túnel | baja `y` 18,3 y `rotX` 4,6° | baja `1,45 m` y +2° FOV |
| Reanimación | 1.ª gratis; luego `2^n` llaves | igual, con llaves del run |
| Guardia lejos / cebo | `70 / 10` unidades | `48 / 4,5 m` (escala de cámara) |

> Las unidades originales son mucho mayores que las de SIMS. La conversión no es
> literal: se ha conservado la **proporción** (carril ≈ 1,5 héores de ancho, salto
> ≈ 1,15 alturas, tren ≈ 1,7 alturas) y se ha adaptado a la escala de metros del
> runner actual.

## 4. Movimiento, choques y vidas

### Carriles

- `laneWidth = 20`; el héroe cambia de carril con una interpolación de
  `0,2-0,3 s` (`0.2 + (1 - speedRatio) * 0.1`).
- La inclinación lateral (`entity.ry`) se aplica solo si no está en hoverboard,
  jetpack o pogo.
- Si intenta salir por el borde, el sistema lanza `onBumpSideways("wall")`.

### Salto y rodar

- El salto usa una subida `sineOut` de `0.41 s` hasta `jumpHeight` y después
  gravedad; el doble salto y el salto alto son mejoras del hoverboard.
- Rodar reduce la altura del cuerpo a `5` unidades durante 30 frames y acelera
  la caída si se pulsa en el aire.
- Los *blockers* tienen tres perfiles: saltable (`height 26`), rodable
  (`height 19`, `bottom 10`) y bajo (`height 4`, `bottom 10`).

### Tropiezo y muerte

El detalle más importante que faltaba en SIMS:

1. Un choque frontal **no mata**: activa `stumble` (mareo de 3 s), sacude la
   cámara y acerca al guardia.
2. Si el jugador choca **otra vez** mientras está mareado, muere.
3. Un choque lateral hace `bump` al carril contrario; también cuenta como
   tropiezo.
4. El hoverboard absorbe el golpe, explota, elimina obstáculos cercanos y deja
   una ventana de invulnerabilidad.
5. Morir por tren hace que el guardia se aleje; morir por otro motivo hace que
   el guardia atrape al héroe.

En SIMS se ha implementado con un estado `TROPEZANDO` de 3 s, un obstáculo
marcado como `golpeado` (para no repetir el mismo impacto) y un segundo impacto
que lleva a `CAIDO`/`REANIMABLE`.

## 5. Generación de nivel

El nivel original se compone de **route sections** y **route chunks**:

- Cada chunk declara `_blockCount`; 1 bloque = 90 unidades.
- Los chunks se encadenan hasta `visibleMaxDistance = 1000`, con 10 chunks
  precargados y limpieza por detrás (`visibleMinDistance = -500`).
- Las secciones se eligen por nivel de dificultad (`easy`, `normal`, `hard`,
  `expert`) con pesos y una distancia mínima de repetición de 2700 unidades.
- Hay chunks específicos: `tunnel`, `tunnel_notrain`, `train_tops_*`,
  `train_tops_moving_*`, `ramp_*`, `bonus_*`, `pogostick_start`, `epic`,
  `no_gameplay`, `jetpack_landing`.
- Los `MovingTrainPlaceholder` tienen `_speed` 0.5, 1, 1.5 o 2; el sistema
  `Movable` calcula la posición objetivo y la velocidad relativa al jugador.
- Los patrones `b-s-b` (bloque, seguro, bloque), `s-s`, `s-s-s-s` y `choice`
  garantizan que siempre haya una ruta transitable.
- Las monedas se colocan con curvas (`CoinCurve`) y arcos de salto; los
  `PickupSpawnPoint` tienen dificultad y altura.
- Los túneles no son obstáculos sólidos: son triggers que bajan la cámara.
- Los checkpoints se usan en el tutorial para volver al último punto seguro.

En SIMS se ha mantenido el generador por oleadas justas, añadiendo trenes en
movimiento, túneles, rampas y una cadencia de power-ups por distancia.

## 6. Power-ups

El sistema original elige el pickup con una bolsa ponderada (líneas 22161-22175
de la copia deobfuscada):

| Tipo | Peso | Duración / efecto |
|---|---:|---|
| Imán | 29 | 10 s (+5 s por mejora) |
| Multiplicador x2 | 29 | 10 s (+5 s) |
| Súper zapatillas | 26 | 10 s (+5 s), salto 40 |
| Caja misteriosa | 18 | premio aleatorio |
| Jetpack | 14 | vuelo, monedas, aterrizaje seguro |
| Pogo | 14 | arco de 300 unidades + monedas |
| Llave | 2 | moneda de reanimación |

Además, la caja misteriosa podía dar monedas, llaves, tablas o puntos. En SIMS se
ha añadido esa caja y se ha mantenido la rareza de la llave, con una llave
garantizada cada ~700 m para que la reanimación sea accesible.

## 7. Puntuación, monedas y misiones

- La puntuación original **no suma monedas**: `data.score` acumula
  `distanceDelta × (multiplier + missionMultiplier)` y se muestra como
  `floor(score × 0.1)`.
- Las monedas van a un contador aparte y alimentan misiones.
- Hay misiones por sesión (`mission-pickup-coins`, `mission-jump`,
  `mission-roll`, `mission-hoverboard`, `mission-score`, etc.).
- La velocidad de animación depende de `speedRatio`; la cámara y el HUD también.

En SIMS se ha cambiado el marcador a `distancia × 10 × multiplicador` (las
monedas ya no dan puntos) y se han añadido **tres retos por carrera** con
recompensa de 750 puntos.

## 8. Cámara, túnel y guardia

- La cámara sigue al héroe con `mainX = stats.x × 0.75`, `mainY = cameraY +
  33.8`, `mainZ = stats.z + 33`, `rotX = -0.375`, FOV 68.
- En el túnel se interpola a una cámara baja (`-18.3` en Y y `-4.62°` en X).
- El guardia persigue a 70 unidades; al marearse el héroe se acerca a 10 en
  0,6 s; si el héroe muere, lo atrapa.
- La reanimación original cuesta `2^paidRevivals` llaves, con la primera gratis;
  al revivir se eliminan obstáculos y se vuelve al mismo punto.

En SIMS: cámara baja en túnel, guardia y perro 3D procedurales, reanimación con
llaves y primera gratis por carrera.

## 9. Qué se ha porteado a SIMS

| Mecánica original | Implementación en SIMS |
|---|---|
| Tres carriles, salto, rodar | `Runner_Simulacion` (ya existía, ajustado) |
| Tropiezo + segundo aviso + muerte | `TROPEZANDO` / `CAIDO`, `_tropezar()` / `_caer()` |
| Hoverboard 30 s y doble toque | `DURACION_TABLA = 30`, doble toque ya existente |
| Trenes en movimiento | `TREN_MOVIL` + `crear_tren_movil()`; algunos exprés en sentido contrario |
| Trenes de 3 vagones | `TREN_LARGO` / `TREN_LARGO_RAMPA` + `crear_tren_largo()` |
| Intro y reanudación | cámara de acercamiento de 1,35 s + cuenta atrás 3-2-1 |
| Túnel con cámara baja | `TUNEL` + `crear_tunel()` + `_factor_tunel` |
| Jetpack | `JETPACK`, vuelo, estela de monedas, aterrizaje seguro |
| Pogo | `POGO`, arco, monedas en tres carriles y power-up final |
| Súper zapatillas / imán / x2 | Ya existían, se mantienen |
| Caja misteriosa | `CAJA` con monedas, llave, tabla o puntos |
| Llaves y reanimación | `llaves`, modal de reanimación y coste `2^n` |
| Puntuación por distancia | `PUNTOS_POR_METRO = 10`, monedas aparte |
| Retos por carrera | `misiones` (3 aleatorias) y pantalla de pausa |
| Guardia y perro | `Runner_Guardia_3D` procedural |
| Reto activo en HUD | píldora con el primer reto incompleto y su progreso |
| Cámara y curvatura | Ya existían; se añade túnel y seguimiento de vuelo |

El personaje sigue siendo **el Sim 3D del proyecto** (`Runner_Personaje_3D`), con
su apariencia, ropa, envejecimiento y expresiones. No se ha importado ningún
modelo de Subway Surfers.

## 10. Qué no se ha copiado

- Geometrías, texturas, animaciones y audio originales (`.pk`, `.webp`, `.ogg`).
- El código JavaScript ofuscado, ni fragmentos literales.
- La economía real, anuncios, compras, ranking online y cuentas de Poki.
- Los personajes, tablas y cosméticos de Subway Surfers.

La implementación es una **reinterpretación de mecánicas** (que no son
copyrightables) con arte y código propios, dentro de la estética cartoon ya
existente en SIMS.

## 11. Verificación

- `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades -ginclude_subdirs -gexit` → **355/355 tests**.
- Tests específicos del runner: **33/33**, incluyendo tropiezo, tren móvil,
  jetpack, pogo, túnel, llaves, reanimación, puntuación y retos.
- Capturas QA: `godot --path . res://Escenas/Herramientas/Captura_Correr.tscn`
  genera menú, partida, túnel, techo, tabla, jetpack, pogo, guardia,
  reanimación, noche, pausa y resultado en `user://capturas_correr/`.

## 12. Validación con REA

Además de la lectura manual del bundle deobfuscado, el análisis se pasó por el
analizador **REA** (`rea-javascript-application`, versión 1) para dejar una
evidencia formal y comprobar que el inventario y el parseo eran completos:

| Evidencia | Alcance | Resultado |
|---|---|---|
| `ev_0cf933fc48860a584dd25be84c65269d6a5f8251c21324bdcd30dcbc074d465a` | `index-DP5nq4Ec.js` (2.108.975 bytes) | 417.643 nodos AST, 107 hallazgos, 0 fallos de parseo, cobertura parcial |
| `ev_886beda390a8d8abf5b673a8d34949ead582dfd85cf013a9010ba1d569d43002` | Directorio completo (17 archivos, 10.559.132 bytes) | 1.651.285 nodos AST, 711 hallazgos, 0 fallos de parseo; algunas ramas superaron el presupuesto de resultado y quedaron retenidas como estáticas |

Limitaciones declaradas por REA que se mantienen en este informe:

- El JavaScript y el HTML se analizaron como texto inerte: **no se ejecutó** el
  bootstrap ni el juego durante el análisis estático.
- Las relaciones estáticas no prueban ejecución en runtime.
- Las rutas y relaciones dinámicas pueden quedar sin resolver por la ofuscación.
- La cobertura del grafo es parcial; lo no observado no equivale a inexistencia.

Por eso la investigación combinó tres fuentes: el grafo estático de REA, la
lectura del bundle deobfuscado y la observación del runtime (`window.game`) en
el navegador. Las constantes de diseño y el comportamiento de los power-ups
proceden de las dos últimas, no de una ejecución instrumentada por REA.

## 13. Pendientes / siguientes pasos

1. Igualar la duración exacta de la velocidad (180 s) si se quiere un ritmo más
   pausado; ahora se conserva la progresión por distancia del runner de SIMS.
2. Añadir misiones diarias persistentes y recompensas de monedas/llaves entre
   carreras.
3. Ampliar el vestuario con tablas desbloqueables y poderes (doble salto,
   speed-up, stay-low, zap-sideways) como en los hoverboards originales.
4. Replicar los chunks completos (trenes de 3 vagones, rampas múltiples,
   `train_tops`) si se quiere una experiencia de varios minutos sin repetición.
5. Añadir un modo tutorial con cámara de intro y checkpoints, como el original.
