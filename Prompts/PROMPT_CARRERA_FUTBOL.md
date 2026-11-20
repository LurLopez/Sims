# Prompt de Implementación — Carrera de Futbolista (Fase 1: Modo Jugador)

> **Cómo usarlo:** Copia todo el bloque a partir de `PROMPT (pegar desde aquí)` y pégalo en el agente implementador. Esta especificación está verificada contra el código real de `/home/lur/sims-0.33` (Godot 4.4 / GDScript 2.0) y deja la Fase 2 (*Top Eleven* / Mánager) explícitamente fuera de alcance para más adelante.

---

PROMPT (pegar desde aquí)

### Tarea: Implementar la Carrera de Futbolista (Fase 1 — Modo Jugador) en SIMS 0.33

Actúa como desarrollador senior de Godot 4.4 / GDScript 2.0 en el proyecto `/home/lur/sims-0.33` (juego de simulación de vida en español, resolución vertical `720×1280` portrait para Android). Implementa de principio a fin la **Carrera de Futbolista** respetando la arquitectura de `Matriz_Jugador` (1440×574), la jerarquía de prioridades P1/P2/P3, los arrays reales de `Progreso` y `Habilidades`, la adaptación completa a Modo Normal y Modo Rápido, la persistencia retrocompatible, la UI en Actividades Fijas y la suite de tests unitarios GUT.

No pidas confirmación interactiva: lee los archivos reales del proyecto antes de editar, escribe el código, registra las actividades, conecta las señales, ejecuta los tests GUT (`addons/gut`) y entrega un informe técnico al finalizar.

---

#### 1. Contexto Obligatorio del Proyecto (Léelo antes de editar)
* `CLAUDE.md`: Reglas Godot 4.4, autoloads, jerarquía de prioridades, build y convenciones.
* `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd`: `_Inicializar_Catalogo()`, `Catalogo_Actividades`, `Estados_Temporales`, `Modo_Rapido`, `Multiplicador_Precios()`, `Dias_Por_Anio()`, `Calcular_Edad()`, `Habilidades` (Array de 7 valores).
* `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd`: `Necesidades_Basicas`, `Progreso` (Array `[Deporte, Académico, Manualidades]`), `Matriz_Jugador`, `Mensajes` (Array de objetos `Mensaje`), `Dinero`, `Trabajo_Actual`, `Minute_Day`, `Minute_Minute`, `Minute`.
* `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd`: `save_game()` y `load_game()` (revisa los nombres exactos de métodos en el archivo).
* `Scripts/Globales/Menu.gd`: Reseteo de variables dinámicas al iniciar una nueva partida.
* `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd`: `Actualizar_Horario()` y gestión de bloques en `Matriz_Jugador`.
* `Scripts/Logica/Escena_Principal/Actividades/Herencia/Actividad.gd`, `Actividad_Fija.gd`, `Actividad_Temporal.gd`, `Actividad_Fija_Trabajo.gd`.
* `Scripts/Logica/Escena_Principal/Actividades/Sistema_Carreras_Deportivas.gd`: Patrón de referencia para `Mensaje.new()` y actualización de `Mensajes`.
* `Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd` y `Scripts/Globales/Script_Principal.gd`.
* `Escenas/Escena_Principal/Escena principal.tscn` y `Scripts/GUI/Escena_Principal/Estilos_UI.gd`.
* `Funcionalidades/Actividades/Jerarquia/Tests/test_jerarquia.gd`: Patrón de referencia para tests GUT.

---

#### 2. Reglas Duras e Inviolables
1. **Godot 4.4 / GDScript 2.0**: Tipado estático obligatorio (`var x: int = 0`, `func f(p: float) -> bool:`). Prohibida sintaxis de Godot 3.
2. **Tipos reales del motor (NO inventar diccionarios)**:
   * `Variables_Dinamicas.Progreso[0]` es `Deporte` (Array `[dep, aca, man]`).
   * `Variables_Estaticas.Habilidades` es un **Array de 7 valores**: `[0]`=Deporte, `[4]`=Liderazgo, `[6]`=Sangre fría.
   * `Variables_Dinamicas.Mensajes` contiene instancias de `Mensaje.new()` (`titulo`, `descripcion`, `leido`, `minuto`).
   * La edad del jugador se obtiene con `Variables_Estaticas.Calcular_Edad()`.
