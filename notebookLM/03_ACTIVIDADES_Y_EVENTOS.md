# Jerarquía de Actividades

## Descripción General

Sistema de prioridades que regula qué actividades pueden coexistir o reemplazarse en la matriz del jugador. Evita que el jugador coloque actividades triviales encima de compromisos importantes (trabajo, examen), y garantiza que al programar trabajo este ocupe el horario respetando únicamente el examen.

---

## Clases / Resources

### `Actividad` — `Scripts/Logica/Escena_Principal/Actividades/Herencia/Actividad.gd`
| Método | Retorno | Valor |
|---|---|---|
| `Obtener_Prioridad()` | `int` | `1` (base para todas las Temporales) |

### `Actividad_Fija` — `Scripts/Logica/Escena_Principal/Actividades/Herencia/Actividad_Fija.gd`
| Método | Retorno | Valor |
|---|---|---|
| `Obtener_Prioridad()` | `int` | `2` (heredado por `Actividad_Fija_Trabajo`) |

`Actividad_Temporal` y `Actividad_Carrera` no sobreescriben el método → prioridad 1.

### Niveles de prioridad

| Nivel | Tipo | Ejemplos |
|---|---|---|
| 3 | Examen (verificación dinámica vía `Carrera_Actual`) | Hora del examen universitario |
| 2 | `Actividad_Fija` / `Actividad_Fija_Trabajo` | Trabajar_En_Comida_Rapida, Trabajar_De_Carpintero |
| 1 | `Actividad_Temporal` / `Actividad_Carrera` | Dormir, Comer, Estudiar, Estudiar_Carrera… |
| 0 | Celda vacía (`""` o `"Actividad_Aleatoria"`) | — |

---

## Variables Dinámicas / Estáticas afectadas

Solo lectura (la jerarquía no modifica estas variables, solo las consulta):

| Variable | Uso |
|---|---|
| `Variables_Dinamicas.Carrera_Actual` | Para detectar si existe examen activo |
| `Variables_Dinamicas.Carrera_Actual.hora_examen_dia` | Día de la semana del examen (0–6) |
| `Variables_Dinamicas.Carrera_Actual.hora_examen_inicio` | Minuto del día de inicio (ej: `900` = 15:00) |
| `Variables_Dinamicas.Carrera_Actual.matriculado` | El examen bloquea celda solo si matriculado o prematriculado |
| `Variables_Dinamicas.Carrera_Actual.prematriculado` | Ídem |
| `Variables_Dinamicas.Matriz_Jugador[j][i]` | Celda leída antes de escribir |

---

## Flujo de Ejecución

### 1. Detectar prioridad de una celda — `Actividades._Prioridad_Celda(celda, i, j)`

```gdscript
func _Prioridad_Celda(celda, i: int, j: int) -> int:
    var carrera = Variables_Dinamicas.Carrera_Actual
    if carrera != null and carrera.hora_examen_dia >= 0 and (carrera.matriculado or carrera.prematriculado):
        # CRÍTICO: la detección de examen es puramente dinámica; no hay objeto en la matriz
        if i % 7 == carrera.hora_examen_dia and j >= carrera.hora_examen_inicio and j < carrera.hora_examen_inicio + 60:
            return 3
    if celda is Actividad:
        return celda.Obtener_Prioridad()
    return 0
```

El examen no ocupa celdas de la matriz; su prioridad se calcula en el momento comparando `i % 7` y el rango `[hora_examen_inicio, hora_examen_inicio + 60)`.

### 2. Escribir una celda — `Actividades.Crear_Actividad(i, j, actividad) → bool`

```gdscript
func Crear_Actividad(i, j, actividad) -> bool:
    # Borrar ("") siempre permitido
    if actividad is String:
        Variables_Dinamicas.Matriz_Jugador[j][i] = actividad
        return true
    var celda_actual = Variables_Dinamicas.Matriz_Jugador[j][i]
    if _Prioridad_Celda(celda_actual, i, j) > actividad.Obtener_Prioridad():
        return false
    Variables_Dinamicas.Matriz_Jugador[j][i] = actividad
    return true
```

### 3. Calcular rango de celdas — `Actividades._Calcular_Rango(...) → Array`

Extrae el bucle de iteración de celdas en un helper que devuelve `Array` de pares `[i, j]`. Permite hacer un pre-scan antes de escribir para evitar escrituras parciales.

```gdscript
func _Calcular_Rango(semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final) -> Array:
    var celdas = []
    var i = semana * 7 + dia_inicio
    var i_fin = semana * 7 + dia_final
    var j = hora_inicio * 60 + minuto_inicio
    var j_fin = hora_final * 60 + minuto_final
    var seguir = true
    while seguir:
        if j_fin == 0:
            if i + 1 >= i_fin:
                if j >= 1439:
                    seguir = false
            elif j >= 1440:
                i += 1
                j = 0
        else:
            if i >= i_fin:
                if j + 1 >= j_fin:
                    seguir = false
            elif j >= 1440:
                i += 1
                j = 0
        celdas.append([i, j])
        j += 1
    return celdas
```

### 4. Programar actividad — `Actividades.Crear_Actividad_Especifica(...) → bool`

```gdscript
func Crear_Actividad_Especifica(..., actividad) -> bool:
    # ... resolver actividad_obj ...

    var celdas = _Calcular_Rango(...)

    # CRÍTICO: para P1 se hace pre-scan completo antes de escribir nada.
    # Así nunca hay escrituras parciales: o se escribe todo o nada.
    if actividad_obj is Actividad and actividad_obj.Obtener_Prioridad() == 1:
        for par in celdas:
            var celda_actual = Variables_Dinamicas.Matriz_Jugador[par[1]][par[0]]
            if _Prioridad_Celda(celda_actual, par[0], par[1]) > 1:
                return false  # Bloqueada: hay trabajo o examen en el rango

    for par in celdas:
        Crear_Actividad(par[0], par[1], actividad_obj)

    Guardar_Variables_Estaticas.save_game()
    Guardar_Variables_Dinamicas.save_game()
    return true
```

