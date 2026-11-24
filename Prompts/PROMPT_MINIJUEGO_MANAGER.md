# Prompt de Implementación — Minijuego «El Mánager» (Modo Club tipo Top Eleven)

> **Cómo usarlo:** Copia todo el bloque a partir de `PROMPT (pegar desde aquí)` y pégalo en el agente implementador. Esta especificación está verificada contra el código real de `/home/lur/sims-0.33` (Godot 4.4 / GDScript 2.0). Cierra todas las decisiones de diseño para que el agente no tenga que preguntar nada.

---

PROMPT (pegar desde aquí)

### Tarea: Implementar «El Mánager», el minijuego de gestión de club (Fase 2 del fútbol) + retiro del futbolista + tarjeta en Minijuegos

Actúa como **Game Designer Senior y Arquitecto de Godot 4.4 (GDScript 2.0)** en `/home/lur/sims-0.33` (**SIMS 0.33**). Implementa de principio a fin un modo de gestión de club jugable, inspirado en la fantasía de *Top Eleven* pero con identidad propia y sin usar marcas, escudos, clubes ni jugadores reales:

1. **«El Mánager»** como tarjeta dentro del apartado `Minijuegos` existente (junto a Cocina y Correr), con estado bloqueado/desbloqueado/activo.
2. **Desbloqueo por retiro del futbolista** (desde `Panel_Futbol`) o, si el Sim nunca fue futbolista, mediante un **título de entrenador** pagado con dinero personal.
3. **Modo club completo MVP:** elección de club, plantilla de 18 jugadores, alineación 11, formaciones, táctica, mercado de fichajes, 3 acciones por jornada, liga de 8 clubes y 7 jornadas, economía separada del club, confianza de la directiva, despido y fin de temporada.
4. **Minijuego de partido «Banquillo en 90 segundos»:** 5 decisiones tácticas con temporizador, dentro del partido, que sustituyen la simulación del partido del club. Siempre hay opción de simular.
5. **Persistencia robusta** en `Guardar_Variables_Dinamicas.dat`, compatible con partidas antiguas, sin romper la carrera de futbolista ni la matriz de actividades.
6. **Tests GUT** del motor puro y de la integración, documentación y actualización del roadmap.

No pidas confirmación interactiva: lee los archivos reales antes de editar, implementa todo, ejecuta los tests y entrega un informe técnico detallado.

---

#### 1. Contexto Obligatorio del Proyecto (Léelo antes de editar)

* `CLAUDE.md`, `project.godot`, `ROADMAP.md`.
* `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` — `Carrera_Futbol`, `Cocina_Estado`, `Dinero`, `Mensajes`, `Minute_Day`, `Minute_Minute`.
* `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` — `Modo_Rapido`, `Multiplicador_Precios()`, `Calcular_Edad()`.
* `Scripts/Globales/Script_Principal.gd` — `_Crear_Pantalla_Minijuegos()`, `_Actualizar_Pantalla_Minijuegos()`, `_Actualizar_Badges()`, `_on_carrera_futbol_pressed()`, patrón `Capa_Panel_Futbol` + `Panel_Futbol.tscn`.
* `Scripts/Globales/Menu.gd` — reseteo de nueva partida (incluye `Cocina_Estado` y `Carrera_Futbol`).
* `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` — `save_game()`, `load_game()`, `_Normalizar_Carrera_Futbol()`, `_Normalizar_Cocina_Estado()`.
* `Scripts/Logica/Escena_Principal/Actividades/Futbol/Sistema_Futbol.gd` — `Carrera_Activa()`, `Obtener_Division()`, `Rescindir_Contrato()`, `Tick_Minuto()`, `_Limpiar_Bloques_Futbol()`.
* `Scripts/Logica/Escena_Principal/Actividades/Futbol/Simulador_Futbol.gd` — nombres de división y fórmulas existentes que deben respetarse.
* `Scripts/GUI/Escena_Principal/Actividades/Futbol/Panel_Futbol_GUI.gd` y `Escenas/Escena_Principal/Panel_Futbol.tscn`.
* `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` — `Actualizar_Horario()`, donde ya se llama `Sistema_Futbol.Tick_Minuto()`.
* `Scripts/GUI/Escena_Principal/Estilos_UI.gd` — `boton()`, `titulo()`, `texto()`, `parrafo()`, `caja()`, `pill_estado()`, `badge_icono()`, `barra_fondo()`, `barra_relleno()`.
* `Scripts/Logica/Mensajes/Mensaje.gd` — creación de mensajes del buzón.
* `Funcionalidades/Actividades/Futbol/Documentacion/CARRERA_FUTBOL.md` y `Prompts/MEGA_PROMPT_CONTEXTO.md`.
* `Funcionalidades/Minijuego_Cocina/Tests/test_minijuego_cocina.gd` — patrón de tests GUT e integración con la pantalla de Minijuegos.

**Estado real de partida:** la Fase 1 (futbolista) está implementada; la Fase 2 (mánager) estaba pospuesta. La pantalla `Pantalla_Minijuegos` ya existe, tiene tarjetas de Cocina y Correr y una sección `PRÓXIMOS MINIJUEGOS`. El autoload `Sistema_Futbol` usa `Carrera_Futbol` y no tiene retiro. No existe ningún `Sistema_Manager`.

---

#### 2. Decisiones de Diseño Cerradas (No reabrir)

1. **Es un minijuego asíncrono, no un trabajo:** no añade bloques a `Matriz_Jugador`, no ocupa horario y no bloquea estudios ni empleos. Se juega desde `Minijuegos` con el reloj del Sim corriendo.
2. **Identidad propia:** el juego se llama **«El Mánager»**. No se usan nombres, escudos, kits, competiciones ni jugadores reales. Todos los clubes y futbolistas son ficticios y generados.
3. **Dos vías de desbloqueo:**
   * **Retiro como futbolista:** disponible desde los 32 años o tras 3 temporadas completadas. Genera reputación según el legado y 3 ofertas de club.
   * **Título de entrenador:** pago único de **1.500 € × `Multiplicador_Precios()`** desde la tarjeta de Minijuegos. Solo si no hay carrera de futbolista activa. Reputación inicial 25 y 3 ofertas de 3ª División.
4. **Un club por partida, sin dinero infinito:** el presupuesto del club es independiente del `Dinero` personal del Sim. El único flujo hacia el Sim son el salario y las primas que fija la directiva; el Sim no puede retirar libremente dinero del club ni fijarse su propio sueldo.
5. **Temporada = 7 jornadas, liga de 8 clubes:** una vuelta única, un partido por jornada. En Modo Normal se juega **una jornada por día real** (ventana de todo el día; si no se juega, se auto-simula a las 23:59). En Modo Rápido se puede jugar la temporada completa en una sola sesión con el botón **Jugar jornada**, sin esperar al reloj; el reloj de la vida sigue avanzando.
6. **Partido jugable:** 5 decisiones tácticas, 15 segundos por decisión (90 segundos en total), con opción **Simular** y auto-decisión si se agota el tiempo. El resultado del minijuego es el resultado real del partido del club.
7. **MVP acotado:** no hay 11v11 en tiempo real, ni animaciones de jugadores, ni multioposición avanzada, ni red de ojeadores (la acción **Ojear** solo refresca el mercado), ni cuerpo técnico, ni academia, ni estadio construible, ni Champions, ni fichajes entre IA. Se deja la arquitectura preparada para ampliar.
8. **Sin softlocks:** siempre hay auto-simulación, auto-alineación de emergencia, ofertas de repuesto y un camino para volver a entrenar tras un despido. El jugador nunca se queda sin poder continuar.

---

#### 3. Reglas Duras e Inviolables

