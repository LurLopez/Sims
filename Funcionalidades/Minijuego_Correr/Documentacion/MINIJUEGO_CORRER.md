# Minijuego «Salir a correr» / PARK RUSH 3D

> Runner infinito 3D de tres carriles con el Sim del proyecto como protagonista.
> Versión HTML autocontenida: [`MINIJUEGO_CORRER.html`](MINIJUEGO_CORRER.html).
> Investigación del juego original: [`SUBWAY_SURFERS_INGENIERIA_INVERSA.md`](SUBWAY_SURFERS_INGENIERIA_INVERSA.md).

## 1. Resumen

Minijuego vertical `720×1280` integrado en **Minijuegos**. El mundo es 3D real
(`SubViewport` + `Camera3D`), no una proyección 2.5D: vías ferroviarias, trenes
biselados, andenes, muros con grafiti, rampas, túneles, cielo procedural y
curvatura de horizonte estilo *Subway Surfers*.

La versión actual incorpora las mecánicas clave estudiadas en *Subway Surfers
Web* (Poki), adaptadas a la escala y al arte de SIMS:

- Tres carriles, salto, rodado, caída rápida y rampas a los techos.
- **Tropiezo antes de morir**: el primer choque marea 3 s; el segundo derriba.
- Trenes aparcados y **trenes en movimiento**, incluidos **trenes largos de 3 vagones** y **exprés en sentido contrario**.
- **Intro cinematográfica** con cámara de acercamiento, **túnel** con cámara rasante y cuenta atrás al reanudar.
- Tabla hoverboard de **30 s**, imán, x2, súper zapatillas, **jetpack**,
  **pogo cohete**, **llave** y **caja misteriosa**.
- Puntuación por distancia y multiplicador; monedas separadas.
- **Tres retos por carrera** y pantalla de pausa con progreso.
- **Guardia y perro** que persiguen al Sim cuando tropieza.
- **Reanimación**: primera gratis y siguientes con llaves (`1, 2, 4…`).

El corredor conserva el aspecto canónico del Sim (`Runner_Personaje_3D`), con
ropa equipada, envejecimiento, expresiones y animación articulada.

---

## 2. Archivos

| Archivo | Rol |
|---|---|
| `Scripts/Logica/Escena_Principal/Minijuego_Correr/Sistema_Correr.gd` | Autoload `Sistema_Correr`: récords, recompensa, aplicación al Sim y guardado en `user://minijuego_correr.cfg`. |
| `Scripts/GUI/Minijuego_Correr/Minijuego_Correr.gd` | Menú, HUD, gestos, teclado, pausa, reanimación, resultado y audio. |
| `Scripts/GUI/Minijuego_Correr/Runner_Simulacion.gd` | Lógica pura: carriles, salto, rodado, tropiezo, trenes, túneles, power-ups, monedas, retos, puntuación y reanimación. |
| `Scripts/GUI/Minijuego_Correr/Runner_Mundo.gd` | `SubViewport` 3D, cámara, iluminación, chunks, sincronización de entidades, partículas, clima y guardia. |
| `Scripts/GUI/Minijuego_Correr/Runner_Personaje_3D.gd` | Sim 3D articulado; añade jetpack, pogo, tabla, aura de imán, pose de vuelo y choque. |
| `Scripts/GUI/Minijuego_Correr/Runner_Escenario_3D.gd` | Materiales, chunks ferroviarios, trenes, rampas, túneles, monedas y power-ups esculpidos. |
| `Scripts/GUI/Minijuego_Correr/Runner_Mallas_3D.gd` | Generador de mallas biseladas (vagones, rampas, monedas, imán, estrella, tabla). |
| `Scripts/GUI/Minijuego_Correr/Runner_Guardia_3D.gd` | Guardia y perro procedurales que persiguen al corredor. |
| `Scripts/GUI/Minijuego_Correr/Runner_Texturas_3D.gd` | Texturas procedurales de balasto, traviesas, muros, trenes y sombras. |
| `Scripts/GUI/Minijuego_Correr/Sonidos_Correr.gd` | Pool de SFX en el bus `SFX`. |
| `Escenas/Minijuego_Correr/Minijuego_Correr.tscn` | Escena mínima que monta el controlador. |
| `Escenas/Herramientas/Captura_Correr.tscn` + `Captura_Correr.gd` | Capturas QA de menú, partida, túnel, techo, tabla, jetpack, pogo, guardia, reanimación, noche, pausa y resultado. |
| `Funcionalidades/Minijuego_Correr/Tests/` | Tests GUT de simulación, 3D y sistema de recompensas. |

### Arte y assets

- `Imagenes/Minijuego_Correr/` conserva el pack 2D histórico del parque.
- El runner 3D actual usa geometría y texturas generadas por código; no
  `preload` de PNG grandes en el arranque.
- La ropa sale de `Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada()` y se
  dibuja en el modelo 3D.

### Integración

- Autoload `Sistema_Correr` en `project.godot`.
- `Script_Principal` añade la tarjeta y abre el minijuego como `CanvasLayer`
  (capa 60). Al salir libera la capa y refresca el Sim.