Para P2 (trabajo) no hay pre-scan: `Crear_Actividad` salta celdas de examen (P3 > P2 → return false) y sobreescribe celdas de temporales (P1 < P2 → escribe).

### 5. Programar trabajo — `Trabajo.Trabajar(actividad)`

```gdscript
for j in range(actividad.hora_inicio, actividad.hora_final):
    Actividades.Crear_Actividad(i, j, actividad)
    # Las celdas de examen se saltan silenciosamente (P3 > P2 → Crear_Actividad devuelve false)
```

### 6. GUI — `Script_Principal.Crear_Actividad(actividad)`

```gdscript
func Crear_Actividad(actividad):
    var ok = actividades_reloj_gui.horario.Crear_Actividad(mirar_semana, actividad)
    if not ok:
        _Mostrar_Error_Prioridad()
        return
    Actividad_Terminada()  # Solo se cierra el reloj si tuvo éxito
```

El `AcceptDialog` de error se crea perezosamente la primera vez (`_dialog_prioridad`).

---

## Casos de Uso

| Escenario | Resultado |
|---|---|
| Colocar "Salir_A_Correr" en horario de trabajo | Bloqueado. `AcceptDialog` informa al jugador. El reloj no se cierra. |
| Colocar "Estudiar" en la hora de examen | Bloqueado. Mismo mensaje. |
| `Trabajo.Trabajar()` con examen el miércoles 15:00–16:00 | El trabajo se escribe en todos los miércoles excepto en `[900, 960)`. |
| Borrar (`""`) un bloque de trabajo desde el calendario | Siempre permitido. |
| Colocar "Dormir" encima de "Ver_La_Television" | Permitido (P1 sobre P1). |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| El examen **no está en la matriz** | Su prioridad se calcula en tiempo de ejecución comparando `i % 7` con `carrera.hora_examen_dia` |
| Sin carrera activa | `Carrera_Actual == null` → no hay celdas P3; el sistema actúa como si no existiera el nivel 3 |
| Borrado siempre libre | Escribir `""` salta toda comprobación de prioridad |
| Sin escritura parcial para P1 | El pre-scan garantiza que si hay conflicto, no se modifica ninguna celda del rango |
| `Trabajo.Trabajar()` no usa pre-scan | Es P2: salta P3 celda a celda, y sobreescribe P1 |
| `Obtener_Prioridad()` usa dispatch dinámico | Más seguro que redeclarar `var prioridad` en GDScript (los `var` del padre no se sobreescriben de forma fiable a través de referencias tipadas) |

---

## Checklist de Implementación

- [x] `Actividad.gd` — añadir `Obtener_Prioridad() → 1`
- [x] `Actividad_Fija.gd` — override `Obtener_Prioridad() → 2`
- [x] `Actividades.gd` — `_Prioridad_Celda`, `_Calcular_Rango`, `Crear_Actividad → bool`, `Crear_Actividad_Especifica → bool`
- [x] `Trabajo.gd` — usar `Actividades.Crear_Actividad` en lugar de asignación directa
- [x] `SeleccionarHorarioReloj.gd` — propagar bool de `Crear_Actividad_Especifica`
- [x] `Script_Principal.gd` — `_Mostrar_Error_Prioridad()` + `_dialog_prioridad`, no llamar `Actividad_Terminada()` si falla
# Eventos Aleatorios

## Descripción General

Sistema que añade imprevistos al juego de forma automática cada minuto de juego. Existen dos tipos de eventos:

1. **Despido por higiene** — ocurre únicamente durante un turno de trabajo. Si la higiene es ≤ 50, hay una probabilidad de ser despedido. Aplica un cooldown de 5 días sobre ese trabajo concreto.
2. **Eventos generales** — sucesos aleatorios (enfermedades, bonus de dinero, accidentes, eventos sociales, hallazgos, inspiración) con restricción horaria. Cada evento solo puede ocurrir dentro de su franja del día.

El objetivo es añadir variabilidad y consecuencias tangibles a las necesidades básicas, especialmente la higiene.

---

## Clases / Resources

### `Eventos_Aleatorios` (autoload)
**Archivo:** `Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd`
**Tipo:** `extends Node` — registrado como autoload en `project.godot`

#### Inner class `Evento`

| Propiedad | Tipo | Descripción |
|---|---|---|
| `tipo` | `int` (enum TipoEvento) | Categoría del evento |
| `titulo` | `String` | Título para el mensaje en bandeja |
| `descripcion` | `String` | Texto descriptivo del evento |
| `efectos` | `Dictionary` | `{"necesidades": [5], "dinero": int, "progreso": [3]}` |
| `hora_inicio` | `int` | Minuto del día desde el que puede ocurrir (-1 = sin restricción) |
| `hora_fin` | `int` | Minuto del día hasta el que puede ocurrir (-1 = sin restricción) |

**Método clave:**
```gdscript
func Es_Hora_Valida(minuto: int) -> bool:
    if hora_inicio == -1:
        return true
    # Franja que cruza medianoche (ej. 18:00–6:00)
    if hora_inicio > hora_fin:
        return minuto >= hora_inicio or minuto < hora_fin
    return minuto >= hora_inicio and minuto < hora_fin
```

#### Enum `TipoEvento`

```gdscript
enum TipoEvento {
    ENFERMEDAD_LEVE, ENFERMEDAD_GRAVE,
    BONUS_DINERO, BONUS_DINERO_GRANDE,
    ACCIDENTE_LEVE, ACCIDENTE_GRAVE,
    EVENTO_SOCIAL_POSITIVO, EVENTO_SOCIAL_NEGATIVO,
    HALLAZGO, INSPIRACION,
}
```

#### Variables de estado del autoload