1. **Godot 4.4 / GDScript 2.0:** tipado explícito en todas las funciones y variables nuevas. Prohibida la sintaxis de Godot 3.
2. **No duplicar lo existente:** reutiliza `Carrera_Futbol`, `Sistema_Futbol`, `Estilos_UI`, `Mensaje`, `Multiplicador_Precios()`, el patrón de `Panel_Futbol` y la pantalla de Minijuegos. No crees otra pantalla de minijuegos ni otro sistema de guardado.
3. **Claves ASCII estables:** sin tildes, ñ, espacios ni mayúsculas arbitrarias en claves de diccionarios y guardado. Los textos visibles sí llevan tildes.
4. **Motor puro testeable:** toda la matemática (generación, fuerzas, probabilidades, resultados, tabla, economía, confianza, legado, ofertas) vive en `Simulador_Manager.gd` como funciones estáticas/puras. `Sistema_Manager.gd` solo orquesta estado, señales, guardado e integración con la UI.
5. **Sin `save_game()` dentro de `_process`:** guarda solo al desbloquear, aceptar club, cambiar alineación/táctica, entrenar, fichar/vender, terminar partido/jornada, cambiar de día y cerrar el panel con cambios. Nunca cada frame ni en mitad de una decisión del partido (si la app se cierra a mitad, el partido se reinicia o se auto-simula, no se guarda un contexto parcial).
6. **Rendimiento:** la plantilla tiene 18 jugadores y la liga 8 clubes; nada de recorrer la matriz de 1440×574. `Tick_Minuto()` debe salir inmediatamente si el mánager no está activo. Prohibido cargar texturas pesadas al arrancar; el panel se instancia bajo demanda.
7. **Retrocompatibilidad:** un save sin `Manager_Estado` debe cargar sin errores y quedar bloqueado. Un save con `Manager_Estado` incompleto debe normalizarse con valores por defecto. Nunca borres la carrera de futbolista al cargar.
8. **Sin dependencias de arte externas:** la tarjeta, los escudos y el campo se dibujan por código (formas, gradientes, iniciales). Si más adelante se añade arte, debe ser opcional y no bloquear la implementación.
9. **Portrait 720×1280:** todo el panel y el partido se diseñan en vertical. No rotar la pantalla. Ningún contenido esencial puede quedar fuera de 720 px de ancho.
10. **Accesibilidad:** botones de al menos 44 px de alto, estados con texto además de color, timer con número visible, contraste suficiente y textos legibles a 12–14 px como mínimo.

---

#### 4. Especificación Técnica Detallada

##### 4.1. Estado Persistente (`Variables_Dinamicas.gd`)

Añadir `MANAGER_ESTADO_BASE` y `var Manager_Estado: Dictionary = MANAGER_ESTADO_BASE.duplicate(true)`, con helper `Manager_Estado_Por_Defecto() -> Dictionary`.

```gdscript
const MANAGER_ESTADO_BASE: Dictionary = {
    "Version": 1,
    "Desbloqueado": false,
    "Titulo_Entrenador": false,
    "Retirado_Como_Jugador": false,
    "Activo": false,
    "Reputacion": 25,
    "Ofertas": [],
    "Ofertas_Dia": -1,
    "Club": {},
    "Liga": {},
    "Historial": [],
    "Ultimo_Resultado": {},
    "Partido_Pendiente": false,
    "Ultima_Jornada_Dia": -1,
    "Dia_Ultimo_Tick": -1,
    "Aviso_Despido": false
}
```

Cuando hay club, `Club` contiene:

```gdscript
{
    "id": "club_...",
    "nombre": "Atletico del Puerto",
    "ciudad": "Puerto",
    "colores": ["#1d4ed8", "#f8fafc"],
    "division": 4,                 # 4 = 3ª Regional, 1 = Superliga
    "temporada": 1,
    "temporada_cerrada": false,
    "presupuesto": 30000,
    "aficion": 1200,
    "estadio_nivel": 1,
    "confianza_directiva": 60.0,
    "paciencia": 55,
    "objetivo": "top_3",           # top_3, top_4, top_2, campeon
    "formacion": "4-4-2",
    "tactica": {
        "mentalidad": "equilibrada",  # defensiva, equilibrada, ofensiva
        "presion": "media",           # baja, media, alta
        "pase": "mixto",              # corto, mixto, largo
        "ritmo": "normal"             # bajo, normal, alto
    },
    "plantilla": [],               # 18 jugadores
    "alineacion": [],              # 11 ids
    "acciones_jornada": 3,
    "ultima_jornada_acciones": -1,
    "fichajes_jornada": 0,
    "mercado": [],
    "ultima_jornada_mercado": -1,
    "dias_confianza_baja": 0,
    "historial_temporadas": [],
    "racha": []                    # "V", "E", "D"
}
```

`Liga` contiene:

```gdscript
{
    "equipos": [
        {"id": "club_...", "nombre": "...", "fuerza": 55.0, "es_jugador": true, "colores": ["#...", "#..."]}
    ],
    "calendario": [
        {"jornada": 1, "local": "club_a", "visitante": "club_b"}
    ],
    "resultados": [
        {"jornada": 1, "local": "club_a", "visitante": "club_b", "goles_local": 2, "goles_visitante": 1}
    ],
    "jornada_actual": 0
}
```

**Fuente única de verdad:** la tabla se calcula desde `resultados`; no guardes puntos duplicados por equipo. `jornada_actual` es el número de jornadas completadas (0–7). La fuerza del club del jugador se calcula en cada partido desde el once y la táctica; `Liga.equipos[].fuerza` se usa para los 7 clubes IA y como referencia de la división. `Ultimo_Resultado` guarda solo el resumen del último partido para la pestaña Inicio (marcador, rival, goleadores, MVP, ingresos); no es fuente de verdad de la tabla.

Un jugador de la plantilla:

```gdscript
{
    "id": "p01",
    "nombre": "Nombre Apellido",
    "posicion": "POR",             # POR, DEF, MED, DEL
    "edad": 24,
    "media": 62,
    "potencial": 74,
    "ritmo": 61, "tiro": 48, "pase": 57, "defensa": 68, "fisico": 66,
    "porteria": 20,
    "valor": 3600,
    "salario": 248,
    "contrato": 2,
    "moral": 70,
    "estado_fisico": 92,
    "forma": 65,
    "lesion_dias": 0,
    "goles": 0,
    "asistencias": 0,
    "partidos": 0
}
```

**Persistencia:**
* `Guardar_Variables_Dinamicas.gd`: guardar `"Manager_Estado": Variables_Dinamicas.Manager_Estado.duplicate(true)` y cargarlo con `_Normalizar_Manager_Estado(game_data.get("Manager_Estado", {}))`.
* La normalización debe completar claves ausentes, clampear números, validar que `plantilla` tenga entre 14 y 22 jugadores (reparar con canteranos o recortar si está fuera de rango), que `alineacion` tenga 11 ids únicos existentes y que `calendario/resultados` sean arrays. Si `Retirado_Como_Jugador`, `Titulo_Entrenador` o `Carrera_Futbol.Retirado` es true, forzar `Desbloqueado=true` (y `Retirado_Como_Jugador=true` si la carrera está retirada). Si `Activo` es true pero `Club` o `Liga` están corruptos, dejar `Activo=false`, conservar `Desbloqueado` y generar ofertas; nunca crashear.
* Si un save corrupto tiene a la vez `Manager_Estado.Activo` y `Carrera_Futbol.Activo`, priorizar la carrera de futbolista: desactivar el club de mánager, conservar `Desbloqueado` y registrar un aviso; nunca borrar la carrera de jugador.
* Si `jornada_actual > 7`, clampear a 7. Si `jornada_actual == 7` y `temporada_cerrada == false`, ejecutar el cierre de temporada una sola vez y marcar `temporada_cerrada=true`; si ya es true, solo mostrar el resumen y el botón **Nueva temporada**. Nunca pagar dos veces premios ni primas.
* `Menu.gd`: resetear `Manager_Estado` en nueva partida y llamar a `Sistema_Manager.Reiniciar_Estado()` si existe.
* Fallback de saves antiguos: sin `Manager_Estado`, todo bloqueado; `Carrera_Futbol` intacta.