3. **Claves ASCII Estables**: Identificadores sin tildes ni eñes para serialización y claves internas: `Carrera_Futbol`, `Entrenamiento_Futbol`, `Partido_Futbol`, `Lesion_Deportiva`.
4. **Jerarquía de Prioridades en Matriz**:
   * `Entrenamiento_Futbol`: Instancia de `Actividad_Fija` (**Prioridad P2**). No puede pisar actividades P3.
   * `Partido_Futbol`: Instancia de una nueva subclase `Actividad_Partido` (en `Scripts/Logica/Escena_Principal/Actividades/Herencia/Actividad_Partido.gd`, hereda de `Actividad` y sobreescribe `Obtener_Prioridad() -> int: return 3`). **Nota:** `Actividad_Temporal` tiene prioridad 1, por lo que NO debe usarse para `Partido_Futbol` si queremos protección P3.
5. **Compatibilidad hacia atrás**: Si un save previo en `Guardar_Variables_Dinamicas.dat` no contiene `Carrera_Futbol`, inicializarlo con los valores por defecto sin errores ni `null`.
6. **Rendimiento O(1) por minuto**: `Actualizar_Horario()` procesa únicamente el minuto actual.
7. **Resolución `720×1280` Portrait**: Modales responsivos con `MarginContainer`, `VBoxContainer`, `ScrollContainer` y `_Alto_Pantalla()` / `get_viewport().size_changed`.
8. **Funciones puras para matemáticas**: Toda la lógica de cálculo de condición, convocatoria, liga, playoff, penaltis y primas vive en funciones estáticas puras en `Simulador_Futbol.gd` para poder testearla en GUT sin instanciar la escena principal.
9. **Alcance**: Implementar únicamente la **Fase 1 (Modo Jugador)**. No implementar el Modo Mánager (*Top Eleven*) ni minijuegos 2D/3D de partidos.

---

#### 3. Datos y Persistencia

##### 3.1. Estado en `Variables_Dinamicas.gd`
Añadir:
```gdscript
var Carrera_Futbol: Dictionary = {
	"Activo": false,
	"Division": 4, # 4: 3ª División Regional, 3: 2ª División, 2: 1ª División, 1: Superliga
	"Relacion_Entrenador": 50.0, # [0.0, 100.0]
	"Entrenamientos_Cancelados_Seguidos": 0,
	"Partidos_Jugados": 0,
	"Goles_Totales": 0,
	"Asistencias_Totales": 0,
	"Temporadas_Jugadas": 0,
	"Titulos_Superliga": 0,
	"Salario_Semanal": 150,
	"Estado_Temporada": "En_Curso", # "En_Curso", "Ascendido", "Mantiene", "Descendido", "Campeon", "Despedido"
	"Entrenamientos_Asistencia": {
		"Martes": true,
		"Jueves": true,
		"Diario": true # Usado en Modo_Rapido
	},
	# Estado de la mini-liga dominical en Modo Normal (4 equipos, 3 jornadas + 4º partido playoff)
	"Liga_Domingo": {
		"Jornada_Actual": 0, # 0..3 (0-2 fase regular, 3 playoff final)
		"Puntos_Jugador": 0,
		"Puntos_Rivales": [0, 0, 0],
		"Medias_Rivales": [45.0, 45.0, 45.0],
		"Posicion_Regular": 1
	}
}
```

##### 3.2. Serialización en `Guardar_Variables_Dinamicas.gd` y Reseteo en `Menu.gd`
* En `save_game()`: guardar `"Carrera_Futbol": Variables_Dinamicas.Carrera_Futbol.duplicate(true)`.
* En `load_game()`: si existe `"Carrera_Futbol"` como `Dictionary`, cargar y completar cualquier clave faltante con el diccionario por defecto (para compatibilidad entre versiones). Si no existe, usar el diccionario por defecto.
* En `Menu.gd`: al iniciar nueva partida, resetear `Variables_Dinamicas.Carrera_Futbol` a sus valores iniciales con `"Activo": false`.

---