| Variable | Tipo | Descripción |
|---|---|---|
| `minutos_sin_evento` | `int` | Minutos acumulados sin que ocurra un evento general; aumenta la probabilidad |
| `_eventos_disponibles` | `Array[Evento]` | Catálogo de 20 eventos inicializado en `_ready()` |

#### Constantes

| Constante | Valor | Descripción |
|---|---|---|
| `PROBABILIDAD_BASE` | `2880` | Base de probabilidad general (1/2880 por minuto ≈ 1 cada 2 días) |
| `MINUTOS_SIN_EVENTO_BASE` | `1440` | Minutos de gracia antes de que la prob. suba |
| `COOLDOWN_TRABAJO_MINUTOS` | `7200` | 5 días × 1440 min — duración del cooldown de trabajo |

---

## Variables Dinámicas / Estáticas afectadas

| Variable | Tipo | Uso |
|---|---|---|
| `Variables_Dinamicas.Cooldown_Trabajos` | `Dictionary` | `{nombre_trabajo: minuto_fin_cooldown}` — persiste el cooldown por trabajo |
| `Variables_Dinamicas.Trabajo_Actual` | `Actividad_Fija_Trabajo \| null` | Leído para saber si el jugador está trabajando |
| `Variables_Dinamicas.Necesidades_Basicas` | `Array[int]` | Leído (higiene `[4]`) y modificado por eventos generales |
| `Variables_Dinamicas.Dinero` | `float` | Modificado por eventos de bonus/accidente |
| `Variables_Dinamicas.Progreso` | `Array[int]` | Modificado por algunos eventos (lesión, hallazgo, inspiración) |
| `Variables_Dinamicas.Mensajes` | `Array[Mensaje]` | Se añade un `Mensaje` en cada evento ocurrido |
| `Variables_Dinamicas.Minute_Minute` | `int` | Minuto del día actual — usado para filtro horario y cálculo de cooldown |
| `Variables_Dinamicas.Minute_Day` | `int` | Día absoluto — usado para cálculo de cooldown |

---

## Flujo de Ejecución

### Llamada cada minuto

Desde `Actividades.Actualizar_Horario()`, después de ejecutar la actividad de la celda actual:

```gdscript
# Actividades.gd — dentro del bucle for i in range(minutos_a_procesar)
var celda = Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day]
# ... Ejecutar_Actividad(celda) ...
get_node("/root/Eventos_Aleatorios").Tick_Eventos(celda)
```

### `Tick_Eventos(celda_actual)`

```gdscript
func Tick_Eventos(celda_actual) -> void:
    _Comprobar_Despido_Por_Higiene(celda_actual)
    _Comprobar_Evento_General()
```

### Despido por higiene

```gdscript
func _Comprobar_Despido_Por_Higiene(celda_actual) -> void:
    if not (celda_actual is Actividad_Fija_Trabajo):
        return
    if Variables_Dinamicas.Trabajo_Actual == null:
        return
    var higiene = Variables_Dinamicas.Necesidades_Basicas[4]
    if higiene > 50:
        return
    # CRÍTICO: divisor = 25000 / (50 - higiene)
    # higiene=50 → 0% | higiene=40 → 1/2500 | higiene=20 → 1/833 | higiene=1 → 1/510
    var divisor = int(25000.0 / max(1, 50 - higiene))
    if divisor < 2:
        divisor = 2
    if randi() % divisor != 0:
        return
    _Despedir_Del_Trabajo()
```

### `_Despedir_Del_Trabajo()`

```gdscript
func _Despedir_Del_Trabajo() -> void:
    var trabajo = Variables_Dinamicas.Trabajo_Actual
    var nombre_trabajo = trabajo.nombre
    var minuto_actual = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
    # CRÍTICO: guardar cooldown ANTES de llamar Dejar_Trabajo (que pone Trabajo_Actual = null)
    Variables_Dinamicas.Cooldown_Trabajos[nombre_trabajo] = minuto_actual + COOLDOWN_TRABAJO_MINUTOS
    Trabajo.Dejar_Trabajo(trabajo)
    # Crear mensaje en bandeja
    var msg = Mensaje.new()
    msg.titulo = "¡Despedido!"
    msg.descripcion = "Te han despedido de ... por falta de higiene.\n\nNo podrás volver durante 5 días."
    msg.leido = false
    msg.minuto = minuto_actual
    Variables_Dinamicas.Mensajes.append(msg)
    Guardar_Variables_Dinamicas.save_game()
```

### Eventos generales — probabilidad acumulativa

```gdscript
func _Comprobar_Evento_General() -> void:
    minutos_sin_evento += 1
    var prob_actual = PROBABILIDAD_BASE
    if minutos_sin_evento > MINUTOS_SIN_EVENTO_BASE:
        var exceso = minutos_sin_evento - MINUTOS_SIN_EVENTO_BASE
        prob_actual = max(60, PROBABILIDAD_BASE - exceso)  # mínimo 1/60 por minuto
    if randi() % prob_actual != 0:
        return
    var evento = _Seleccionar_Evento()
    if evento == null:
        return
    _Aplicar_Evento(evento)
    minutos_sin_evento = 0
```

### Selección ponderada con filtro horario

```gdscript
func _Seleccionar_Evento() -> Evento:
    var minuto_actual = Variables_Dinamicas.Minute_Minute
    # Calcular media de necesidades una sola vez
    var pesos = []
    for i in range(_eventos_disponibles.size()):
        var evento = _eventos_disponibles[i]
        if not evento.Es_Hora_Valida(minuto_actual):
            pesos.append(0.0)   # CRÍTICO: peso 0 excluye el evento sin eliminarlo del array
            continue
        var peso_base = 1.0
        # Sesgos según estado del jugador (enfermedades más probables si necesidades bajas, etc.)
        pesos.append(peso_base)
    var suma_pesos = 0.0
    for p in pesos: suma_pesos += p
    if suma_pesos == 0.0:
        return null   # CRÍTICO: ningún evento válido en esta hora, no ocurre nada
    # Ruleta ponderada...
```

