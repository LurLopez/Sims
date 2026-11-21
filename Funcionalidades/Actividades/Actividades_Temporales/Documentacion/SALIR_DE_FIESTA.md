# Salir de Fiesta — Euforia y Resacón

> Versión implementada: 2026-11-19 · Actividad temporal P1 · Estados temporales persistentes.

## 1. Resumen

`Salir_De_Fiesta` es una actividad temporal de alto riesgo y alta recompensa. Se programa entre las 18:00 y las 06:00, dura entre 2 y 12 horas y cada minuto calcula dos probabilidades independientes:

- **Ligar**: sube con Salud Mental, Higiene, Descanso, Deporte, Académico, personalidad, edad y día de la semana.
- **Resacón**: sube cuando empeoran Hambre, Descanso, Salud Física o cuando baja el Deporte; la edad también influye.

El primer evento que sale se resuelve una sola vez por bloque de fiesta. Ligar activa `Euforia` durante 24 h; pasarse con la bebida activa `Resacon` durante 24 h. Ambos estados son mutuamente excluyentes y generan una notificación en la bandeja de entrada.

## 2. Catálogo y jerarquía

| Campo | Valor |
|---|---|
| Clave | `Salir_De_Fiesta` |
| Clase | `Actividad_Temporal` |
| Prioridad | P1 |
| Color | `Color(0.85, 0.15, 0.45)` |
| Efectos necesidades | `[0, 9, -3, -4, -2]` |
| Efectos progreso | `[0, 0, 0]` |
| Pool aleatorio | **No** (solo se ejecuta si el jugador la programa) |

La actividad no puede pisar trabajo (P2) ni examen (P3): `Crear_Actividad_Especifica` bloquea toda la operación si alguna celda del rango tiene prioridad mayor que 1.

## 3. Ventana horaria y validación

`Actividades.Validar_Horario_Fiesta(...)` es una función pura que devuelve:

```gdscript
{ "valido": true, "duracion_min": 720, "motivo": "" }
{ "valido": false, "duracion_min": 0, "motivo": "..." }
```

Reglas, en orden de comprobación:

1. Inicio permitido: **18:00–04:00** inclusive.
2. Fin permitido: **20:00–06:00** inclusive. Las 24:00 se tratan como 00:00 del día siguiente.
3. Si el bloque es 18:00–19:59, prevalece el motivo de **duración mínima** (AC-04).
4. Cruce de medianoche: se deduce de las horas (`inicio >= 18:00` y `fin <= 06:00`).
5. Duración mínima **120 min** y máxima **720 min**.
6. Coherencia de días: en un cruce se acepta el mismo día (se normaliza al siguiente) o el día siguiente, incluido domingo(6) → lunes(0).
7. Límite de matriz: con `semana` informada, el día final absoluto no puede superar **573**.

Mensajes exactos:

| Caso | Motivo |
|---|---|
| Inicio fuera de 18:00–04:00 | `La fiesta debe empezar entre las 18:00 y las 04:00` |
| Fin fuera de 20:00–06:00 | `La fiesta debe terminar como máximo a las 06:00` |
| Menos de 2 h | `La fiesta debe durar al menos 2 horas` |
| Más de 12 h | `La fiesta no puede durar más de 12 horas` |
| Fin no posterior / días incoherentes | `El horario de fin debe ser posterior al de inicio` |
| Se sale de la matriz | `El bloque se sale del calendario` |

### Normalización al escribir

El selector trabaja con días de la semana 0–6. Para un cruce de medianoche, `SeleccionarHorarioReloj` pasa a `_Calcular_Rango` el día `dia_inicio + 1` (puede ser 7 = lunes siguiente), sin modificar `_Calcular_Rango` para el resto de actividades.

## 4. Fórmulas

### 4.1. Ligar