---

##### 4.2. Autoload `Sistema_Manager` + Motor Puro

Crear:

| Archivo | Responsabilidad |
|---|---|
| `Scripts/Logica/Escena_Principal/Manager/Simulador_Manager.gd` | Motor puro: generación, fuerzas, táctica, probabilidades, partido, tabla, economía, confianza, legado y ofertas. `class_name Simulador_Manager extends RefCounted`. |
| `Scripts/Logica/Escena_Principal/Manager/Sistema_Manager.gd` | Autoload `Sistema_Manager`: estado, señales, persistencia, tick por minuto/cambio de día, acciones y fachada para la UI. |
| `Scripts/Logica/Escena_Principal/Manager/Datos_Manager.gd` | Datos ficticios: 24 nombres de club, 12 ciudades, 32 nombres, 32 apellidos, paletas, formaciones. Sin recursos externos. |
| `Scripts/GUI/Escena_Principal/Manager/Cresta_Manager.gd` | `Control` que dibuja un escudo procedural con dos colores e iniciales. |
| `Scripts/GUI/Escena_Principal/Manager/Panel_Manager.gd` | Panel vertical con pestañas. |
| `Scripts/GUI/Escena_Principal/Manager/Panel_Manager_Partido.gd` | Minijuego de 5 decisiones y temporizador. |
| `Escenas/Escena_Principal/Panel_Manager.tscn` | Escena raíz del panel. |
| `Escenas/Escena_Principal/Panel_Manager_Partido.tscn` | Escena raíz del partido. |
| `Funcionalidades/Manager/Tests/test_manager.gd` | Tests GUT. |
| `Funcionalidades/Manager/Documentacion/MANAGER.md` | Documentación técnica. |

Registrar `Sistema_Manager="*res://Scripts/Logica/Escena_Principal/Manager/Sistema_Manager.gd"` en `project.godot`, después de `Sistema_Futbol`.

**Señales del autoload:**
```gdscript
signal estado_cambiado
signal manager_desbloqueado
signal partido_pendiente
signal partido_finalizado(resultado: Dictionary)
signal temporada_finalizada(resumen: Dictionary)
signal club_destituido
```

**API mínima (fachada):**
```gdscript
Esta_Desbloqueado() -> bool
Esta_Activo() -> bool
Reiniciar_Estado() -> void
Puede_Comprar_Titulo() -> Dictionary          # {ok, motivo, coste}
Comprar_Titulo_Entrenador() -> Dictionary
Desbloquear_Por_Retiro() -> Dictionary
Calcular_Legado(carrera: Dictionary) -> int
Generar_Ofertas(forzar: bool = false) -> Array
Aceptar_Oferta(indice: int) -> Dictionary     # {ok, motivo}
Renunciar_Al_Club() -> void
Obtener_Club() -> Dictionary
Obtener_Plantilla() -> Array
Obtener_Alineacion() -> Array
Obtener_Tabla() -> Array
Obtener_Siguiente_Partido() -> Dictionary
Cambiar_Formacion(formacion: String) -> bool
Cambiar_Tactica(clave: String, valor: String) -> bool
Asignar_Titular(id_jugador: String, slot: int) -> bool
Autoalinear() -> void
Entrenar(tipo: String) -> Dictionary          # ataque, defensa, fisico
Recuperar(id_jugador: String) -> Dictionary
Ojear() -> Dictionary
Marketing() -> Dictionary
Comprar_Jugador(id_jugador: String) -> Dictionary
Vender_Jugador(id_jugador: String) -> Dictionary
Renovar_Contrato(id_jugador: String, anios: int) -> Dictionary
Iniciar_Partido(usar_minijuego: bool = true) -> Dictionary
Resolver_Decision_Partido(opcion_id: String) -> Dictionary
Finalizar_Partido(resultado: Dictionary) -> Dictionary
Simular_Partido_Actual() -> Dictionary
Tick_Minuto() -> void
Hay_Novedad() -> bool
```

`Sistema_Manager` no debe guardar estado propio fuera de `Variables_Dinamicas.Manager_Estado` (salvo cachés de UI no persistentes). Así el guardado/carga y el reset son triviales. No resuelvas referencias a `Sistema_Futbol` en `_ready()`: usa referencias perezosas (`get_node_or_null("/root/Sistema_Futbol")`) para no depender del orden de autoloads.

**RNG determinista:** usa `RandomNumberGenerator` con semilla explícita en todas las funciones puras. Prohibido `randi()`/`randf()` globales dentro del motor. La semilla del partido se guarda en el contexto para que una recarga no cambie el resultado.

---

##### 4.3. Desbloqueo, Retiro y Ofertas

**A. Retiro como futbolista**
* En `Sistema_Futbol.gd` añadir:
  * `Puede_Retirarse() -> bool`: `Carrera_Activa()` y (`Variables_Estaticas.Calcular_Edad() >= 32` o `Temporadas_Jugadas >= 3`).
  * `Retirarse_Como_Jugador() -> Dictionary`: valida, limpia bloques con la misma lógica de `_Limpiar_Bloques_Futbol(_Minuto_Abs())`, marca `Activo=false`, `Estado_Temporada="Retirado"`, `Retirado=true`, `Anio_Retiro=Variables_Estaticas.Calcular_Edad()`, guarda el legado y llama a `Sistema_Manager.Desbloquear_Por_Retiro()`. Envía un `Mensaje` al buzón y emite una señal.
  * Añadir a `CARRERA_FUTBOL_BASE`: `"Retirado": false`, `"Anio_Retiro": -1`, `"Legado": 0`; normalizar en `_Normalizar_Carrera_Futbol()`.
* En `Panel_Futbol_GUI.gd`, cuando `Puede_Retirarse()`: mostrar una tarjeta/acción **«Colgar las botas y dar el salto al banquillo»** con `ConfirmationDialog`. Al confirmar, llamar a `Retirarse_Como_Jugador()`, mostrar resumen (división, goles, títulos, legado, reputación) y refrescar/cerrar el panel. No permitir retirarse si hay un partido en curso o un conflicto de ascenso pendiente.

**B. Exclusividad jugador/mánager**
* Si `Manager_Estado.Desbloqueado` es true (por retiro o por título), `Sistema_Futbol.Fichar()` debe rechazar cualquier fichaje con el motivo «Ya has iniciado tu carrera como entrenador» y `Panel_Futbol_GUI` debe comprobar `Manager_Estado.Desbloqueado` (no solo `Retirado`) para mostrar el estado de retirado/entrenador y ocultar el botón de prueba de fichaje. No se puede compaginar la carrera de futbolista con El Mánager.
* Si el mánager es despedido, puede seguir entrenando otros clubes; no vuelve a ser futbolista.

**C. Legado y reputación**
```text
division_alcanzada = 5 - Division        # 4ª división -> 1; Superliga -> 4
legado = 15*division_alcanzada + 30*Titulos_Superliga + 2*min(Temporadas_Jugadas, 10)
         + min(Goles_Totales, 150)/6 + min(Asistencias_Totales, 100)/10
legado = clamp(round(legado), 0, 100)
reputacion = clamp(20 + legado, 20, 95)
```
Con título de entrenador: `reputacion = 25`.

**D. Título de entrenador**
* `Puede_Comprar_Titulo()` devuelve `{ok, motivo, coste}`:
  * No desbloqueado, no activo, sin carrera de futbolista activa.
  * `coste = roundi(1500 * Variables_Estaticas.Multiplicador_Precios())`.
  * `Dinero >= coste`.
* `Comprar_Titulo_Entrenador()` descuenta el coste, marca `Titulo_Entrenador=true`, `Desbloqueado=true`, `Reputacion=25`, genera ofertas, guarda, envía mensaje y emite `manager_desbloqueado`.
* Si hay carrera activa, el motivo es: «Retírate desde Carrera futbolística para desbloquear El Mánager».

**E. Ofertas de club**
* `Generar_Ofertas()` crea 3 clubes ficticios distintos según reputación:

