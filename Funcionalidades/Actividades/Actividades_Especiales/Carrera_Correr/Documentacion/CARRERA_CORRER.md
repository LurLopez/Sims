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