### Comprobación de cooldown (desde Script_Principal)

```gdscript
# Script_Principal.gd — _Intentar_Tomar_Trabajo()
var minutos_rest = get_node("/root/Eventos_Aleatorios").Minutos_Restantes_Cooldown(actividad.nombre)
if minutos_rest > 0:
    _Mostrar_Error_Requisito("... Tiempo restante: %d horas y %d minutos." % [horas, mins])
    return
```

```gdscript
# Eventos_Aleatorios.gd
func Minutos_Restantes_Cooldown(nombre_trabajo: String) -> int:
    if not Variables_Dinamicas.Cooldown_Trabajos.has(nombre_trabajo):
        return 0
    var minuto_actual = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
    var fin_cooldown = Variables_Dinamicas.Cooldown_Trabajos[nombre_trabajo]
    if minuto_actual >= fin_cooldown:
        Variables_Dinamicas.Cooldown_Trabajos.erase(nombre_trabajo)
        Guardar_Variables_Dinamicas.save_game()
        return 0
    return fin_cooldown - minuto_actual
```

---

## Catálogo de eventos (20 eventos)

| Evento | Tipo | Franja | Efectos principales |
|---|---|---|---|
| Resfriado | ENFERMEDAD_LEVE | Cualquier hora | -salud fís, -sal mental, -descanso / -20€ |
| Dolor de cabeza | ENFERMEDAD_LEVE | Cualquier hora | -sal mental, -descanso / -10€ |
| Intoxicación alimentaria | ENFERMEDAD_LEVE | 8:00–22:00 | -todo / -15€ |
| Gripe | ENFERMEDAD_GRAVE | Cualquier hora | Penalizaciones fuertes / -50€ |
| Lesión deportiva | ENFERMEDAD_GRAVE | 6:00–18:00 | -salud fís fuerte, -3 deporte / -80€ |
| Reembolso inesperado | BONUS_DINERO | 9:00–18:00 | +100€ |
| Trabajo extra | BONUS_DINERO | 9:00–18:00 | +150€ / -sal mental, -descanso |
| Herencia | BONUS_DINERO_GRANDE | Cualquier hora | +500€ |
| Premio de lotería | BONUS_DINERO_GRANDE | Cualquier hora | +1000€ |
| Multa de tráfico | ACCIDENTE_LEVE | 8:00–22:00 | -sal mental / -60€ |
| Lavadora estropeada | ACCIDENTE_LEVE | 8:00–22:00 | -higiene / -80€ |
| Accidente de coche | ACCIDENTE_GRAVE | 7:00–23:00 | -varios / -300€ |
| Robo | ACCIDENTE_GRAVE | 18:00–6:00 | -sal mental / -200€ |
| Quedada con amigos | SOCIAL_POSITIVO | 16:00–23:00 | +sal mental fuerte / -30€ |
| Cena familiar | SOCIAL_POSITIVO | 18:00–22:00 | +sal mental, +hambre / 0€ |
| Discusión con amigo | SOCIAL_NEGATIVO | Cualquier hora | -sal mental fuerte |
| Mal día | SOCIAL_NEGATIVO | 8:00–20:00 | -varios |
| Libro interesante | HALLAZGO | 10:00–20:00 | +sal mental, +académico / -15€ |
| Material manualidades | HALLAZGO | 9:00–18:00 | +manualidades |
| Chispa de creatividad | INSPIRACION | Cualquier hora | +sal mental, +académico, +manualidades |
| Motivación repentina | INSPIRACION | 5:00–10:00 | +todo |

---

## Persistencia (Save/Load)

### Guardado
`Guardar_Variables_Dinamicas.game_data_func()` incluye:
```gdscript
"Cooldown_Trabajos": Variables_Dinamicas.Cooldown_Trabajos,
```
El diccionario almacena `{nombre_trabajo: minuto_absoluto_fin_cooldown}` donde `minuto_absoluto = Minute_Day * 1440 + Minute_Minute`.

### Carga
```gdscript
if game_data.has("Cooldown_Trabajos"):
    Variables_Dinamicas.Cooldown_Trabajos = game_data["Cooldown_Trabajos"]
else:
    Variables_Dinamicas.Cooldown_Trabajos = {}
get_node("/root/Eventos_Aleatorios").Limpiar_Cooldowns_Expirados()
```
`Limpiar_Cooldowns_Expirados()` elimina entradas cuyo minuto de fin ya pasó.

### Lo que NO se persiste
- `minutos_sin_evento` — se reinicia a 0 en cada carga. Efecto: el primer evento general puede ocurrir antes de lo habitual tras reiniciar.
- `_eventos_disponibles` — se reconstruye en `_ready()`.

---

## Casos de Uso

| Escenario | Condición | Resultado esperado |
|---|---|---|
| Jugador trabajando con higiene 30 | Celda es `Actividad_Fija_Trabajo`, higiene=30 | 1/1250 prob/min de ser despedido |
| Jugador despedido | — | `Trabajo_Actual = null`, celdas futuras borradas, mensaje en bandeja, cooldown 5 días |
| Jugador intenta retomar trabajo en cooldown | 3 días después del despido | Mensaje de error con tiempo restante, trabajo no se toma |
| Evento "Cena familiar" a las 15:00 | `Minute_Minute = 900` | Peso = 0, no puede ser seleccionado |
| Evento "Robo" a las 3:00 AM | `Minute_Minute = 180` | `hora_inicio(1080) > hora_fin(360)` → `180 < 360` → válido |
| Sin eventos durante 2 días | `minutos_sin_evento = 2880` | `prob_actual = max(60, 2880 - 1440) = 1440` → probabilidad duplicada |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| Franja con cruce de medianoche | `hora_inicio > hora_fin` → `minuto >= hora_inicio OR minuto < hora_fin` |
| Suma de pesos cero | Si todos los eventos están fuera de horario, `_Seleccionar_Evento` devuelve `null` y no ocurre nada |
| Cooldown calculado con `Minute_Day * 1440 + Minute_Minute` | Equivalente a `Variables_Dinamicas.Minute`; ambos deben ser coherentes |
| Sesgos de peso | Enfermedades ×2–6 si necesidades bajas; bonus ×1.5 si dinero<100; accidentes ×1.8 si salud<30 |
| `save_game()` en cooldown expiry | Se llama al comprobar cooldown si ha expirado — puede ser lento en móvil |
| El despido ocurre DESPUÉS de `Ejecutar_Actividad` | El salario del minuto actual ya se cobra antes del posible despido |

