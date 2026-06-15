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