- No cambia la orientación: el runner es vertical como el juego principal.

---

## 3. Controles

| Acción | Táctil | Teclado |
|---|---|---|
| Cambiar de carril | Desliza izquierda/derecha | `A`/`D`, flechas |
| Saltar | Desliza arriba o toca | `W`/`↑`/`Espacio` |
| Rodar | Desliza abajo | `S`/`↓` |
| Tabla | Doble toque o botón TABLA | `E`/`H`/`Shift` |
| Pausa | Botón superior derecho | `Esc`/`P` |
| Salir | Botón de volver / atrás Android | `Esc` en pausa/menú |

Gestos: 30 px de desplazamiento; doble toque dentro de 320 ms. Ratón emulado
como toque.

---

## 4. Reglas de juego

### Pista y velocidad

- Tres carriles; el jugador empieza en el central.
- Velocidad `22 → 46 m/s` con la distancia (`1 - e^(-d/950)`), más un
  multiplicador temporal del 62 % durante 0,85 s tras un tropiezo.
- Cambio de carril suavizado (`exp(-17·dt)`), salto `14,2 m/s` (zapatillas
  `19,6 m/s`), gravedad `42 m/s²`, rodado `0,62 s`.

### Obstáculos

| Tipo | Cómo se supera |
|---|---|
| `VALLA_BAJA` | Saltar o cambiar de carril |
| `ARCO_ALTO` | Rodar por debajo o saltar por encima |
| `SETO_ALTO` / vagón aparcado | Cambiar de carril o subir por rampa |
| `PASARELA_RAMPA` | Subir la rampa y correr por el techo |
| `CICLISTA` / vagoneta | Cambiar de carril |
| `TREN_MOVIL` | Cambiar de carril; se acerca o se aleja con velocidad relativa. Algunos son exprés y llegan muy rápido |
| `TREN_LARGO` / `TREN_LARGO_RAMPA` | Tren de **3 vagones** (40,5 m); cambiar de carril o subir por su rampa y correr por el techo |
| `TUNEL` | No colisiona; activa la cámara rasante |

### Tropiezo y reanimación

- Primer choque frontal o lateral: `TROPEZANDO` durante **3 s**, cámara con
  sacudida y guardia acercándose.
- El obstáculo que provocó el tropiezo se marca como golpeado para no repetir.
- Segundo choque mientras está mareado: `CAIDO`.
- Si hay tabla activa, absorbe el golpe, elimina obstáculos cercanos y deja
  1,35 s de invulnerabilidad.
- En `CAIDO` se abre el modal de reanimación con cuenta atrás de 6 s:
  - primera reanimación de la carrera: gratis;
  - siguientes: `1, 2, 4…` llaves;
  - si no hay llaves, solo se puede terminar la carrera.

### Monedas, power-ups y llaves

- Moneda: +1 moneda (no da puntos directamente).
- **Imán**: atrae monedas a 22 m durante 11 s.
- **Súper zapatillas**: salto reforzado 11 s.
- **x2**: duplica la puntuación 13 s.
- **Tabla**: 30 s; se activa con doble toque o botón; absorbe un choque y
  permite correr por los techos.
- **Jetpack**: 9 s de vuelo a 7,8 m; monedas en el aire y aterrizaje seguro.
- **Pogo**: arco de 78 m y 8,5 m de altura; monedas en tres carriles y un
  power-up al final.
- **Caja misteriosa**: +12 monedas, +1 llave, +1 tabla o +1.000 puntos.
- **Llave**: se usa para reanimarse; hay una garantizada cada ~700 m.

### Puntuación

```
puntos = floor(distancia × 10 × multiplicador)
```

- Las monedas no suman puntos (igual que en el original).
- Cada reto completado suma 750 puntos.
- Hitos cada 250 m con aviso y sonido.
- Récord de puntuación y de distancia en `Sistema_Correr`.

### Retos por carrera

Se eligen 3 aleatorios sin repetir entre:

- recoge 40 monedas;
- salta 10 veces;
- rueda 6 veces;
- cambia de carril 15 veces;
- corre 800 m;
- usa la tabla 1 vez.

El progreso se ve en la pausa y el resultado muestra cuántos se completaron.

---

## 5. Recompensa para el Sim

Una carrera de **≥ 100 m** aplica la recompensa al terminar. Salir desde la
pausa no la aplica.

| Concepto | Fórmula |
|---|---|
| Progreso de Deporte | `1 + floor(distancia / 400)`, máximo 4; +1 si ≥ 30 monedas |
| Salud física | `+3 + floor(distancia / 500)` (máx. +5) |
| Salud mental | `+2 + floor(distancia / 500)` (máx. +4) |
| Hambre | `-2 - floor(distancia / 500)` (máx. -4) |
| Descanso | `-2 - floor(distancia / 500)` (máx. -4) |
| Higiene | `-3 - floor(distancia / 500)` (máx. -5) |