#### 4. Catálogo de Actividades y Estados (`Variables_Estaticas.gd`)

Dentro de `_Inicializar_Catalogo()` (sin añadirlas al pool aleatorio `Actividades`):

1. **`Entrenamiento_Futbol`** (`Actividad_Fija.new()`, P2):
   * `nombre = "Entrenamiento_Futbol"`
   * `color = Color(0.2, 0.6, 0.86)`
   * `efectos_necesidades_basicas = [2, 1, -2, -3, -3]`
   * `efectos_progreso = [4, 0, 0]` (`Progreso[0]` Deporte)
2. **`Partido_Futbol`** (`Actividad_Partido.new()`, P3):
   * `nombre = "Partido_Futbol"`
   * `color = Color(0.15, 0.75, 0.35)`
   * `efectos_necesidades_basicas = [-1, 3, -4, -5, -4]`
   * `efectos_progreso = [6, 0, 0]`
3. **Estado temporal `"Lesion_Deportiva"`** en `Variables_Estaticas.Estados_Temporales`:
```gdscript
"Lesion_Deportiva": {
	"duracion": 1440,
	"meseta": 360,
	"tipo": "cap_gradual",
	"indices": [0], # Salud Física
	"cap_inicial": 35,
	"cap_final": 100,
	"titulo_inicio": "Lesión deportiva",
	"titulo_fin": "Recuperado de lesión",
	"mensaje_inicio": "Has sufrido una lesión deportiva. Tu salud física queda limitada durante 24 h.",
	"mensaje_fin": "Te has recuperado totalmente de la lesión deportiva."
}
```

---

#### 5. Calendario y Horarios (`Calendario_Futbol.gd`)

Crear `Scripts/Logica/Escena_Principal/Actividades/Futbol/Calendario_Futbol.gd` (`class_name Calendario_Futbol`, `extends RefCounted`):

* **Entrenamientos:**
  * `Modo_Rapido == true`: Todos los días, **45 min**. 3ª Div: `18:30–19:15`; Profesional (2ª, 1ª, Superliga): `10:00–10:45`.
  * `Modo_Rapido == false`: **Martes (`dia_semana == 1`) y Jueves (`dia_semana == 3`)**, **120 min**. 3ª Div: `19:00–21:00`; Profesional: `10:00–12:00`.
* **Partidos:**
  * `Modo_Rapido == true`: Todos los días, **1 partido decisivo diario** de **60 min** a las **20:30–21:30**.
  * `Modo_Rapido == false`: **Domingos (`dia_semana == 6`)**, **4 partidos de 60 min** repartidos para permitir comer/descansar entre medias:
    * Partido 1 (Fase regular J1): `10:00–11:00`
    * Partido 2 (Fase regular J2): `13:00–14:00`
    * Partido 3 (Fase regular J3): `16:00–17:00`
    * Partido 4 (Playoff Ascenso `1º vs 2º` / Permanencia `3º vs 4º`): `19:00–20:00`

---

#### 6. Motor Matemático (`Simulador_Futbol.gd`)

Crear `Scripts/Logica/Escena_Principal/Actividades/Futbol/Simulador_Futbol.gd` (`class_name Simulador_Futbol`, `extends RefCounted`):