| Reputación | Ofertas |
|---|---|
| 0–34 | 3 × División 4 |
| 35–54 | 2 × División 4, 1 × División 3 |
| 55–69 | 1 × División 4, 2 × División 3 |
| 70–79 | 2 × División 3, 1 × División 2 |
| 80–89 | 1 × División 3, 2 × División 2 |
| 90–100 | 2 × División 2, 1 × División 1 |

* Cada oferta: `id`, `nombre`, `ciudad`, `colores`, `division`, `presupuesto`, `fuerza_plantilla`, `objetivo`, `aficion`, `estadio_nivel`, `paciencia`.
* Presupuesto base: Div 4: 30.000 €; Div 3: 120.000 €; Div 2: 500.000 €; Div 1: 1.800.000 €. Aplicar variación ±20 % y multiplicador `1.0 + reputacion/200`.
* Fuerza base de plantilla: Div 4: 55; Div 3: 65; Div 2: 75; Div 1: 84. Sumar `reputacion/10` y variación ±3.
* `paciencia = clamp(68 - reputacion/4 + rng.randi_range(-5, 5), 35, 70)`.
* Objetivos: Div 4 `top_3` (o `campeon` con reputación ≥ 60); Div 3 `top_4` (o `top_2` con reputación ≥ 70); Div 2 `top_2` (o `campeon` con reputación ≥ 80); Div 1 `campeon` (o `top_3` con reputación < 80).
* `Ofertas_Dia` evita regenerar el mismo día. Si no hay ofertas y no hay club, el panel debe poder generarlas de nuevo (botón **Buscar club**) sin softlock.
* `Aceptar_Oferta(indice)`: valida, inicializa `Club` y `Liga`, genera 18 jugadores y 7 clubes rivales, crea el calendario, `Partido_Pendiente=true`, `Ultima_Jornada_Dia=Minute_Day`, guarda, envía mensaje y emite `estado_cambiado`.
* `Renunciar_Al_Club()`: desactiva, conserva desbloqueo, resta 2 de reputación, guarda historial y genera ofertas. No borra la partida.

---

##### 4.4. Plantilla, Alineación y Táctica

**Generación de 18 jugadores:** 2 POR, 6 DEF, 6 MED, 4 DEL. Semilla = `hash(club_id) + temporada*1000`.

* `media_objetivo` = fuerza base de la división ±8; un jugador es «estrella» (+6..10) y otro «promesa» (−6, potencial +10..15).
* Edad: 18–34, con más probabilidad entre 21 y 29.
* Stats base según posición (luego `rng.randi_range(-4, 4)` y clamp 20–99):
  * POR: `porteria = media+12`, `defensa = media-5`, `pase = media-15`, `tiro = media-25`, `ritmo = media-10`, `fisico = media+2`.
  * DEF: `defensa = media+10`, `fisico = media+8`, `pase = media-5`, `tiro = media-15`, `ritmo = media`, `porteria = 20`.
  * MED: `pase = media+9`, `defensa = media-2`, `fisico = media+2`, `tiro = media-2`, `ritmo = media+4`, `porteria = 20`.
  * DEL: `tiro = media+10`, `ritmo = media+6`, `pase = media-4`, `fisico = media+2`, `defensa = media-20`, `porteria = 20`.
* `media` final = media ponderada por posición (ver abajo), no el objetivo. `potencial = clamp(media + rng.randi_range(2, 15) - maxi(0, edad-24)*1.5, media, 95)`. Al mejorar stats con entrenamiento, recalcular `media`; `valor` y `salario` se recalculan al renovar contrato o al terminar la temporada.
* `valor = roundi(media*media * factor)` con factor Div 4 = 1, Div 3 = 3, Div 2 = 8, Div 1 = 20; multiplicar por edad: `<21 ×1.3`, `21–27 ×1.1`, `28–31 ×0.9`, `32+ ×0.6`; redondear a 100.
* `salario = roundi(media * factor_salario)` con factor 4 / 12 / 40 / 120 según división; mínimo 80 €. Ajustar ±10 % por reputación.
* `contrato` 1–3 años; `moral` 55–85; `estado_fisico` 80–100; `forma` 50–80; `lesion_dias=0`; stats de temporada a 0.
* Nombres únicos dentro de la plantilla, sin nombres reales de futbolistas. Ids `p01..p18`; al fichar, siguiente libre; al vender, no reutilizar el id en la misma temporada.

**Media por posición:**
```text
POR: 0.70*porteria + 0.15*defensa + 0.15*fisico
DEF: 0.55*defensa + 0.25*fisico + 0.10*pase + 0.10*ritmo
MED: 0.40*pase + 0.20*defensa + 0.20*fisico + 0.10*tiro + 0.10*ritmo
DEL: 0.50*tiro + 0.20*pase + 0.15*ritmo + 0.15*fisico
```

**Alineación y química:**
* Formaciones disponibles con 11 slots y coordenadas normalizadas para el campo vertical: `4-4-2`, `4-3-3`, `3-5-2`, `5-3-2`, `4-2-3-1`.
* `Autoalinear()` elige por slot el mejor jugador disponible de la posición exacta; si no hay, adyacente; si tampoco, cualquiera. Nunca duplica ids. Si hay menos de 11 sanos, permite lesionados con penalización del 35 % antes que dejar el once incompleto.
* `media_efectiva = media * (0.85 + 0.15*estado_fisico/100) * (0.90 + 0.10*moral/100)`.
* Química: jugador en posición exacta = 0; adyacente (DEF↔MED, MED↔DEL) = −4 %; no relacionado = −8 %; POR fuera de portería = −15 %. `factor_quimica = clamp(1.0 - suma_penalizaciones, 0.75, 1.0)`. Se aplica a las fuerzas del equipo.

**Fuerzas del once (0–99):**
```text
ataque   = 0.60*media_tiro_DEL + 0.30*media_tiro_MED + 0.10*media_tiro_DEF
creacion = 0.60*media_pase_MED + 0.20*media_pase_DEL + 0.20*media_pase_DEF
defensa  = 0.60*media_defensa_DEF + 0.30*media_defensa_MED + 0.10*media_porteria_POR
porteria = media_porteria_POR
global   = 0.35*ataque + 0.25*creacion + 0.25*defensa + 0.15*porteria
```
Aplicar después `factor_quimica` y la forma media (`0.95 + 0.10*forma_media/100`). La moral ya está incorporada en `media_efectiva`; no la cuentes dos veces. Clamp 20–99.

**Tácticas (modificadores planos):**

| Clave | Valor | Efecto |
|---|---|---|
| `mentalidad` | `ofensiva` | +6 ataque, −5 defensa |
| | `defensiva` | −6 ataque, +5 defensa |
| | `equilibrada` | 0 |
| `presion` | `alta` | +4 creacion, −3 defensa, +4 fatiga |
| | `baja` | −3 creacion, +4 defensa, −2 fatiga |
| | `media` | 0 |
| `pase` | `corto` | +3 creacion |
| | `largo` | +3 ataque, −2 creacion |
| | `mixto` | 0 |
| `ritmo` | `alto` | +3 ataque, −3 defensa |
| | `bajo` | −2 ataque, +3 defensa |
| | `normal` | 0 |

**Triángulo táctico** (se aplica después de los modificadores, solo al equipo que lleva la ventaja):
* Presión `alta` contra pase `corto`: +4 al que presiona.
* Pase `largo` contra presión `alta`: +4 al que juega largo.
* Pase `corto` contra presión `baja`: +3 al que juega corto.

La UI de táctica debe mostrar una vista previa: «Ataque 72 · Creación 68 · Defensa 70 · Portería 65 · Química 96 %» y un aviso de ventaja/desventaja táctica antes de jugar.

---

##### 4.5. Bucle de Jornada: Acciones, Mercado y Contratos