---

## Checklist de Implementación

- [x] `Eventos_Aleatorios.gd` — autoload con `Tick_Eventos`, catálogo de 20 eventos, franjas horarias
- [x] `project.godot` — `Eventos_Aleatorios` registrado como autoload
- [x] `Variables_Dinamicas.gd` — `Cooldown_Trabajos: Dictionary`
- [x] `Guardar_Variables_Dinamicas.gd` — guardado/carga de `Cooldown_Trabajos` + llamada a `Limpiar_Cooldowns_Expirados`
- [x] `Actividades.gd` — llamada a `Tick_Eventos(celda)` en `Actualizar_Horario`
- [x] `Script_Principal.gd` — comprobación de cooldown en `_Intentar_Tomar_Trabajo`
# Carrera Correr (Carreras de Atletismo)

## Descripción General

Evento semanal de competición de atletismo que da utilidad real al progreso de Deporte. El jugador puede inscribirse de lunes a viernes (coste 50€), eligiendo día (sábado o domingo) y hora. La carrera ocupa 60 minutos en el calendario con prioridad P3 (igual que `Examen_Carrera`). El resultado se calcula con un snapshot de variables al inicio de la hora, se aplican los premios al final, y se envía un mensaje de notificación. El número de participantes rivales se genera cada lunes y crece visiblemente durante la semana, creando una capa de estrategia para el jugador.

---

## Clases / Resources

### `Actividad_Carrera_Deportiva` (nueva clase)
**Archivo:** `Scripts/Logica/Escena_Principal/Actividades/Actividades_Especiales/Actividad_Carrera_Deportiva.gd`
**Tipo:** `extends Actividad_Temporal`

```gdscript
class_name Actividad_Carrera_Deportiva
extends Actividad_Temporal

func Obtener_Prioridad() -> int:
    return 3  # P3: no puede ser sobreescrita por trabajo (P2) ni actividades normales (P1)
```

Registrada en `Variables_Estaticas.Catalogo_Actividades["Carrera_Deportiva"]` con efectos idénticos a `Salir_A_Correr`:

```gdscript
var carrera_dep = Actividad_Carrera_Deportiva.new()
carrera_dep.nombre = "Carrera_Deportiva"
carrera_dep.color = Color(0.10, 0.72, 0.30)
carrera_dep.efectos_necesidades_basicas = [4, 2, -3, -3, -4]  # igual que Salir_A_Correr
carrera_dep.efectos_progreso = [4, 0, 0]
Catalogo_Actividades["Carrera_Deportiva"] = carrera_dep
```

### `Sistema_Carreras_Deportivas` (nuevo nodo)
**Archivo:** `Scripts/Logica/Escena_Principal/Actividades/Actividades_Especiales/Sistema_Carreras_Deportivas.gd`
**Tipo:** `extends Node` — añadir a la escena principal o como autoload

Funciones principales: `Calcular_Y_Guardar_Resultado()`, `Aplicar_Premio_Y_Notificar()`, `Escribir_Carrera_En_Matriz()`, `Calcular_Inscritos_Visibles() -> int`.

---

## Variables Dinámicas / Estáticas afectadas

| Variable | Tipo | Descripción |
|---|---|---|
| `Variables_Dinamicas.Carrera_Deportiva_Pendiente` | `Dictionary` | Estado completo de la carrera de la semana actual (ver estructura abajo) |
| `Variables_Dinamicas.Progreso[0]` | `int 1–100` | Progreso de Deporte — leído para la fórmula, modificado por bonus post-carrera |
| `Variables_Dinamicas.Necesidades_Basicas[0]` | `int 1–100` | Salud Física — snapshot al inicio de carrera |
| `Variables_Dinamicas.Necesidades_Basicas[3]` | `int 1–100` | Descanso — snapshot al inicio de carrera |
| `Variables_Dinamicas.Necesidades_Basicas[2]` | `int 1–100` | Hambre — snapshot al inicio de carrera |
| `Variables_Dinamicas.Dinero` | `float` | -50€ al inscribirse, +premio al terminar |
| `Variables_Dinamicas.Mensajes` | `Array[Mensaje]` | Recibe notificación de resultado al terminar la carrera |
| `Variables_Estaticas.Catalogo_Actividades["Carrera_Deportiva"]` | `Actividad_Carrera_Deportiva` | Referencia del catálogo que se escribe en la matriz |

### Estructura de `Carrera_Deportiva_Pendiente`

```gdscript
# En Variables_Dinamicas.gd — valor inicial:
var Carrera_Deportiva_Pendiente: Dictionary = {
    "inscrito": false,       # true si el jugador está inscrito esta semana
    "dia": -1,               # 5=Sábado, 6=Domingo
    "hora_inicio": -1,       # minutos desde medianoche (ej. 540 = 9:00)
    "semana_inscripcion": -1,# Minute_Day / 7 en el momento de inscribirse
    "total_inscritos": 0,    # total generado el lunes (60–140), persiste toda la semana
    "resultado_puesto": -1,  # puesto calculado al inicio de carrera (-1 = no calculado aún)
    "resultado_procesado": false  # true = premio ya aplicado y mensaje enviado
}
```