* **Divisiones:** `4`: `"3ª División Regional"` (umbral `45.0`, salario `150`), `3`: `"2ª División Nacional"` (umbral `62.0`, salario `600`), `2`: `"1ª División Élite"` (umbral `78.0`, salario `2500`), `1`: `"Superliga Internacional"` (umbral `90.0`, salario `10000`).
* **Primas:** Victoria `{4:50, 3:200, 2:800, 1:3000}`, Gol `{4:15, 3:50, 2:150, 1:500}`.
* **Funciones puras requeridas:**
  1. `Calcular_Condicion_Fisica(salud_fisica: float, descanso: float, hambre: float) -> float`:
     `clampf((salud_fisica * 0.45) + (descanso * 0.35) + (hambre * 0.20), 0.0, 100.0)`
  2. `Calcular_Innata_Futbol(habilidades: Array) -> float`:
     Lee de forma segura `habilidades[0]` (Deporte, peso `0.50`), `habilidades[4]` (Liderazgo, peso `0.25`), `habilidades[6]` (Sangre fría, peso `0.25`). Si el array tiene menos elementos, usar `50.0` por defecto.
  3. `Evaluar_Convocatoria(relacion_entrenador: float, condicion_fisica: float, salud_fisica: float, liderazgo: float, lesionado: bool) -> Dictionary`:
     * Bloqueos duros: `lesionado == true`, `salud_fisica < 30.0`, `relacion_entrenador < 25.0`.
     * Índice: `(relacion_entrenador * 0.55) + (condicion_fisica * 0.30) + (liderazgo * 0.15)`. Convocado si `indice >= 45.0`.
  4. `Calcular_Puntuacion_Partido(progreso_deporte: float, condicion_fisica: float, innata_futbol: float, sangre_fria: float, es_partido_decisivo: bool, variacion_aleatoria: float = 0.0) -> float`:
     * **Partido normal (J1–J3):** `(progreso_deporte * 0.50) + (condicion_fisica * 0.30) + (innata_futbol * 0.20) + variacion_aleatoria`.
     * **Partido decisivo (4º partido de domingo o partido diario en Modo Rápido):** `Sangre fría` tiene **mayor importancia** en el partido: `(progreso_deporte * 0.42) + (condicion_fisica * 0.25) + (innata_futbol * 0.13) + (sangre_fria * 0.20) + variacion_aleatoria`.
     * Clampeado a `[0.0, 100.0]`.
  5. `Resolver_Tanda_Penaltis(sangre_fria: float, progreso_deporte: float, tirada_azar: float) -> bool`:
     * Solo se usa si hay **empate en el 4º partido decisivo (Modo Normal)** (en Modo Rápido un empate mantiene categoría sin penaltis).
     * `Sangre fría` tiene **peso dominante**: `prob_ganar = clampf(0.25 + (sangre_fria / 100.0) * 0.55 + (progreso_deporte / 100.0) * 0.20, 0.15, 0.90)`.
     * Retorna `true` si `tirada_azar < prob_ganar` (gana la tanda), `false` si pierde.
  6. `Simular_Partido_Liga(puntuacion_final: float, media_rival: float, es_decisivo: bool, sangre_fria: float = 50.0, progreso_deporte: float = 50.0, azar_penaltis: float = 0.5) -> Dictionary`:
     * Si `puntuacion_final >= media_rival + 4.0`: `"Victoria"`, `goles = 1 + int((puntuacion_final - media_rival) / 12.0)`, `delta_relacion = 4.0`.
     * Si `puntuacion_final >= media_rival - 4.0`: `"Empate"`:
       * Si `es_decisivo`: resuelve por `Resolver_Tanda_Penaltis(sangre_fria, progreso_deporte, azar_penaltis)` → `gano_penaltis: bool` (el resultado final del cruce pasa a ser `"Victoria_Penaltis"` o `"Derrota_Penaltis"`).
     * En otro caso: `"Derrota"`, `goles = 0`, `delta_relacion = -3.0`.
     * Calcular también `asistencias: int` (p. ej. `1` si `puntuacion_final >= media_rival` y `goles >= 1`, o según liderazgo).
  7. `Resolver_Playoff_Domingo(posicion_regular: int, gano_partido_4: bool, division_actual: int) -> Dictionary`:
     * Si `posicion_regular <= 2` (`1º vs 2º` por el ascenso):
       * `gano_partido_4 == true` → queda 1º: si `division_actual > 1`, `cambio_division = -1` (asciende); si `division_actual == 1`, `campeon_superliga = true`.
       * `gano_partido_4 == false` → queda 2º: `cambio_division = 0` (se mantiene).
     * Si `posicion_regular >= 3` (`3º vs 4º` por la permanencia):
       * `gano_partido_4 == true` → queda 3º: `cambio_division = 0` (se mantiene).
       * `gano_partido_4 == false` → queda 4º: si `division_actual == 4`, `despedido = true`; si `division_actual < 4`, `cambio_division = 1` (desciende).
  8. `Simular_Partido_Rapido(puntuacion_final: float, division_actual: int) -> Dictionary`:
     * Para `Modo_Rapido == true` (1 partido diario contra `UMBRALES_DIVISION[division_actual]`): Victoria (`>= umbral`) asciende (`-1`) o gana Superliga; Empate (`>= umbral - 8.0`) mantiene (`0`); Derrota desciende (`+1`) o despide en 3ª División.
  9. `Comprobar_Riesgo_Lesion(condicion_fisica: float, salud_fisica: float, tirada_azar: float) -> bool`:
     * Si `condicion_fisica < 30.0 or salud_fisica < 25.0`, `return tirada_azar < 0.25`.