```
mod_edad = clamp(10.0 - (edad - 20) * 0.625, -25.0, 12.0)

puntaje_ligar = clamp(
    50
    + 0.30 * (NB[1] - 50)        # Salud Mental
    + 0.25 * (NB[4] - 50)        # Higiene
    + 0.20 * (Progreso[0] - 50)  # Deporte
    + 0.15 * (Progreso[1] - 50)  # Académico
    + 0.10 * (NB[3] - 50)        # Descanso
    + mod_personalidad
    + mod_edad,
    0, 100
)

prob_ligar_min = (0.00001 + 0.00099 * puntaje_ligar / 100) * mult_dia
```

Personalidad: `Deportista +10`, `Culo_Del_Sofa −10`, `Trabajador_Compulsivo −5`, resto `0`.

Multiplicador por noche:

| Día de la noche | Mult. |
|---|---|
| Lunes–Miércoles (0–2) | 0.70 |
| Jueves (3) | 1.00 |
| Viernes (4) | 1.25 |
| Sábado (5) | 1.45 |
| Domingo (6) | 0.80 |

La noche pertenece al día en que empezó. **El límite son las 06:00 inclusive**: un domingo a las 06:00 todavía cuenta como noche del sábado.

### 4.2. Resacón

```
aguante_resacon = clamp(
    50
    + 0.40 * (NB[2] - 50)        # Hambre
    + 0.30 * (NB[3] - 50)        # Descanso
    + 0.20 * (NB[0] - 50)        # Salud Física
    + 0.10 * (Progreso[0] - 50)  # Deporte
    + mod_edad,
    0, 100
)

riesgo_resacon = (100 - aguante_resacon) / 100
prob_resacon_min = 0.00001 + 0.00099 * riesgo_resacon
```

El día de la semana y la personalidad **no** afectan al resacón.

### 4.3. Tirada por minuto

```
if randf() < prob_ligar_min:
    activar Euforia
elif randf() < prob_resacon_min:
    activar Resacon
```

Máximo un evento por bloque. `Fiesta_Evento_Ocurrido` se resetea en el primer minuto de un bloque nuevo; dos bloques adyacentes cuentan como uno solo.

## 5. Vista previa

`Actividades.Simular_Preview_Fiesta(...)` proyecta las necesidades minuto a minuto con el valor esperado de los efectos:

```
delta = signo(efecto) * min(1, abs(efecto) / frecuencia)
nb = clamp(nb + delta, 1, 100)
```

Frecuencias: física/mental 30, hambre 12, descanso 15, higiene 20.

La simulación usa riesgos competitivos (ligar se resuelve primero):

```
p_ligar += supervivencia * pl
p_resacon += supervivencia * pr * (1 - pl)
supervivencia *= (1 - pl) * (1 - pr)
p_nada = supervivencia
```

Siempre se cumple `p_ligar + p_resacon + p_nada = 1`.

En `Seleccionar_Horario`, el panel `Preview_Fiesta` sustituye al mini calendario mientras se ajusta la fiesta:

```
Salir de fiesta
Duración: 4h 00m
Por minuto: ligar 0,070 % al empezar · 0,059 % al terminar
Por minuto: resacón 0,024 % al empezar · 0,079 % al terminar
Ligar: 19,7 % · Resacón: 15,7 % · Nada: 64,6 %
Estimación según tus necesidades actuales y el desgaste previsto.
```

Si el horario no es válido, el panel muestra el motivo en rojo y oculta las probabilidades.

### Flujo de creación

La actividad se elige antes que el horario:

1. **Actividades → Especiales → Salir de fiesta**.
2. Se abre `Seleccionar_Horario` en modo Fiesta con el panel de vista previa y una franja propuesta dentro de la ventana 18:00–06:00 (o la franja que se hubiera marcado antes en el calendario).
3. Ajustar inicio y final y pulsar **Crear actividad**: se valida la ventana y se escribe directamente en la matriz.

Si se parte del calendario, el botón **Elegir actividad** abre el catálogo y conserva la franja seleccionada como propuesta; al elegir la actividad se vuelve al selector para confirmar el horario.

El resto de actividades sigue el mismo orden: primero la actividad en el catálogo y después el selector de horario.

## 6. Estados temporales

### Euforia