**3 acciones por jornada** (`acciones_jornada`), se reinician al comenzar cada jornada. En Modo Normal una jornada = un día real, así que el reset es diario; en Modo Rápido cada partido inicia una nueva jornada y el reset ocurre al terminar el partido, aunque el reloj no cambie de día. Al aceptar un club se fijan `acciones_jornada=3`, `ultima_jornada_acciones=0`, `fichajes_jornada=0` y `ultima_jornada_mercado=0`. El reset se aplica cuando `jornada_actual != ultima_jornada_acciones` (o `..._mercado`), nunca por mero paso del tiempo. Cada acción guarda y emite `estado_cambiado`:

1. **Entrenar** (`ataque`, `defensa`, `fisico`): mejora a 3 jugadores disponibles +1..3 en los stats de la línea (ataque: DEL/MED; defensa: DEF/MED/POR; físico: cualquiera), −5 estado físico, +2 moral. Coste 1 acción.
2. **Recuperar** (`id_jugador`): +15..25 estado físico, −1 día de lesión, +5 moral. Coste 1 acción.
3. **Ojear**: regenera los 4 objetivos del mercado y revela una promesa con potencial +5..10. Coste 1 acción.
4. **Marketing**: +2 % afición y un ingreso extra de patrocinio (Div 4: 500 €; Div 3: 2.000 €; Div 2: 8.000 €; Div 1: 25.000 €), una vez por jornada. Coste 1 acción.

No se puede entrenar a lesionados ni a jugadores con `estado_fisico < 20`; no se puede recuperar a un jugador con `estado_fisico >= 100` y `lesion_dias == 0` (mensaje claro). Si quedan 0 acciones, los botones se deshabilitan con el texto «Sin acciones · vuelve a la próxima jornada».

**Mercado:**
* 4 jugadores objetivo, generados con fuerza alrededor de la división ±5, edad 18–32, precio = valor × `rng.randf_range(0.85, 1.15)`, salario según fórmula y contrato 1–3.
* Se regenera al comenzar cada jornada o con **Ojear**. `fichajes_jornada` máximo 2 por jornada.
* Comprar: requiere presupuesto >= precio, plantilla < 22 y `fichajes_jornada < 2`. Suma el jugador, descuenta presupuesto, autoalinea si falta el once, guarda y emite mensaje.
* Vender: paga el 75 % del valor, requiere plantilla > 14 y que queden al menos 11 jugadores disponibles; si el vendido estaba en el once, autoalinear. No se puede vender al último portero.
* Renovar contrato: cuesta `salario_semanal * 4 * anios` (1–3 años), sube el salario un 10 % y reinicia el contrato. Si un contrato llega a 0 al final de temporada, el jugador se marcha gratis y se sustituye por un canterano de 18–20 años y media 45–60.
* Sin cláusulas, agentes, primas de fichaje ni subastas en el MVP.

**Progresión y edad (fin de temporada):**
* Edad +1. Si `edad < 23`: +1..3 media hacia el potencial. 24–29: +0..1. 30–33: −1. 34+: −1..3.
* Retiro: 50 % a los 36, 75 % a los 37, 100 % a los 38. Sustituir por canterano para mantener 18 jugadores.
* Reset de stats de temporada, moral 55–85, estado físico 85–100, lesiones a 0.

---

##### 4.6. Liga, Partidos y Minijuego «Banquillo en 90 segundos»

**Calendario:**
* 8 clubes (el del jugador + 7 ficticios de la misma división), una vuelta, 7 jornadas, 28 partidos. Método círculo con seed; cada club juega 7 partidos, 3 o 4 en casa. Los ids de los 8 clubes deben ser únicos; el club del jugador conserva el id de la oferta aceptada.
* Fuerza de los rivales: `fuerza_plantilla` del club ±8, clamp 40–92; sin plantillas completas (solo fuerza y nombres ficticios).
* `jornada_actual` empieza en 0. El siguiente partido del jugador se obtiene del calendario en `jornada_actual + 1`.
* Modo Normal: al comenzar el día se marca `Partido_Pendiente=true` si hay partido; el jugador puede jugarlo en cualquier momento del día. A las 23:59, si sigue pendiente, se auto-simula y se resuelve la jornada. `Ultima_Jornada_Dia` impide jugar dos jornadas el mismo día.
* Modo Rápido: el panel muestra **Jugar jornada**; cada pulsación inicia el siguiente partido sin esperar al reloj. Se pueden encadenar las 7 jornadas en una sesión. El reloj de la vida sigue corriendo; el modo mánager no lo pausa.

**Tick de minuto y cambio de día:**
* `Sistema_Manager.Tick_Minuto()` sale de inmediato si no hay club activo.
* Al detectar `Minute_Day != Dia_Ultimo_Tick`: actualizar `Dia_Ultimo_Tick`, aplicar recuperación diaria (+5 estado físico a toda la plantilla, −1 día de lesión, +2 moral), regenerar ofertas si no hay club y, en Modo Normal, auto-simular un partido pendiente del día anterior antes de seguir, marcar `Partido_Pendiente` si toca partido y guardar una sola vez. El cambio de día **no** regala acciones, mercado ni fichajes: eso se reinicia al iniciar cada jornada (aceptar club, terminar partido o auto-simulación). Emitir `estado_cambiado` si cambió algo visible.
* En Modo Rápido el cambio de día no auto-simula ni reinicia acciones: eso ocurre al cerrar cada partido. El cambio de día solo aplica recuperación y ofertas.
* A las 23:59 en Modo Normal, si `Partido_Pendiente` sigue activo, llamar a `Simular_Partido_Actual()` y resolver la jornada sin esperar al cambio de día. Si la app se cierra antes, el cambio de día del siguiente arranque debe detectar el partido vencido y auto-simularlo.

**Flujo de jornada:**
1. `Iniciar_Partido(true)` prepara el contexto (rival, local/visitante, fuerzas, once, banquillo, táctica, semilla) y abre `Panel_Manager_Partido`.
2. El jugador toma 5 decisiones. Cada una actualiza marcador, minuto, moral, fatiga y lesiones. `Resolver_Decision_Partido(opcion_id)` devuelve `{ok, texto, marcador, minuto, siguiente, fin}`; la UI solo pinta el texto, actualiza el marcador y avanza a la siguiente decisión.
3. Al terminar, `Finalizar_Partido(resultado)` guarda el resultado del jugador en `Liga.resultados`, simula los otros 3 partidos con `Simular_Partido_Base()`, incrementa `jornada_actual`, actualiza tabla/economía/confianza, comprueba despido y fin de temporada, guarda y emite `partido_finalizado`/`temporada_finalizada`.
4. Si el jugador elige **Simular** (o cierra el panel), se usa `Simular_Partido_Base()` para su partido y se resuelve la jornada igual. No se puede repetir.

**Auto-simulación base (IA y partido simulado):**
```text
xg_local = clamp(1.35 + (fuerza_local - fuerza_visitante)/22.0 + 0.15, 0.20, 4.0)
xg_visitante = clamp(1.10 - (fuerza_local - fuerza_visitante)/24.0, 0.15, 3.5)
goles = Poisson(xg) con RNG determinista, cap 6
```
La ventaja de local ya está incluida en el +0.15. Los goleadores se eligen ponderando posición: DEL 55 %, MED 30 %, DEF 14 %, POR 1 %, y dentro de la línea por `tiro`. Para la IA, nombres ficticios del pool.

**Minijuego de 5 decisiones (15 s cada una, 90 s):**

| # | Minuto | Situación | Opciones | Estadísticas |
|---|---|---|---|---|
| 1 | 12' | Ataque | Pase filtrado / Centro al área / Disparo lejano | creación vs defensa; ataque vs defensa; ataque vs portería |
| 2 | 30' | Defensa | Presión alta / Repliegue / Falta táctica | defensa+creación vs ataque; defensa vs ataque; defensa vs ataque |
| 3 | 55' | Ataque | Doble cambio ofensivo / Mantener el plan / Balón parado | media del banquillo; ataque; defensa+ataque |
| 4 | 75' | Defensa | Cambio defensivo / Línea adelantada / Posesión | media del banquillo; defensa vs ataque; creación vs creación |
| 5 | 90' | Cierre | Empate: Aguantar / Asedio final / Balón parado. Gana: Proteger / Buscar el segundo. Pierde: Asedio total / Juego directo | defensa; ataque; defensa+ataque |