---

#### 7. Integración en el Ciclo Horario (`Actividades.gd`)

1. **Entrenamientos:** En el minuto de inicio según `Calendario_Futbol`:
   * Si asiste (`Entrenamientos_Asistencia`): inscribe/ejecuta `Entrenamiento_Futbol` (P2). Al terminar el bloque suma `+3.0` (o `+5.0` si condición ≥ 70) a `Relacion_Entrenador` y resetea `Entrenamientos_Cancelados_Seguidos = 0`.
   * Si no asiste: `-12.0` a `Relacion_Entrenador`, `Entrenamientos_Cancelados_Seguidos += 1`, añade `Mensaje.new()` a `Variables_Dinamicas.Mensajes`.
2. **Partidos:**
   * **En Modo Normal (Domingo):** Al inicio del día (primer minuto del domingo o al inicio del partido 1), generar los 3 rivales de `Liga_Domingo` con medias en torno a `UMBRALES_DIVISION[Division] ± 5.0` y resetear `Jornada_Actual = 0`, `Puntos_Jugador = 0`, `Puntos_Rivales = [0, 0, 0]`.
   * En cada uno de los 4 horarios (`10:00`, `13:00`, `16:00`, `19:00`):
     * Evaluar convocatoria (`Evaluar_Convocatoria`). Si no es convocado, el jugador pierde el partido `0-3` (sin goles/primas).
     * Si es convocado, ejecutar `Partido_Futbol` (P3) durante 60 min y resolver al finalizar:
       * Partidos 1–3 (`Jornada_Actual < 3`): usar `Calcular_Puntuacion_Partido(..., es_partido_decisivo=false)` y `Simular_Partido_Liga(..., es_decisivo=false)`, actualizar puntos de tabla (simular también el otro cruce entre los otros 2 rivales) y enviar crónica breve a `Mensajes`. Al terminar el 3º, calcular `Posicion_Regular` (1..4).
       * Partido 4 (`19:00`, `Jornada_Actual == 3`): usar `Calcular_Puntuacion_Partido(..., es_partido_decisivo=true)` (más peso de `Sangre fría`) y `Simular_Partido_Liga(..., es_decisivo=true)` (con penaltis si empata), luego `Resolver_Playoff_Domingo(...)`. Aplicar ascenso/permanencia/descenso/despido, `Temporadas_Jugadas += 1`, `Titulos_Superliga` si campeón, y enviar crónica final a `Mensajes`.
   * **En Modo Rápido:** 1 partido diario (`20:30–21:30`) usando `es_partido_decisivo=true` y `Simular_Partido_Rapido(...)`.
   * **Liquidación económica y lesiones:** Sumar primas de victoria y gol (`* Multiplicador_Precios()`) a `Dinero`; comprobar `Comprobar_Riesgo_Lesion` y activar `"Lesion_Deportiva"` en `Variables_Dinamicas.Estados_Temporales`.
3. **Salario semanal:** Domingo `23:59` (o diario `23:59` en Modo Rápido) sumar `Salario_Semanal * Multiplicador_Precios()` a `Dinero`.

---

#### 8. Detección y Resolución de Conflictos en Actividades Fijas

Siempre que exista solapamiento horario entre los entrenamientos de fútbol y un trabajo (`Actividad_Fija_Trabajo`), el jugador **debe elegir uno u otro** mediante un diálogo modal de alerta:
1. **Al fichar por 3ª División o al ascender a 2ª División (entrenamiento pasa a 10:00–12:00):**
   * Si `Variables_Dinamicas.Trabajo_Actual != null` y su franja (`hora_inicio..hora_final`) y `dias_laborales` solapan con el horario de `Entrenamiento_Futbol`:
   * Mostrar alerta modal:
     * **Opción A ("Seguir con el Fútbol"):** `Variables_Dinamicas.Trabajo_Actual = null`, limpia sus bloques de la matriz y confirma el alta/ascenso en fútbol.
     * **Opción B ("Mantener Trabajo"):** Si era intento de fichaje en 3ª, cancela el fichaje; si era ascenso a 2ª, rechaza el ascenso y permanece en 3ª División (entrenando de tarde).