- Duración: 1440 min.
- Primeras 8 h (480 min): suelo de Salud Mental = **100**.
- Últimas 16 h (960 min): baja linealmente de 100 a 50.
- Al activarse: Salud Mental sube a 100 (o 20 en calle/bancarrota).
- Sustituye a `Resacon`.

### Resacón

- Duración: 1440 min.
- Primeras 8 h: techo de Salud Física y Mental = **30**.
- Últimas 16 h: sube linealmente de 30 a 100.
- Al activarse: Salud Física y Mental se recortan a 30 (o 20 en calle/bancarrota).
- Sustituye a `Euforia`.
- Mientras está activo, ninguna actividad puede subir física o mental por encima del techo.

### Curvas de referencia

| Minutos restantes | Tiempo restante | Techo Resacón | Suelo Euforia |
|---|---|---|---|
| 1440–960 | 24–16 h | 30 | 100 |
| 720 | 12 h | 47 | 87 |
| 480 | 8 h | 65 | 75 |
| 240 | 4 h | 82 | 62 |
| 0 | 0 h | 100 | 50 |

La fórmula de Euforia usa `floor(100 - progreso * 50)` para que 720 → 87 y 240 → 62 coincidan con la tabla aprobada.

### Tick

Cada minuto de simulación, para cada estado activo:

1. Se aplica el efecto con el contador actual.
2. Se descuenta 1 minuto.
3. Si llega a 0, se elimina y se añade el mensaje de fin.

`Tick_Estados()` se ejecuta siempre, esté o no el personaje de fiesta, para que las 24 h corran también durante otras actividades.

## 7. Notificaciones

Al activar un estado se añade un `Mensaje` a `Variables_Dinamicas.Mensajes` con `leido = false`:

| Título | Descripción |
|---|---|
| `Has ligado` | `Has ligado. Euforia durante 24 h.` |
| `Resacón` | `Te has pasado con la bebida. Resacón durante 24 h.` |
| `Fin de la euforia` | `La euforia ha terminado.` |
| `Fin del resacón` | `El resacón ha terminado.` |

El badge de mensajes no leídos del perfil se actualiza automáticamente.

## 8. Persistencia

`Variables_Dinamicas` añade:

```gdscript
var Estados_Temporales: Dictionary = {}   # { "Euforia": minutos } o { "Resacon": minutos }
var Fiesta_Evento_Ocurrido: bool = false
```

`Guardar_Variables_Dinamicas` guarda ambos campos y los carga con fallback:

- Save antiguo sin campos → `{}` y `false`.
- Valores de estado convertidos a `int` y limitados a `0..1440`.
- Claves desconocidas filtradas.
- Si un save corrupto trae `Euforia` y `Resacon` a la vez, se conserva el que tenga más minutos restantes (empate → `Resacon`).

`Menu._reiniciar_partida_desde_cero()` también resetea ambos campos.

## 9. UI

### Botón

- Nodo: `Actividades/Elegir_Actividad/Tipos_De_Actividades/Especiales_Opciones/Salir_De_Fiesta`.
- Texto de escena: `🎉  SALIR DE FIESTA`.
- Icono: `party-popper` (`Estilos_UI.ICONOS_BOTONES`).
- Subtítulo: `Noche · 2–12 h · Prob. según estado`.
- El contenedor mide 960 px; los 5 botones ocupan 5×78 + 4×10 = 430 px, sin scroll.

### Panel de preview

- Nodo dinámico `Preview_Fiesta`, hijo de `Seleccionar_Horario`.
- Rect: `(16, 174)` · `688×584`. Termina en y=758, antes de los relojes (y=772).
- Sustituye al mini calendario solo en modo Fiesta.
- Se actualiza al cambiar día/hora/minuto, sin trabajo por frame.

### Label de estado

- `Estado_Temporal_Label` dentro del card `Resumen_Necesidades`.
- `Euforia · 23h 59m` en verde.
- `Resacón · 18h 20m · límite 45` en rojo.
- Oculto si no hay estado activo.
- Se actualiza con la misma cadencia que el resto del panel (0,5 s), pero solo toca la UI cuando cambia la firma de los estados.