**Probabilidad de éxito:**
```text
p = clamp(base + (stat_equipo - stat_rival)/200.0 + bonus_tactico + bonus_moral, 0.15, 0.90)
base: conservador 0.62, equilibrado 0.55, arriesgado 0.45, balón parado 0.50
bonus_tactico: −0.05..+0.05 según triángulo/mentalidad
bonus_moral: (moral_media - 65)/500.0  # −0.05..+0.05
```
* Ataque con éxito = gol (elige goleador y suma stats). Ataque fallido = sin gol; las opciones arriesgadas tienen 25 % de contragolpe rival (gol rival).
* Defensa con éxito = despeje/parada, sin gol, +2 moral. Defensa fallida = gol rival.
* Cierre sin penaltis: en la liga el empate es un resultado válido. Si empate, «Aguantar» exitoso mantiene el empate y fallido concede; «Asedio final»/«Balón parado» exitoso marca y fallido no marca (25 % de contra en asedio). Si gana, «Proteger» exitoso mantiene y fallido concede; «Buscar el segundo» exitoso marca y fallido no. Si pierde, «Asedio total»/«Juego directo» exitoso marca y fallido no marca (15–25 % de contra).
* Cada decisión resta 3–8 de estado físico a 2–3 titulares; presión alta resta 4 extra. Al final del partido, los 11 titulares pierden 8–12 más y los suplentes que hayan entrado, 4–6. Lesión: 2 % por titular sano, 6 % si estado físico < 50; 1–3 jornadas de baja.
* Cada decisión declara `opcion_auto` (la equilibrada). Si el temporizador llega a 0, se elige esa opción y se muestra «Decisión automática». Si el jugador cierra el panel, confirmación y auto-simulación completa. Sin softlock.
* El resultado final del minijuego es el marcador del partido (no se suma a una simulación previa). La fuerza del once y la táctica influyen en las probabilidades; el azar decide. Cap de marcador 6 por equipo.

**Resumen del partido:** marcador, goleadores, MVP (mejor `media_efectiva` del once), lesiones, fatiga, cambio de confianza, taquilla/ingresos, posición en la tabla y próximo rival. Tras el resultado: victoria +5 moral, empate +1, derrota −5; goleador +3 y MVP +4 (clamp 20–100). Forma individual: victoria +3, empate 0, derrota −3; goleador +2 (clamp 20–100). Actualizar `Club.racha` con `"V"/"E"/"D"` (máximo 5). Botón **Continuar**.

**Tabla:** 3 puntos victoria, 1 empate, 0 derrota. Desempate: puntos, diferencia de goles, goles a favor, nombre. La tabla se calcula desde `resultados`; no se guarda duplicada.

---

##### 4.7. Economía del Club, Directiva y Fin de Temporada

**Presupuesto del club por jornada** (no se multiplica por `Multiplicador_Precios()`; es una economía interna del club):

| Concepto | Div 4 | Div 3 | Div 2 | Div 1 |
|---|---:|---:|---:|---:|
| Patrocinio | 700 | 2.200 | 8.000 | 28.000 |
| Derechos TV | 300 | 1.200 | 5.000 | 18.000 |
| Entrada (solo casa) | 6 € × 1.200 | 10 € × 3.500 | 15 € × 9.000 | 25 € × 20.000 |
| Prima victoria | 1.500 | 6.000 | 20.000 | 60.000 |
| Prima empate | 500 | 2.000 | 7.000 | 20.000 |
| Gastos operativos | 300 | 1.000 | 4.000 | 12.000 |
| Nómina semanal | variable | variable | variable | variable |
| Premio por objetivo (fin de temporada, ingreso al club) | 5.000 | 20.000 | 80.000 | 250.000 |

**Cuenta personal del mánager** (la paga la directiva aparte; no sale del presupuesto del club):

| Concepto | Div 4 | Div 3 | Div 2 | Div 1 |
|---|---:|---:|---:|---:|
| Salario por jornada | 50 | 150 | 500 | 1.500 |
| Prima victoria | 20 | 75 | 250 | 750 |
| Prima empate | 5 | 20 | 70 | 200 |
| Prima título | 200 | 800 | 3.000 | 10.000 |
| Prima ascenso | 100 | 400 | 1.500 | 0 |

* La taquilla se multiplica por `1.0 + 0.15*(estadio_nivel-1)` y solo se cobra en casa.
* Salarios semanales del club = suma de `salario` de toda la plantilla; se descuentan completos en cada jornada (una jornada = una semana de nómina). El presupuesto puede quedar negativo, pero no se pueden hacer fichajes con saldo negativo.
* El salario y las primas del mánager se ingresan en `Variables_Dinamicas.Dinero` tras cada jornada, multiplicados por `Multiplicador_Precios()` en Modo Rápido. La directiva los paga aparte: no reducen el presupuesto del club y el Sim no puede retirar dinero del club.
* El **premio por objetivo** se ingresa en el presupuesto del club solo si se cumple el objetivo de temporada; es una inyección de la directiva, no dinero personal.
* Al aceptar un club, el presupuesto inicial debe cubrir al menos 4 nóminas semanales; si no, reducir los salarios generados hasta que se cumpla.

**Confianza de la directiva (0–100):**
* Inicial: `clamp(50 + reputacion*0.2, 40, 75)`.
* Victoria: +5. Empate: 0. Derrota: `-(4 + roundi((100 - paciencia)/25.0))`. Victoria por 3+ goles: +2 extra. Derrota por 3+ goles: −3 extra.
* Presupuesto negativo tras la jornada: −3; por debajo del −25 % del presupuesto inicial: −8 adicional.
* Aviso a ≤30: mensaje y badge «Directiva preocupada»; `Aviso_Despido=true` al bajar de 30 y se vuelve a false al superar 35.
* Llevar `dias_confianza_baja`: se incrementa al terminar una jornada con confianza ≤25 y se resetea al superar 25. Despido si confianza ≤10 tras una jornada, o si `dias_confianza_baja >= 2`. Al final de temporada: despido si el objetivo no se cumple y confianza <40, o si confianza <20.
* Al ser despedido: `Activo=false`, `Club={}`, `Liga={}`, `Partido_Pendiente=false`, reputación −5, entrada parcial en `Historial` (club, temporada, jornada y motivo), 3 ofertas nuevas, mensaje y señal `club_destituido`. No se borra el desbloqueo.

**Fin de temporada (tras la jornada 7):**
1. Calcular tabla final y posición.
2. Si se cumple el objetivo, ingresar el premio por objetivo en el presupuesto del club. Ascenso si queda 1.º en Div 4/3/2; descenso si queda 8.º en Div 3/2/1 (en Div 4 no hay descenso). El campeón de Div 1 gana la Superliga. Al ascender: +15 % afición y +20 % presupuesto; al descender: −10 % en ambos.
3. Revisión de directiva: objetivo cumplido +15 confianza; no cumplido −20; campeón +10; ascenso +10; descenso −20. Aplicar despido si corresponde.
4. Pagar al Sim las primas personales de título/ascenso desde la cuenta de la directiva y actualizar reputación (+8 título, +5 ascenso, −5 descenso, +2 victoria, −1 derrota, clamp 0–100).
5. Envejecer plantilla, contratos, progresión, retiros y canteranos; recalcular `valor` y `salario` con la división de la nueva temporada y ajustar la fuerza de los 7 clubes IA ±3 (clamp 40–92).
6. Nueva temporada: `temporada++`, `jornada_actual=0`, nuevo calendario, mercado, acciones, moral/físico, stats de temporada a 0, ofertas vacías y objetivo recalculado según división/reputación.
7. Añadir la entrada de temporada a `Club.historial_temporadas` y a `Manager_Estado.Historial` (posición, puntos, título, ascenso/descenso, confianza, presupuesto). Marcar `temporada_cerrada=true`, guardar, enviar mensaje y emitir `temporada_finalizada` con resumen. Mostrar modal de resumen y, si sigue activo, botón **Nueva temporada**; al iniciarla, `temporada_cerrada=false`.