---

## Flujo de Ejecución

### 1. Lunes 00:00 — Generar participantes de la semana

En `Actividades.Actualizar_Horario()`, dentro del bucle, tras actualizar `Minute_Day`/`Minute_Minute`:

```gdscript
# CRÍTICO: regenerar solo si no hay carrera pendiente inscrita (no pisar datos activos)
var dia_semana = Variables_Dinamicas.Minute_Day % 7
var minuto_dia = Variables_Dinamicas.Minute_Minute
if dia_semana == 0 and minuto_dia == 0:
    if not Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("inscrito", false):
        var total = int(clamp(randfn(100.0, 15.0), 60.0, 140.0))
        Variables_Dinamicas.Carrera_Deportiva_Pendiente["total_inscritos"] = total
        Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_puesto"] = -1
        Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_procesado"] = false
```

### 2. Lunes–Viernes — Inscripción del jugador

Botón en UI → modal → el jugador elige día (Sáb/Dom) y hora (07:00–17:00):

```gdscript
# En Script_Principal.gd o Sistema_Carreras_Deportivas.gd
func Inscribirse_Carrera(dia: int, hora_inicio: int) -> bool:
    if Variables_Dinamicas.Dinero < 50.0:
        return false
    if Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("inscrito", false):
        return false  # ya hay una inscrita
    Variables_Dinamicas.Dinero -= 50.0
    var semana_actual = Variables_Dinamicas.Minute_Day / 7
    Variables_Dinamicas.Carrera_Deportiva_Pendiente["inscrito"] = true
    Variables_Dinamicas.Carrera_Deportiva_Pendiente["dia"] = dia
    Variables_Dinamicas.Carrera_Deportiva_Pendiente["hora_inicio"] = hora_inicio
    Variables_Dinamicas.Carrera_Deportiva_Pendiente["semana_inscripcion"] = semana_actual
    Escribir_Carrera_En_Matriz()
    Guardar_Variables_Dinamicas.save_game()
    return true
```

### 3. Escribir al calendario (P3)

```gdscript
func Escribir_Carrera_En_Matriz() -> void:
    var pendiente = Variables_Dinamicas.Carrera_Deportiva_Pendiente
    var semana = pendiente.get("semana_inscripcion", -1)
    var columna = semana * 7 + pendiente.get("dia", -1)
    if columna < 0 or columna >= 574:
        return
    var actividad = Variables_Estaticas.Catalogo_Actividades["Carrera_Deportiva"]
    var hora_inicio = pendiente.get("hora_inicio", -1)
    for offset in range(60):
        var fila = hora_inicio + offset
        if fila < 1440:
            Variables_Dinamicas.Matriz_Jugador[fila][columna] = actividad
```

### 4. Inicio de carrera — Snapshot y cálculo del resultado

En `Actividades.Actualizar_Horario()`, primer minuto del bloque de carrera:

```gdscript
var pendiente = Variables_Dinamicas.Carrera_Deportiva_Pendiente
if pendiente.get("inscrito", false) and pendiente.get("resultado_puesto", -1) == -1:
    var semana_actual = Variables_Dinamicas.Minute_Day / 7
    var dia_semana = Variables_Dinamicas.Minute_Day % 7
    var minuto_dia = Variables_Dinamicas.Minute_Minute
    if semana_actual == pendiente.get("semana_inscripcion", -1) \
    and dia_semana == pendiente.get("dia", -1) \
    and minuto_dia == pendiente.get("hora_inicio", -1):
        get_node("/root/Sistema_Carreras_Deportivas").Calcular_Y_Guardar_Resultado()
```

```gdscript
# Sistema_Carreras_Deportivas.gd
func Calcular_Y_Guardar_Resultado() -> void:
    # CRÍTICO: snapshot de las variables PRE-carrera (antes de que correr las degrade)
    var deporte = Variables_Dinamicas.Progreso[0]
    var salud_fisica = Variables_Dinamicas.Necesidades_Basicas[0]
    var descanso = Variables_Dinamicas.Necesidades_Basicas[3]
    var hambre = Variables_Dinamicas.Necesidades_Basicas[2]

    var condicion_fisica = salud_fisica * 0.50 + descanso * 0.35 + hambre * 0.15
    var puntuacion_base = deporte * 0.65 + condicion_fisica * 0.35
    var puntuacion_jugador = clamp(randfn(puntuacion_base, 15.0), 0.0, 100.0)

    # Generar puntuaciones de todos los rivales y contar cuántos supera el jugador
    var total = Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("total_inscritos", 100)
    var mejor_que = 0
    for _i in range(total - 1):  # -1: el jugador ya cuenta como inscrito
        var rival = clamp(randfn(50.0, 20.0), 0.0, 100.0)
        if puntuacion_jugador > rival:
            mejor_que += 1

    # Puesto 1 = mejor, total = peor
    var puesto = total - mejor_que
    Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_puesto"] = puesto
```

### 5. Durante los 60 minutos — Efectos de correr

La celda contiene `Actividad_Carrera_Deportiva`. `Actividades.Ejecutar_Actividad()` la procesa normalmente:

```gdscript
# Actividades.gd — mismo código que para cualquier actividad
Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(actividad.efectos_necesidades_basicas, actividad.nombre)
# efectos_necesidades_basicas = [4, 2, -3, -3, -4] → igual que Salir_A_Correr
Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array(actividad.efectos_progreso)
# efectos_progreso = [4, 0, 0] → sube Deporte con la misma probabilidad que correr
```

El resultado ya calculado NO se ve afectado por esta degradación.

### 6. Fin de carrera — Premio y notificación

En `Actividades.Actualizar_Horario()`, al cruzar `hora_inicio + 60`:

```gdscript
var pendiente = Variables_Dinamicas.Carrera_Deportiva_Pendiente
if pendiente.get("inscrito", false) \
and pendiente.get("resultado_puesto", -1) != -1 \
and not pendiente.get("resultado_procesado", false):
    var semana_actual = Variables_Dinamicas.Minute_Day / 7
    var dia_semana = Variables_Dinamicas.Minute_Day % 7
    var hora_fin = pendiente.get("hora_inicio", -1) + 60
    if semana_actual == pendiente.get("semana_inscripcion", -1) \
    and dia_semana == pendiente.get("dia", -1) \
    and Variables_Dinamicas.Minute_Minute >= hora_fin:
        get_node("/root/Sistema_Carreras_Deportivas").Aplicar_Premio_Y_Notificar()
```

```gdscript
func Aplicar_Premio_Y_Notificar() -> void:
    var pendiente = Variables_Dinamicas.Carrera_Deportiva_Pendiente
    var puesto = pendiente.get("resultado_puesto", 99)
    var total = pendiente.get("total_inscritos", 100)

    var premio = _Calcular_Premio(puesto)
    var bonus_min = _Calcular_Bonus_Minutos(puesto)

    Variables_Dinamicas.Dinero += premio
    if bonus_min > 0:
        _Aplicar_Bonus_Correr(bonus_min)

    var msg = Mensaje.new()
    msg.titulo = "Carrera completada"
    msg.descripcion = "Has quedado %dº de %d participantes.\n" % [puesto, total]
    if premio > 50.0:
        msg.descripcion += "Premio: +%.0f€ (neto +%.0f€).\n" % [premio, premio - 50.0]
    elif premio == 50.0:
        msg.descripcion += "Recuperas la inscripción (50€). Sin ganancias.\n"
    else:
        msg.descripcion += "Sin premio. Pierdes los 50€ de inscripción.\n"
    if bonus_min > 0:
        msg.descripcion += "Bonus Deporte: equivalente a %d min corriendo." % bonus_min
    msg.leido = false
    msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
    Variables_Dinamicas.Mensajes.append(msg)

    pendiente["resultado_procesado"] = true
    pendiente["inscrito"] = false
    Guardar_Variables_Dinamicas.save_game()
```

### Tablas de premio y bonus

```gdscript
func _Calcular_Premio(puesto: int) -> float:
    if puesto == 1:      return 550.0   # neto +500€
    elif puesto == 2:    return 350.0   # neto +300€
    elif puesto == 3:    return 250.0   # neto +200€
    elif puesto <= 10:
        var t = float(puesto - 4) / 6.0
        return lerp(200.0, 130.0, t)   # neto +150€ → +80€
    elif puesto <= 20:
        var t = float(puesto - 11) / 9.0
        return lerp(80.0, 60.0, t)     # neto +30€ → +10€
    elif puesto <= 50:   return 50.0    # break even
    else:                return 0.0    # pierde 50€

func _Calcular_Bonus_Minutos(puesto: int) -> int:
    if puesto == 1:      return 200
    elif puesto == 2:    return 150
    elif puesto == 3:    return 100
    elif puesto <= 10:   return 80
    elif puesto <= 20:   return 50
    elif puesto <= 50:   return 20
    else:                return 0

func _Aplicar_Bonus_Correr(minutos: int) -> void:
    # Reutiliza el mismo mecanismo probabilístico de Actividades_Habilidades.gd.
    # Con Deporte bajo: sube mucho. Con Deporte alto: sube poco (logarítmico natural).
    for _i in range(minutos):
        Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([4, 0, 0])
```

### Contador visible para la UI

```gdscript
func Calcular_Inscritos_Visibles() -> int:
    var total = Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("total_inscritos", 0)
    var dia_semana = Variables_Dinamicas.Minute_Day % 7
    var factor = {0: 0.10, 1: 0.25, 2: 0.45, 3: 0.70, 4: 0.90, 5: 1.0, 6: 1.0}
    return int(total * factor.get(dia_semana, 1.0))
```

---

## UI: Nodos y Visibilidad

- **Botón de inscripción:** dentro de `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso_Opciones` en `Escena principal.tscn`. Solo visible lunes–viernes y si no hay carrera inscrita.
- **Modal de inscripción:** nodo hijo de la escena principal. Muestra contador de inscritos actuales (`Calcular_Inscritos_Visibles()`), selector de día (Sáb/Dom) y selector de hora (07:00–17:00 en pasos de 30 min).
- **Estado "carrera pendiente":** el botón cambia de texto a "Carrera inscrita: [día] [hora]" cuando `inscrito == true`.

---

## Persistencia (Save/Load)

En `Guardar_Variables_Dinamicas.gd`:

```gdscript
# game_data_func() — añadir:
"Carrera_Deportiva_Pendiente": Variables_Dinamicas.Carrera_Deportiva_Pendiente,

# load_game() — añadir:
Variables_Dinamicas.Carrera_Deportiva_Pendiente = game_data.get(
    "Carrera_Deportiva_Pendiente",
    {
        "inscrito": false, "dia": -1, "hora_inicio": -1,
        "semana_inscripcion": -1, "total_inscritos": 0,
        "resultado_puesto": -1, "resultado_procesado": false
    }
)
```

El diccionario solo contiene primitivos (`bool`, `int`, `float`) — no necesita conversión especial, a diferencia de `Carrera_Actual` que requiere `_Carrera_A_Dict()`.

---

## Casos de Uso