## 10. Tests

Archivo: `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd`.

Cubre:

- Catálogo, efectos, P1 y ausencia del pool aleatorio.
- Botón, conexión, icono, subtítulo y layout de 5 botones.
- Ventana 18:00–06:00, 2–12 h, cruce de medianoche, 24:00, domingo→lunes y límite de matriz.
- Fórmulas independientes, edad, personalidad, día de la semana y tabla de 6 h.
- Preview: suma 1, desgaste, valores por minuto y UI válida/inválida.
- Primer minuto, bloques adyacentes y máximo un evento.
- Activación, sustitución mutua, mensajes, curvas de cap/suelo, tick y cap en `Cambiar_Necesidades_Basicas`.
- Persistencia, save antiguo, claves desconocidas y ambos estados.
- Label de estado.
- No regresión de jerarquía.

Resultado actual: **100/100 tests GUT pasando** (suite completa del proyecto).

## 11. Correcciones aplicadas a la especificación v1.0

Al implementar se detectaron incoherencias numéricas. Se aplicaron las fórmulas y la tabla acumulada como fuente de verdad:

| Punto | Spec v1.0 | Implementado |
|---|---|---|
| AC-08, minuto 0, NB=80 | Ligar 0,070 % · Resacón 0,031 % | Ligar 0,0698 % · Resacón 0,0239 % |
| AC-08, minuto 360, NB=80 | Ligar 0,042 % · Resacón 0,059 % | Ligar 0,0590 % · Resacón 0,0785 % |
| AC-13, 720 min | Techo 65 | 720 → 47; 480 → 65 |
| Curva Euforia | 720 → 87; 240 → 62 con `100 - floor(p*50)` (daba 88/63) | `floor(100 - p*50)` → 87/62 |
| AC-04 | 18:00–19:59 → duración mínima | Se mantiene: el caso se evalúa antes que el fin |
| Límite 06:00 | `hora < 6` | `hora <= 6`: las 06:00 del domingo cuentan como sábado |

La tabla acumulada de 6 h (19,7 / 15,7 / 64,6 para NB=80) se mantiene exacta.

## 12. Archivos

| Archivo | Cambio |
|---|---|
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | Actividad y `Estados_Temporales` |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | `Estados_Temporales`, `Fiesta_Evento_Ocurrido` |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Save/load con fallback y filtrado |
| `Scripts/Globales/Menu.gd` | Reset en partida nueva |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Fórmulas, validación, estados, evento e integración |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` | Cap de Resacón |
| `Escenas/Escena_Principal/Escena principal.tscn` | Botón y conexión |
| `Scripts/GUI/Escena_Principal/Estilos_UI.gd` | Icono |
| `Scripts/Globales/Script_Principal.gd` | Handler, flujo actividad → horario, preview, diálogo y label |
| `Scripts/GUI/Escena_Principal/Actividades/Reloj/Auxiliar/SeleccionarHorarioReloj.gd` | Preview y normalización de día final |
| `Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd` | Label de estado |
| `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd` | Tests GUT |
| `Funcionalidades/Actividades/Jerarquia/Tests/test_jerarquia.gd` | Bootstrap de matriz y examen como objeto real |
| `Funcionalidades/Actividades/Eventos_Aleatorios/Tests/test_eventos_aleatorios.gd` | Typo `Coolood_Trabajos` corregido |
| `addons/gut/` | GUT 9.7.1 vendorizado para ejecutar la suite |
| `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/SALIR_DE_FIESTA.md` / `.html` | Esta ficha |
| `Prompts/salir-de-fiesta/salir-de-fiesta.md` / `.html` | Spec v1.1 con las correcciones numéricas |
| `Prompts/MEGA_PROMPT_CONTEXTO.md`, `notebookLM/00_CONTEXTO_MAESTRO_Y_ROL.md` | Contexto actualizado |
| `CLAUDE.md` | Contexto actualizado |