**Anti-exploit:** sin retiradas libres de dinero del club, sin fijarse el salario, sin repetir partidos, sin vender fichajes al mismo precio (compra 0.85–1.15, venta 0.75), sin entrenamientos infinitos (3 acciones/jornada), sin recompensas por simular partidos una y otra vez (una jornada por día en Normal).

---

##### 4.8. UI: Tarjeta de Minijuegos, Panel y Partido

**A. Tarjeta en `_Actualizar_Pantalla_Minijuegos()`**
* Implementar `_Anadir_Tarjeta_Manager()` y llamarlo desde `_Actualizar_Pantalla_Minijuegos()` después de Cocina/Correr y antes de `PRÓXIMOS MINIJUEGOS`, con `PanelContainer` y el mismo lenguaje visual de las tarjetas existentes.
* Banner de 142 px con fondo degradado índigo/oro, escudo procedural y silueta de banquillo dibujada por código.
* Título **«El Mánager»**, subtítulo «Modo club · 7 jornadas · 720×1280» (la referencia a *Top Eleven* es solo interna de diseño; no mostrarla en la UI publicada).
* Estados:
  * **Bloqueado:** candado + texto «Retírate como futbolista o sácate el título de entrenador». Mostrar el coste real que devuelve `Puede_Comprar_Titulo().coste` (1.500 € × multiplicador). Botón **Sacar título** si `Puede_Comprar_Titulo().ok`; si hay carrera activa, botón deshabilitado con «Retírate desde Carrera futbolística».
  * **Desbloqueado sin club:** «Tienes 3 ofertas de club» + botón **Ver ofertas**.
  * **Activo:** escudo, nombre del club, división, posición actual, próximo rival, presupuesto, barra de confianza y botón **Entrar al vestuario**. Si hay partido pendiente, pill «Partido pendiente» y borde de color.
* `Hay_Novedad()` = ofertas disponibles, partido pendiente, temporada terminada o despido. En `_Actualizar_Badges()`, el badge de `Minijuegos_Button` debe mostrarse con `_minijuegos_novedad_pendiente or Sistema_Manager.Hay_Novedad()`; al abrir la pantalla de Minijuegos, limpiar solo la novedad de cocina, no la del mánager si sigue habiendo partido/ofertas.
* Quitar «Fútbol · Modo Partido» de la lista de próximos minijuegos (ya está cubierto por El Mánager) y dejar «Trading en Directo» y «Partido en 90 segundos» como futuros.

**B. `Panel_Manager.tscn` / `Panel_Manager.gd`**
* `Control` a pantalla completa dentro de un `CanvasLayer` (`Capa_Panel_Manager`, layer 61), instanciado desde `Script_Principal` al pulsar la tarjeta. Mismo patrón que `Panel_Futbol`.
* Cabecera fija de 86 px: volver, escudo, nombre del club, división, presupuesto, confianza y botón de cerrar.
* Pestañas en una fila desplazable de 6 botones tipo pill: **Inicio · Plantilla · Táctica · Mercado · Liga · Club**. Contenido en `ScrollContainer` vertical, sin scroll horizontal.
* **Inicio:** próximo partido (rival, casa/fuera, fuerza en estrellas 1–5, ventaja táctica), botones **Jugar** / **Simular**, acciones por jornada (3), confianza, presupuesto, último resultado y noticias.
* **Plantilla:** 18 filas con posición, nombre, edad, media, estado físico, moral, contrato, valor y salario; detalle al pulsar; botones **Autoalinear**, **Vender**, **Renovar**.
* **Táctica:** campo vertical dibujado con `_draw` (franjas verdes, líneas blancas), 11 slots; selector de formación; al pulsar un slot, lista de jugadores elegibles con ajuste de posición; 4 selectores de táctica; vista previa de fuerzas y química; botón **Guardar táctica**.
* **Mercado:** 4 tarjetas de objetivos con posición, edad, media, potencial, precio y salario; botón **Fichar**; sección **Vender**; contador de fichajes 0/2; botón **Ojear** (si quedan acciones).
* **Liga:** tabla de 8 clubes, calendario de 7 jornadas con resultados, racha y goleadores del club.
* **Club:** finanzas (ingresos/gastos de la última jornada, presupuesto, nómina semanal), afición, estadio, confianza, reputación, objetivo, salario del mánager, historial de temporadas y botón **Renunciar** con confirmación.
* **Ofertas:** si no hay club, el panel abre directamente una subvista con 3 tarjetas de club (escudo, división, presupuesto, fuerza, objetivo, paciencia) y botón **Firmar**. Botón **Buscar club** si no hay ofertas.
* Refrescar tras cada acción; no reconstruir todo el árbol si no es necesario, pero priorizar claridad sobre microoptimización.

**C. `Panel_Manager_Partido.tscn` / `Panel_Manager_Partido.gd`**
* Se instancia en un `CanvasLayer` propio (`Capa_Partido_Manager`, layer 62) o como hijo directo de `Capa_Panel_Manager`; **nunca** dentro del `ScrollContainer` del panel, para que cubra la pantalla completa sin recortes.
* Pantalla completa vertical, fondo de estadio dibujado por código (degradado, gradas, líneas), marcador arriba, minuto y anillo de tiempo.
* Tarjeta central con la situación y 2–3 botones grandes (≥52 px), texto de consecuencia y marcador.
* Barra inferior con **Auto** y **Salir**; **Salir** pide confirmación y auto-simula.
* Timer de 15 s por decisión, visible con número; se pausa 1,2 s durante la animación de resultado. Usa `Timer` o `Time.get_ticks_msec()`, nunca un `await` sin control.
* Al final, modal de resultado con botón **Continuar**; si es fin de temporada, resumen y **Nueva temporada**.

**D. Integración en `Script_Principal.gd`:**
* `_Abrir_Panel_Manager()` / `_Cerrar_Panel_Manager()` / `_Refrescar_Panel_Manager_Si_Abierto()`, con `CanvasLayer` layer 61. `_Cerrar_Panel_Manager()` debe cerrar también `Capa_Partido_Manager` si existe; si hay un partido abierto, pedir confirmación y auto-simularlo antes de destruir la capa.
* Conectar `Sistema_Manager.estado_cambiado` a `_Actualizar_Pantalla_Minijuegos_Si_Visible()` y `_Actualizar_Badges()`; `manager_desbloqueado` a `_Mostrar_Toast_Desbloqueo()` con «¡Nuevo minijuego desbloqueado: El Mánager!» y un `Mensaje`; `club_destituido` a un modal; `temporada_finalizada` a un modal/toast.
* Al cerrar el panel, volver a la pantalla de Minijuegos (no a la home) y refrescar la tarjeta. Si se abrió desde otro sitio, volver a `Quitar_Todo()` como el resto de paneles.
* No añadir un botón nuevo a la barra superior: la entrada es la tarjeta de Minijuegos.

---

##### 4.9. Integración con el Resto del Juego