2. **Al seleccionar un trabajo en Actividades Fijas (`Trabajo.gd` / `Script_Principal.gd`):**
   * Si `Variables_Dinamicas.Carrera_Futbol["Activo"] == true` y el trabajo elegido solapa en días y horas con `Calendario_Futbol.Obtener_Horario_Entrenamiento(...)`:
   * Mostrar la misma alerta de solapamiento para elegir entre **dejar el fútbol** (rescindir/desactivar `Carrera_Futbol` y limpiar sus bloques) o **quedarse en el fútbol** (cancelar la contratación del trabajo).

---

#### 9. Interfaz de Usuario Vertical (`720×1280` Portrait)

1. **Botón en Actividades Fijas (`Escena principal.tscn`):**
   * Añadir `Boton_Carrera_Futbol` (`"Carrera Futbolística"`) junto a los botones de `Trabajo` / `Fijas_Opciones`.
2. **Panel `Panel_Futbol.tscn` + `Scripts/GUI/Escena_Principal/Actividades/Futbol/Panel_Futbol_GUI.gd`:**
   * Ancho máx. ~680 px centrado, responsive en altura con `ScrollContainer`.
   * **Sin club (`Activo == false`):** Requisitos (`Progreso[0] >= 25` y `Calcular_Edad() < 30`) con color verde/rojo y botón `"Realizar Prueba de Fichaje"`.
   * **Con club (`Activo == true`):** División actual, salario, estado de temporada, posición en la liga dominical (si es domingo en Modo Normal), barra de `Progreso[0]` (Deporte), barra de `Relacion_Entrenador` (colores Rojo <25, Amarillo 25–60, Verde >60), estadísticas (`Partidos_Jugados`, `Goles_Totales`, `Asistencias_Totales`, `Temporadas_Jugadas`), toggles de asistencia a entrenamientos y botón `"Rescindir Contrato"` (con confirmación).

---

#### 10. Suite de Tests Unitarios GUT (`Funcionalidades/Actividades/Futbol/Tests/test_futbol.gd`)

Implementar tests GUT que cubran como mínimo:
1. `Calcular_Condicion_Fisica` (valores extremos y ponderados).
2. `Calcular_Innata_Futbol` con `Array` de 7 habilidades reales.
3. `Evaluar_Convocatoria` (convocado, relación <25, salud <30, lesionado).
4. `Calcular_Puntuacion_Partido` verificando que `Sangre fría` pesa más en partido decisivo que en partido normal.
5. `Resolver_Tanda_Penaltis` verificando la influencia dominante de `Sangre fría`.
6. `Resolver_Playoff_Domingo` (1º asciende, 2º mantiene, 3º mantiene, 4º desciende o despide en 3ª División).
7. `Simular_Partido_Rapido` (victoria asciende, empate mantiene, derrota desciende/despide en 3ª).
8. `Calendario_Futbol` (horarios Modo Normal: 4 partidos domingo `10/13/16/19`, entreno 3ª `19:00` y 2ª `10:00`; Modo Rápido: entreno 45 min y partido `20:30`).

---

#### 11. Checklist de Entrega
1. Ejecutar los tests GUT (`test_futbol.gd` y tests existentes) y confirmar que pasan al 100% sin errores ni advertencias de tipo.
2. Verificar compatibilidad al cargar un save antiguo sin `Carrera_Futbol`.
3. Verificar que `Entrenamiento_Futbol` (P2) y `Partido_Futbol` (P3) respetan la jerarquía de `Matriz_Jugador`.
4. Verificar la alerta de conflicto horario en ambas direcciones (fútbol ↔ trabajo).
5. Entregar resumen técnico de archivos creados/modificados y resultados de los tests.