Las monedas siguen siendo puntuación arcade, no dinero del Sim. La recompensa
usa `Actividades_Habilidades.Cambiar_Progreso(0)` y
`Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas(±1, índice)`.

Persistencia en `user://minijuego_correr.cfg`: `mejor_distancia`,
`mejor_puntuacion`, `monedas_totales`, `carreras`, `distancia_total`,
`ultima_distancia`, `ultima_puntuacion`, `ultima_monedas`,
`recompensas_aplicadas`.

---

## 6. Interfaz y presentación

- **Menú PARK RUSH 3D:** escena 3D viva con el Sim, cámara orbital suave,
  récord, estadísticas y botón JUGAR.
- **HUD:** puntuación, multiplicador, distancia, monedas, llaves, pausa, botón
  TABLA y medidores de power-ups (tabla, imán, salto+, x2, jetpack, pogo).
- **Avisos:** tropiezo, tabla salvadora, llave, caja misteriosa, reto completado
  e hitos.
- **Pausa:** continuar (con cuenta atrás 3-2-1), reiniciar, menú, salir y lista de retos con progreso.
- **Reanimación:** cuenta atrás, coste en llaves y saldo actual.
- **Resultado:** distancia, monedas, récord, retos completados, recompensa y
  botones OTRA VEZ / SALIR AL HUB.
- **Escenario:** estación ferroviaria urbana con tres vías, traviesas, raíles,
  andenes, muros con grafiti, pórticos, semáforos, puentes, árboles, farolas y
  cielo procedural día/atardecer/noche.
- **Personaje:** Sim 3D articulado con poses de carrera, salto, rodado, vuelo,
  pogo, tabla, choque y celebración; jetpack y pogo visibles.
- **Guardia:** guardia con gorra, chaleco reflectante y linterna + perro
  policía; se acerca al tropezar y atrapa al caer.

---

## 7. QA

### Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Minijuego_Correr -ginclude_subdirs -gexit
```

Resultado actual: **33/33 tests** del runner y **355/355** de la suite completa.

Cubren:

- carriles, salto, súper salto, rodado y caída rápida;
- valla, arco, rampa y techo;
- tropiezo lateral y frontal + segundo choque;
- tabla protectora y limpieza de obstáculos;
- imán entre carriles;
- tren móvil con velocidad relativa;
- túnel sin colisión y cámara rasante;
- jetpack, pogo, llaves y reanimación;
- puntuación por distancia/multiplicador y retos;
- generador de oleadas con al menos un carril pasable;
- apariencia 3D, peinados, atuendos y carga/limpieza de escena;
- recompensas, récords, persistencia y aplicación al Sim.

### Capturas

```bash
godot --path . res://Escenas/Herramientas/Captura_Correr.tscn
```

Salida en `user://capturas_correr/`:

- `01_menu.png`, `02_partida.png`, `02a2_tunel.png`, `02b_techo.png`
- `02c_tabla_powerups.png`, `02c2_jetpack.png`, `02c3_pogo.png`
- `02c4_guardia.png`, `02c5_reanimar.png`, `02d_otro_sim.png`
- `02e_noche.png`, `03_pausa.png`, `04_resultado.png`

---

## 8. Decisiones técnicas

- **Lógica pura separada:** `Runner_Simulacion` no toca nodos 3D; se puede
  probar con GUT y reproducir con semilla.
- **Trenes de 3 vagones:** el obstáculo mide 40,5 m y se dibuja como tres vagones
  independientes con sus sombras y enganches; la rampa se coloca delante y
  permite rutas de techo largas.
- **Intro y cuenta atrás:** la intro usa una cámara que interpola al encuadre de
  carrera; la reanudación desde pausa hace 3-2-1 para que el jugador recupere el
  ritmo.
- **Personaje propio:** el 3D del Sim se reutiliza en todos los estados; el
  jetpack y el pogo son accesorios procedurales, no modelos externos.
- **Escala de metros:** carriles de 2,7 m y cámara baja para que la velocidad
  se lea bien en vertical.
- **Trenes móviles con velocidad relativa:** se suman al desplazamiento del
  mundo, de modo que un tren puede alcanzar o dejar atrás al jugador.
- **Túnel sin colisión:** es una cobertura visual/cámara; la simulación solo
  marca `tunel` para que `Runner_Mundo` baje la cámara.
- **Reanimación con llaves del run:** evita moneda premium y mantiene la
  economía del Sim intacta.
- **Retos por carrera:** dan variedad sin añadir persistencia diaria todavía.
- **Rendimiento:** mallas compartidas, `MultiMesh` para traviesas/partículas,
  texturas procedurales y carga perezosa de la escena.

---

## 9. Futuro

1. Misiones diarias persistentes y recompensas entre carreras.
2. Tablas desbloqueables con poderes (doble salto, speed-up, stay-low).
3. Chunks largos de 3 vagones y `train_tops` para runs de varios minutos.
4. Tutorial con cámara de intro, checkpoints y guardia.
5. Ranking local por personaje y logros permanentes.
