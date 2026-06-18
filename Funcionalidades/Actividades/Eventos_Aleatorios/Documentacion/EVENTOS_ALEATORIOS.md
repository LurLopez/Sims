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