| Escenario | Estado | Resultado esperado |
|---|---|---|
| Jugador entrenado y descansado | Deporte 85, Salud 80, Descanso 75 | Puntuación ~82 → probable top 10 con 100 inscritos. Premio ≥130€ + boost alto. |
| Jugador entrenado pero agotado | Deporte 80, Salud 20, Descanso 15 | Puntuación ~60 → puesto ~30-50. Break even o pequeña pérdida. |
| Jugador débil, pocos rivales (viernes tarde) | Deporte 30, 62 inscritos visibles | Probabilidad ~80% de top 50 → break even. Estrategia rentable. |
| Juego cerrado durante la carrera | Reapertura posterior | `Actualizar_Horario` procesa los minutos perdidos. Snapshot ocurre al procesar `hora_inicio`, premio al procesar `hora_inicio+60`. Funciona correctamente. |
| Sin dinero al intentar inscribirse | `Dinero < 50` | `Inscribirse_Carrera()` retorna `false`. No se descuenta nada. |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| Momento del cálculo | Snapshot al **primer minuto** de la hora de carrera. El resultado se guarda en `resultado_puesto` y se revela al **último minuto** (fin) via mensaje. |
| Prioridad P3 | La `Actividad_Carrera_Deportiva` retorna `3` en `Obtener_Prioridad()`. No puede ser sobreescrita por trabajo (P2) ni actividades normales (P1). |
| Total inscritos | Se genera cada lunes con `randfn(100, 15)` clampado a [60, 140]. Persiste en el dict durante toda la semana. No se regenera si el jugador ya está inscrito. |
| Restricción de inscripción | Solo lunes–viernes. Sábado y domingo ya no se puede inscribir (la carrera es ese mismo fin de semana o ya pasó). |
| Una carrera por semana | `inscrito == true` bloquea nuevas inscripciones. Se resetea al procesar el resultado. |
| Rivals score | `randfn(50.0, 20.0)` — media 50, σ=20. Jugador con Deporte 80 y buenas condiciones (~puntuación 80) supera ~85% de rivales. |
| Bonus correr | Llama `Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([4, 0, 0])` N veces. Usa la misma curva logarítmica que `Salir_A_Correr`. Académico y Manualidades no se ven afectados (efecto=0). |

---

## Convenciones de Nombres

| Elemento | Nombre |
|---|---|
| Clase actividad | `Actividad_Carrera_Deportiva` |
| Clave en catálogo | `"Carrera_Deportiva"` |
| Nodo de lógica | `Sistema_Carreras_Deportivas` |
| Variable dinámica | `Carrera_Deportiva_Pendiente` |
| Clave en save | `"Carrera_Deportiva_Pendiente"` |

---

## Checklist de Implementación

- [ ] Crear `Actividad_Carrera_Deportiva.gd` con `Obtener_Prioridad() -> 3`
- [ ] Registrar `"Carrera_Deportiva"` en `Variables_Estaticas._Inicializar_Catalogo()`
- [ ] Crear `Sistema_Carreras_Deportivas.gd` con las funciones descritas
- [ ] Añadir `Carrera_Deportiva_Pendiente` a `Variables_Dinamicas.gd`
- [ ] Añadir generación de total en lunes 00:00 en `Actividades.Actualizar_Horario()`
- [ ] Añadir detección de inicio de carrera (snapshot) en `Actualizar_Horario()`
- [ ] Añadir detección de fin de carrera (premio + mensaje) en `Actualizar_Horario()`
- [ ] Añadir save/load de `Carrera_Deportiva_Pendiente` en `Guardar_Variables_Dinamicas.gd`
- [ ] Añadir botón en `Escena principal.tscn` > `Progreso_Opciones`
- [ ] Crear modal de inscripción con contador de inscritos visibles y selector día/hora
- [ ] Conectar señales en `Script_Principal.gd`

---

# Salir de Fiesta (Euforia y Resacón) — IMPLEMENTADO

Actividad temporal P1 `Salir_De_Fiesta` con ventana 18:00–06:00, duración 2–12 h y dos probabilidades independientes por minuto (ligar y resacón). No entra en el pool aleatorio.

- **Catálogo:** `Actividad_Temporal`, color `Color(0.85, 0.15, 0.45)`, NB `[0, 9, -3, -4, -2]`, Prog `[0,0,0]`.
- **Validación:** `Actividades.Validar_Horario_Fiesta(...)` (inicio 18:00–04:00, fin 20:00–06:00, 120–720 min, cruce de medianoche, límite 573). El selector normaliza domingo→lunes con `dia_inicio + 1`.
- **Ligar:** `puntaje = 50 + 0.30*Mental + 0.25*Higiene + 0.20*Deporte + 0.15*Académico + 0.10*Descanso + personalidad + edad` (sobre 50). `prob = (0.00001 + 0.00099 * puntaje/100) * mult_dia`; `mult_dia`: L–X 0.70, J 1.00, V 1.25, S 1.45, D 0.80.
- **Resacón:** `aguante = 50 + 0.40*Hambre + 0.30*Descanso + 0.20*Física + 0.10*Deporte + mod_edad`; `prob = 0.00001 + 0.00099 * (100-aguante)/100`.
- **Edad:** `clamp(10 - (edad-20)*0.625, -25, 12)`.
- **Noche:** pertenece al día de inicio; **las 06:00 cuentan como el día anterior**.
- **Un evento por bloque:** `Fiesta_Evento_Ocurrido`; dos bloques adyacentes cuentan como uno.
- **Estados:** `Euforia` (suelo Mental 100→50) y `Resacon` (techo Física/Mental 30→100), 1440 min, mutuamente excluyentes. Curvas: `suelo = floor(100 - p*50)`, `cap = 30 + floor(p*70)`. En calle/bancarrota, efecto máximo 20.
- **Mensajes:** `Has ligado`, `Resacón`, `Fin de la euforia`, `Fin del resacón`; `leido=false` para el badge del perfil.
- **Preview:** `Actividades.Simular_Preview_Fiesta(...)` con riesgos competitivos; `p_ligar + p_resacon + p_nada = 1`. Panel `Preview_Fiesta` en `Seleccionar_Horario` (688×584) y flujo de dos pasos para Fiesta.
- **Persistencia:** `Estados_Temporales` y `Fiesta_Evento_Ocurrido` con fallback `{}`/`false`, filtrado y saneado.
- **Tests:** `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd`; suite GUT 100/100.
- **Ficha completa:** `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/SALIR_DE_FIESTA.md`.