* `project.godot`: autoload `Sistema_Manager` después de `Sistema_Futbol`.
* `Variables_Dinamicas.gd`: `Manager_Estado` + helper.
* `Guardar_Variables_Dinamicas.gd`: guardar/cargar/normalizar.
* `Menu.gd`: reset de nueva partida.
* `Actividades.gd`: añadir `Sistema_Manager.Tick_Minuto()` justo después de `Sistema_Futbol.Tick_Minuto()`. El tick debe ser O(1) y no hacer nada si no está activo.
* `Sistema_Futbol.gd`: retiro, legado y claves nuevas en `Carrera_Futbol`.
* `Panel_Futbol_GUI.gd`: tarjeta/acción de retiro.
* `Script_Principal.gd`: tarjeta, panel, badge, toasts y mensajes. En **Perfil → Info**, añadir una fila `Mánager` con el club/división/reputación si está activo, o «Bloqueado»/«Sin club» si no.
* `Estilos_UI.gd`: no modificar salvo que falte un helper; reutilizar los existentes.
* `CLAUDE.md`, `Prompts/MEGA_PROMPT_CONTEXTO.md`, `ROADMAP.md` y `Funcionalidades/Actividades/Futbol/Documentacion/CARRERA_FUTBOL.md`: actualizar el estado de la Fase 2.
* No tocar `Matriz_Jugador`, prioridades P1/P2/P3, trabajos, estudios, bolsa, cocina ni necesidades básicas. El mánager no consume necesidades del Sim (es una capa de gestión), pero el reloj sigue corriendo.

---

#### 5. Tests GUT Obligatorios (`Funcionalidades/Manager/Tests/test_manager.gd`)

Cubrir como mínimo:

1. Estado por defecto, reset en nueva partida y save sin `Manager_Estado`.
2. Normalización de saves incompletos/corruptos: no crashea, conserva desbloqueo, desactiva club inválido.
3. Cálculo de legado y reputación con carreras de distinta división, títulos, goles y temporadas.
4. Desbloqueo por retiro: limpia bloques, mantiene estadísticas, marca `Retirado`, genera ofertas y mensaje.
5. Título de entrenador: coste con y sin `Modo_Rapido`, descuenta `Dinero`, no permite duplicar, bloquea con carrera activa.
6. Ofertas: 3 clubes distintos, división según reputación, presupuesto/fuerza/paciencia en rangos, determinismo con seed.
7. Aceptar oferta: 18 jugadores, 11 titulares únicos, 8 equipos, 7 jornadas, cada club juega 7 partidos y cada pareja una vez.
8. Generación de plantilla: posiciones 2/6/6/4, stats 20–99, ids únicos, media/potencial/valor/salario coherentes, reproducibilidad.
9. Autoalineación con formaciones 4-4-2, 4-3-3, 3-5-2, 5-3-2 y 4-2-3-1; sin duplicados; suplencia por lesión.
10. Fuerzas del once: mejor plantilla > peor; química reduce; táctica ofensiva sube ataque y baja defensa.
11. Triángulo táctico: presión alta vs pase corto, pase largo vs presión alta, pase corto vs presión baja.
12. Probabilidades de decisión clampeadas 0,15–0,90; opciones conservadoras más seguras que las arriesgadas.
13. Resolución de las 5 decisiones con seeds forzadas: gol de ataque, defensa exitosa, defensa fallida, cierre en empate/ganando/perdiendo, auto-decisión.
14. Auto-simulación: marcadores 0–6, determinista por seed, goleadores válidos.
15. Tabla: 3/1/0, desempates por diferencia y goles, 28 resultados.
16. Resolución de jornada: resultado del jugador + 3 partidos IA, `jornada_actual` +1, sin duplicar jornadas.
17. Economía: patrocinio/TV/taquilla solo casa, primas, nómina semanal, gastos operativos, presupuesto negativo bloquea fichajes.
18. Salario personal del mánager y primas van a `Dinero`, no al club; multiplicador en Modo Rápido.
19. Confianza: victoria/derrota, aviso ≤30, despido ≤10, despido tras 2 jornadas ≤25, revisión de objetivo.
20. Despido: desactiva club, conserva desbloqueo, reputación −5, nuevas ofertas, no softlock.
21. Fin de temporada: campeón, ascenso, descenso, premio de objetivo al club (no a `Dinero`), primas personales, envejecimiento, contratos, retiros, canteranos y `temporada_cerrada` sin duplicar pagos.
22. Mercado: compra/vende, límites 22/14, 2 fichajes/día, venta al 75 %, renovación y contrato a 0.
23. Acciones por jornada: 3 usos, reset al comenzar cada jornada, entrenar/recuperar/ojear/marketing, efectos correctos.
24. `Tick_Minuto`: no hace nada sin club; cambio de día sin regalar acciones; reset de acciones/mercado al iniciar jornada; partido pendiente en Normal; auto-simulación a las 23:59 y recuperación de partido vencido al cargar; Modo Rápido no auto-simula.
25. Persistencia: roundtrip completo de club, liga, calendario, resultados, plantilla, alineación y ofertas.
26. Integración: `Sistema_Futbol.Retirarse_Como_Jugador()` desbloquea el mánager y no deja bloques de fútbol.
27. UI: instanciar `Panel_Manager.tscn` y `Panel_Manager_Partido.tscn`, comprobar 720×1280, pestañas, botones y que no faltan nodos.
28. Tarjeta de Minijuegos: aparece, estados bloqueado/ofertas/activo, badge de novedad.
29. No regresión: la suite GUT existente sigue pasando.

Comandos:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=res://Funcionalidades/Manager/Tests/test_manager.gd -gexit
```
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades -ginclude_subdirs -gexit
```

---

#### 6. Documentación y Entrega

* Crear `Funcionalidades/Manager/Documentacion/MANAGER.md` con: arquitectura, esquema de estado, fórmulas, tabla de decisiones, economía, flujo de temporada, UI, tests y comandos.
* Actualizar `CLAUDE.md`: autoload `Sistema_Manager`, archivos nuevos, estado «Fase 2 MVP implementada», notas de guardado y retiro.
* Actualizar `Prompts/MEGA_PROMPT_CONTEXTO.md` y `ROADMAP.md`: marcar la Fase 2 como implementada en su MVP y enumerar las ampliaciones futuras (11v11, ojeadores, academia, estadio, competiciones, fichajes entre IA).
* Actualizar `Funcionalidades/Actividades/Futbol/Documentacion/CARRERA_FUTBOL.md` con el retiro y el legado.
* Entregar un informe con: archivos creados/modificados, decisiones de implementación, resultados de GUT (nuevos y suite completa), comprobación de layouts 720×1280 y riesgos/pendientes.

---

#### 7. Criterios de Aceptación

* Se puede desbloquear El Mánager retirándose como futbolista o comprando el título, y el estado se conserva al guardar/cargar.
* Se pueden ver 3 ofertas, firmar por un club y jugar una temporada completa de 7 jornadas sin errores.
* La plantilla, alineación, formaciones, táctica, mercado y acciones por jornada funcionan y se reflejan en las fuerzas del equipo.
* El partido se puede jugar en 60–90 s con 5 decisiones claras; **Simular** y el auto-tiempo siempre están disponibles; no hay softlocks.
* La economía del club y la del Sim están separadas; no hay dinero infinito ni fichajes con presupuesto negativo.
* La confianza de la directiva, el despido y el fin de temporada funcionan y generan un camino de continuación.
* Saves antiguos cargan sin errores; la carrera de futbolista y la cocina no se rompen.
* UI vertical 720×1280 sin cortes, botones ≥44 px y textos legibles.
* Todos los tests nuevos pasan y la suite GUT completa sigue verde.
* Documentación actualizada y sin nombres/escudos reales.

---

#### 8. Orden de Implementación Recomendado

1. `Simulador_Manager.gd` + `Datos_Manager.gd` + tests puros (generación, fuerzas, táctica, tabla, economía, legado).
2. `Manager_Estado` + normalización + guardado/carga + `Sistema_Manager` básico + desbloqueo/ofertas.
3. Tarjeta en Minijuegos + `Panel_Manager` (ofertas, inicio, plantilla, táctica).
4. Mercado, acciones por jornada, contratos y progresión.
5. `Panel_Manager_Partido` + resolución de jornada + fin de temporada + confianza/despido.
6. Integración con retiro de `Sistema_Futbol`, tick en `Actividades.gd`, toasts/badges y documentación.
7. QA final: GUT completo, partida nueva, save/load, modo normal/rápido y layouts.

FIN DEL PROMPT
