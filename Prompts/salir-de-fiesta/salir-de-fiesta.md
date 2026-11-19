# Salir de fiesta: ligue, euforia y resacón
> Versión v1.1 · 2026-11-19 · Estado: Aprobada e implementada

## 1. Resumen

`Salir_De_Fiesta` es una actividad temporal de alto riesgo y alta recompensa. Se programa entre las 18:00 y las 06:00, con una duración mínima de 2 horas y máxima de 12. Cada minuto del bloque calcula dos probabilidades separadas con las necesidades básicas actuales, el progreso y la personalidad: ligar (sube cuando el estado es bueno) y pasarse con la bebida (sube cuando el estado empeora). El primer evento que salga se resuelve una sola vez por fiesta: ligar activa `Euforia` durante 24 h; pasarse activa `Resacon` durante 24 h. La fiesta continúa después del evento y el estado se aplica durante el resto del bloque y las horas siguientes.

## 2. Contexto y problema

El juego tiene siete actividades temporales con perfiles de efecto muy parecidos. `Salir_De_Fiesta` debe ser distinta: una actividad de decisiones, no otra barra que sube y baja. El jugador elige cuánto tiempo se queda, sabiendo que las necesidades se desgastan y que cada minuto es menos probable ligar, pero que una fiesta más larga acumula más oportunidades de que ocurra algo.

El motor actual ya aplica los efectos de las actividades por minuto con una probabilidad basada en una frecuencia (`Actividades_Necesidades_Basicas.gd`). Esta funcionalidad reutiliza ese mismo patrón para los eventos especiales: probabilidad por minuto, calculada con el estado actual del personaje.

## 3. Objetivo y métricas de éxito

**Objetivo:** añadir una actividad de fiesta que cree una decisión real entre duración, desgaste y probabilidad de un estado temporal.

**Métricas de éxito:**

- El jugador puede programar bloques de 2 a 12 horas dentro de la ventana 18:00–06:00.
- La vista previa muestra la probabilidad acumulada de ligar, resacón y noche normal antes de confirmar.
- Cada fiesta programada activa como máximo un estado especial.
- Los estados `Euforia` y `Resacon` son visibles, persistentes y se eliminan mutuamente.
- Ninguna actividad existente cambia de efectos, prioridad ni comportamiento.
- Los tests GUT de la funcionalidad pasan.

## 4. Alcance

### Dentro

- Entrada `Salir_De_Fiesta` en `Variables_Estaticas.Catalogo_Actividades`.
- Botón en `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones`, conexión y handler.
- Ventana horaria 18:00–06:00, duración mínima 2 h y máxima 12 h.
- Probabilidad por minuto de evento especial basada en necesidades, progreso y personalidad.
- Dos probabilidades separadas por minuto: ligar crece con el estado y resacón decrece. El primer evento que salga se resuelve una sola vez por fiesta programada.
- Estados `Euforia` y `Resacon`: duración, tick, cap, mensajes, UI y persistencia.
- Vista previa de duración y probabilidades en `Seleccionar_Horario`.
- Label de estado activo en el panel de Necesidades Básicas.
- Tests GUT y documentación de la funcionalidad.

### Fuera (y por qué)

- **Las otras cinco actividades del lote anterior** (`Ordenar_La_Casa`, `Meditar`, `Leer_Un_Libro`, `Entrenar_En_El_Gimnasio`, `Montar_Un_Taller_De_Manualidades`): esta especificación se centra solo en `Salir_De_Fiesta`.
- **Otros estados temporales** (`Lesion`, `Inspiracion`, `Corte`): el sistema queda preparado, pero v1 solo registra `Euforia` y `Resacon`.
- **Coste o ingreso de dinero**: la actividad no cobra entrada ni gana dinero.
- **Requisitos de objetos o libros**: no se añaden.
- **Nueva pestaña o categoría**: se reutiliza Necesidades Básicas.
- **Fiesta en el pool aleatorio**: en v1 `Salir_De_Fiesta` no entra en `Variables_Estaticas.Actividades`; solo se ejecuta cuando el jugador la programa. Así se respeta la ventana 18:00–06:00 y no hay estados mientras el jugador no mira.
- **Animaciones nuevas o assets de iconos**: se usa `party-popper`, ya existente en `Imagenes/UI/Iconos/`.
- **Cambios en el selector aleatorio global**: se mantiene el comportamiento actual para las demás actividades.

## 5. Actores y permisos

| Actor | Permiso |
|---|---|
| Jugador | Programa, cancela y consulta la fiesta; ve la vista previa y el estado activo. |
| Sistema | Ejecuta los efectos por minuto, calcula la probabilidad, resuelve el evento, tickea los estados y genera mensajes. |
| Guardado | Persiste `Estados_Temporales` y el flag de evento de la fiesta en curso. |

No hay multijugador ni permisos adicionales.

## 6. Flujo principal

1. El jugador abre **Actividades → Temporales → Necesidades → Salir de fiesta**.
2. El sistema abre `Seleccionar_Horario` con el día, hora y minuto de inicio y fin.
3. El sistema valida: inicio entre 18:00 y 04:00; fin entre 20:00 y 06:00; duración entre 120 y 720 minutos; que el bloque no se salga de la matriz; y prioridad P1/P2/P3 (no puede pisar trabajo P2 ni examen P3).
4. Si es válido, la vista previa muestra duración, probabilidad por minuto al inicio y al final, y probabilidad acumulada de ligar, resacón y nada.
5. Al confirmar, el bloque se escribe en `Variables_Dinamicas.Matriz_Jugador`.
6. En el primer minuto del bloque se resetea `Fiesta_Evento_Ocurrido = false`.
7. Cada minuto del bloque programado: (1) se aplican los efectos base; (2) si `Fiesta_Evento_Ocurrido` es falso, se calcula el puntaje con las necesidades actuales y se tiran las dos probabilidades; (3) si el evento ocurre, se marca el flag, se activa el estado correspondiente y se genera un mensaje; ligar y resacón se tiran por separado y gana el primero que salga; (4) se tickean los estados activos; (5) se comprueba la muerte con el estado ya aplicado.
8. La fiesta continúa después del evento. El estado sigue activo durante el resto del bloque y las horas que le queden.
9. Al terminar la duración del estado, se elimina y se genera el mensaje de fin.
10. Al cancelar o terminar la fiesta sin evento, no se activa ningún estado.

**Puntos de decisión:**

- ¿El bloque está dentro de la ventana y dura al menos 2 h?
- ¿Hay trabajo o examen en alguna celda?
- ¿Ya ocurrió un evento en esta fiesta?
- ¿La tirada por minuto activa ligar o resacón?
- ¿El estado activo es el opuesto de otro? En ese caso, el nuevo sustituye al anterior.
- ¿El personaje está en la calle o en bancarrota? El cap de necesidades se reduce a 20.

## 7. Requisitos funcionales

| ID | Requisito | Detalle |
|---|---|---|
| RF-01 | Registrar la actividad | `Salir_De_Fiesta` es una `Actividad_Temporal` en `Catalogo_Actividades`, con `color = Color(0.85, 0.15, 0.45)`, `efectos_necesidades_basicas = [0, 9, -3, -4, -2]`, `efectos_progreso = [0, 0, 0]` y prioridad P1. |
| RF-02 | Integrar en la UI | Botón en `Necesidades_Basicas_Opciones`, texto `🎉  SALIR DE FIESTA`, conexión `pressed` al método `Actividad_Terminada_Salir_De_Fiesta` y handler que llama a `Crear_Actividad("Salir_De_Fiesta")`. |
| RF-03 | Ventana horaria | El bloque debe empezar entre las 18:00 y las 04:00, terminar entre las 20:00 y las 06:00 y durar entre 120 y 720 minutos. El fin debe ser posterior al inicio; si cruza medianoche, el día final es el siguiente. Si no cumple, se rechaza con el motivo concreto. |
| RF-04 | Probabilidad por minuto | Cada minuto se calcula un puntaje con necesidades, progreso y personalidad; se traducen a dos probabilidades separadas (ligar y resacón) y se tiran. |
| RF-05 | Un evento por fiesta | `Fiesta_Evento_Ocurrido` impide más tiradas en el mismo bloque. Se resetea en el primer minuto de un bloque nuevo. Cada minuto se tira primero ligar y después resacón, con probabilidades separadas; el primero que salga activa su estado y detiene las tiradas de esa fiesta. |
| RF-06 | Estado Euforia | Al ligar, se activa `Euforia` durante 1440 minutos, se fija la salud mental al máximo permitido, se elimina `Resacon` y se genera mensaje. |
| RF-07 | Estado Resacon | Al pasarse con la bebida, se activa `Resacon` durante 1440 minutos, se recortan física y mental a 30, se elimina `Euforia` y se genera mensaje. |
| RF-08 | Cap del resacón | Mientras `Resacon` esté activo, física y mental no pueden superar el techo calculado. El techo sube linealmente de 30 a 100 en 1440 minutos. En la calle o en bancarrota, el techo efectivo es el mínimo entre el del resacón y 20. |
| RF-09 | Tick de estados | En cada minuto se aplica primero el efecto del estado con el valor actual del contador y después se descuenta 1. Al llegar a 0 se elimina y se genera el mensaje de fin. |
| RF-10 | Vista previa | En `Seleccionar_Horario`, cuando la actividad es `Salir_De_Fiesta`, se muestra un panel con duración, probabilidad por minuto al inicio y al final, y acumuladas de ligar, resacón y nada. Se oculta para las demás actividades. |
| RF-11 | Label de estado | En el panel de Necesidades Básicas se muestra el estado activo: `Euforia · 23h 59m` o `Resacon · 18h 20m · límite 45`. |
| RF-12 | Persistencia | `Variables_Dinamicas.Estados_Temporales` y `Variables_Dinamicas.Fiesta_Evento_Ocurrido` se guardan y cargan. Los saves antiguos cargan con `{}` y `false`. |
| RF-13 | Mensajes | Se generan mensajes al activar y al terminar cada estado. Se reutiliza `Variables_Dinamicas.Mensajes` y la pantalla de perfil. |
| RF-14 | No regresión | Las actividades existentes, la jerarquía P1/P2/P3, los trabajos, la tienda, las carreras y el guardado actual no cambian. |
| RF-15 | Tests y documentación | Se añaden tests GUT y una ficha de la funcionalidad en `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/`. |

## 8. Requisitos no funcionales

| ID | Requisito | Valor objetivo |
|---|---|---|
| RNF-01 | Rendimiento | La lógica de la fiesta y los estados cuesta O(1) por minuto; no se añade trabajo por frame ni escaneos nuevos de la matriz. |
| RNF-02 | Compatibilidad | Godot 4.4; los saves antiguos cargan sin migración manual; nombres de catálogo ASCII y estables. |
| RNF-03 | Testabilidad | Funciones puras para puntaje, probabilidades y acumulada con riesgos competitivos; el RNG solo se usa en la tirada final. |
| RNF-04 | UI | A 720×1280 la vista previa y el label de estado se leen sin desbordes; no se depende solo del color. |

## 9. Datos

| Campo | Tipo | Rango/Valores | Default | Persistencia |
|---|---|---|---|---|
| `Salir_De_Fiesta.nombre` | String | `"Salir_De_Fiesta"` | — | Catálogo, no save |
| `Salir_De_Fiesta.color` | Color | `Color(0.85, 0.15, 0.45)` | — | Catálogo, no save |
| `Salir_De_Fiesta.efectos_necesidades_basicas` | Array[5] | `[0, 9, -3, -4, -2]` | — | Catálogo, no save |
| `Salir_De_Fiesta.efectos_progreso` | Array[3] | `[0, 0, 0]` | — | Catálogo, no save |
| `Variables_Dinamicas.Estados_Temporales` | Dictionary | `{nombre_estado: minutos_restantes}` | `{}` | Save dinámico |
| `Variables_Dinamicas.Fiesta_Evento_Ocurrido` | bool | `true`/`false` | `false` | Save dinámico |
| `Variables_Estaticas.Estados_Temporales["Euforia"]` | Dictionary | `duracion=1440`, `meseta=480`, `tipo="suelo_gradual"`, `valor_inicial=100`, `valor_final=50` | — | Catálogo estático |
| `Variables_Estaticas.Estados_Temporales["Resacon"]` | Dictionary | `duracion=1440`, `meseta=480`, `tipo="cap_gradual"`, `indices=[0,1]`, `cap_inicial=30`, `cap_final=100` | — | Catálogo estático |

### Fórmulas independientes por minuto

Ligar y resacón tienen **dos fórmulas y dos tiradas independientes**:

#### 1. Probabilidad de Ligar (carisma, ánimo, presencia, edad y día)

```
mod_edad = clamp(10.0 - (edad - 20) * 0.625, -25.0, 12.0)   # 20 años: +10 · 36: 0 · 60: -15 · 76+: -25

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

prob_ligar_min = (0.00001 + 0.00099 * (puntaje_ligar / 100.0)) * mult_dia
```

Multiplicador por día de la semana de la noche (`dia_noche = dia` si `hora >= 18`, o `dia - 1` si `hora < 6`, con `dia_noche % 7`):

| Día (`dia_noche % 7`) | `mult_dia` (solo Ligar) | Motivo |
|---|---|---|
| `0, 1, 2` (Lunes–Miércoles) | `0,70` | Poca gente en los bares |
| `3` (Jueves) | `1,00` | Ambiente universitario / neutro |
| `4` (Viernes) | `1,25` | Inicio de fin de semana |
| `5` (Sábado) | `1,45` | Noche pico, locales llenos |
| `6` (Domingo) | `0,80` | Noche tranquila antes del lunes |

#### 2. Probabilidad de Resacón (aguante físico y edad)

```
aguante_resacon = clamp(
    50
    + 0.40 * (NB[2] - 50)        # Hambre
    + 0.30 * (NB[3] - 50)        # Descanso
    + 0.20 * (NB[0] - 50)        # Salud Física
    + 0.10 * (Progreso[0] - 50)  # Deporte
    + mod_edad,                  # 20 años: +10 aguante · 60 años: -15 aguante
    0, 100
)

riesgo_resacon = (100.0 - aguante_resacon) / 100.0
prob_resacon_min = 0.00001 + 0.00099 * riesgo_resacon          # 0,001 %/min .. 0,100 %/min
```

*(El día de la semana solo afecta a Ligar por la afluencia de gente; el Resacón depende del cuerpo, las necesidades y la edad).*

| Personalidad | `mod_personalidad` (solo en Ligar) |
|---|---|
| `Deportista` | +10 |
| `Culo_Del_Sofa` | −10 |
| `Trabajador_Compulsivo` | −5 |
| Otra / vacía | 0 |

- Las probabilidades se calculan **después** de aplicar los efectos del minuto.
- La suma `prob_ligar_min + prob_resacon_min` **no es constante**: cada evento depende de sus propias necesidades.
- Tirada independiente por minuto: primero `if randf() < prob_ligar_min:` → ligar; si no, `if randf() < prob_resacon_min:` → resacón; si no, nada.

### Efecto de las necesidades en la probabilidad

Para el perfil estándar (Deporte 50, Académico 50, sin personalidad) y todas las necesidades al mismo valor (fiesta de 6 h con desgaste):

| Necesidades iniciales | Ligar/min (inicio) | Resacón/min (inicio) | Ligar (6 h) | Resacón (6 h) | Nada (6 h) |
|---|---|---|---|---|---|
| 100 | 0,0827 % | 0,0060 % | 22,3 % | 10,8 % | 66,9 % |
| 80 | 0,0698 % | 0,0238 % | 19,7 % | 15,7 % | 64,6 % |
| 60 | 0,0569 % | 0,0416 % | 17,0 % | 19,8 % | 63,2 % |
| 50 | 0,0505 % | 0,0505 % | 15,7 % | 21,6 % | 62,8 % |
| 40 | 0,0441 % | 0,0594 % | 14,3 % | 23,2 % | 62,6 % |
| 20 | 0,0312 % | 0,0772 % | 11,7 % | 25,7 % | 62,6 % |

- Con necesidades altas, ligar domina claramente sobre el resacón.
- Con necesidades bajas (o sin cenar/dormir), el resacón domina sobre ligar.
- La higiene, la salud mental y lo académico ayudan a ligar pero no protegen del resacón; el hambre y el descanso protegen del resacón.

### Curva de los estados (8 h a tope + 16 h bajada gradual)

Ambos estados duran 1440 min (24 h) con una **meseta inicial de 480 min (8 h)** al máximo efecto, y luego bajan gradualmente durante los **960 min (16 h)** restantes:

- **Resacón (`cap` máximo de Salud Física y Mental):**
```
si minutos_restantes > 960: cap = 30
si no: cap = 30 + floor((960 - minutos_restantes) * 70 / 960)
```
- **Euforia (`suelo` mínimo de Salud Mental):**
```
si minutos_restantes > 960: suelo = 100
si no: suelo = floor(100 - (960 - minutos_restantes) * 50 / 960)
```

| Minutos restantes | Tiempo transcurrido | Techo Resacón | Suelo Euforia |
|---|---|---|---|
| 1440–960 | 0–8 h | 30 | 100 |
| 720 | 12 h | 47 | 87 |
| 480 | 16 h | 65 | 75 |
| 240 | 20 h | 82 | 62 |
| 0 | 24 h | 100 | 50 |

### Proyección para la vista previa

La vista previa simula el bloque minuto a minuto con el valor esperado de los efectos:

```
delta = signo(efecto) * min(1.0, abs(efecto) / frecuencia)
necesidad_proyectada = clamp(necesidad_proyectada + delta, 1, 100)
```

Frecuencias: salud física y mental 30; hambre 12; descanso 15; higiene 20. Con esas necesidades proyectadas se calcula el puntaje y, en cada minuto, `prob_ligar_min` y `prob_resacon_min`. La simulación usa riesgos competitivos, porque solo puede ocurrir un evento por fiesta:

```
supervivencia = 1.0
p_ligar = 0.0
p_resacon = 0.0
para cada minuto:
    p_ligar += supervivencia * prob_ligar_min
    p_resacon += supervivencia * prob_resacon_min * (1.0 - prob_ligar_min)
    supervivencia *= (1.0 - prob_ligar_min) * (1.0 - prob_resacon_min)
p_nada = supervivencia
```

Al final, `p_ligar + p_resacon + p_nada = 1`. La etiqueta indica que es una estimación.

## 10. Integración con el código existente

| Archivo | Cambio |
|---|---|
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | Añadir `Salir_De_Fiesta` en `_Inicializar_Catalogo()`. No añadir al array `Actividades` en v1. Añadir `Estados_Temporales` con `Euforia` y `Resacon`. |
| `Escenas/Escena_Principal/Escena principal.tscn` | Añadir el `Button` en `Necesidades_Basicas_Opciones` y la conexión `pressed`. |
| `Scripts/Globales/Script_Principal.gd` | Handler `Actividad_Terminada_Salir_De_Fiesta`, entrada en `_SUBTITULOS_ACTIVIDADES`, diálogo de error de ventana/duración. |
| `Scripts/GUI/Escena_Principal/Estilos_UI.gd` | Entrada `Salir_De_Fiesta` en `ICONOS_BOTONES` con `party-popper`. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | `Resolver_Evento_Fiesta`, `Tick_Estados`, `Activar_Estado`, `Obtener_Cap_Resacon`, `Es_Primer_Minuto_Del_Bloque`, validación de la ventana. |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` | Aplicar el cap de `Resacon` después del cap de bancarrota. |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | Nuevos campos `Estados_Temporales` y `Fiesta_Evento_Ocurrido`. |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Guardar/cargar los dos campos nuevos con fallback. |
| `Scripts/Globales/Menu.gd` | Resetear los dos campos en partida nueva. |
| `Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd` | Label de estado activo y actualización del texto/techo. |
| `Scripts/GUI/Escena_Principal/Actividades/Reloj/Auxiliar/SeleccionarHorarioReloj.gd` | Panel de vista previa de Fiesta y actualización al cambiar hora/minuto. |
| `Funcionalidades/Actividades/Actividades_Temporales/Tests/` | Tests GUT de fórmula, ventana, estados, cap, persistencia y no regresión. |
| `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/` | Ficha `SALIR_DE_FIESTA.md` y `.html`. |

## 11. Casos borde y errores

| Escenario | Comportamiento esperado |
|---|---|
| Inicio a las 17:59 | Rechazo: "La fiesta debe empezar entre las 18:00 y las 04:00". |
| Inicio a las 04:01 | Rechazo por el mismo motivo. |
| Fin a las 06:01 | Rechazo: "La fiesta debe terminar como máximo a las 06:00". |
| Duración 1 h 59 min | Rechazo: "La fiesta debe durar al menos 2 horas". |
| Duración 12 h exactas (18:00–06:00) | Aceptado. |
| Bloque 22:00–02:00 | Aceptado; cruza medianoche. |
| Bloque 02:00–06:00 | Aceptado; empieza de madrugada. |
| Bloque que se sale de la matriz | Rechazo: "El bloque se sale del calendario". |
| Solape con trabajo o examen | Rechazo con el diálogo de prioridad existente. |
| Evento en el primer minuto | Se activa el estado; la fiesta continúa. |
| Evento en el último minuto | Se activa el estado; la fiesta termina y el estado sigue. |
| Sin evento | No se activa ningún estado. |
| `Euforia` activa y ocurre `Resacon` | `Resacon` sustituye a `Euforia`. |
| `Resacon` activo y ocurre `Euforia` | `Euforia` sustituye a `Resacon`. |
| Resacón con 480 min restantes | Techo 65. |
| Resacón en bancarrota o calle | Techo efectivo 20. |
| Guardado a mitad de fiesta | El flag y los estados se conservan; no se repite el evento. |
| Save antiguo sin los campos nuevos | Carga con `{}` y `false`. |
| Dos bloques de Fiesta adyacentes | Se consideran un solo bloque; como máximo un evento. |

## 12. UI/UX

### Tarjeta de actividad

- Icono: `party-popper`.
- Título: `Salir de fiesta`.
- Subtítulo: `Noche · 2–12 h · Prob. según estado`.
- Color de badge: rosa/magenta.

### Vista previa en `Seleccionar_Horario`

```
Salir de fiesta
Duración: 6h 00m
Por minuto: ligar 0,070 % al empezar · 0,059 % al terminar
Por minuto: resacón 0,024 % al empezar · 0,079 % al terminar
Ligar: 19,7 % · Resacón: 15,7 % · Nada: 64,6 %
Estimación según tus necesidades actuales y el desgaste previsto.
```

- Si el bloque no es válido, se muestra el motivo y no se muestran probabilidades.
- El panel se oculta para cualquier otra actividad.
- La estimación usa las necesidades proyectadas; la tirada real usa las necesidades reales.

### Label de estado

- `Euforia · 23h 59m` en color positivo.
- `Resacon · 18h 20m · límite 45` en color negativo.
- Se actualiza una vez por minuto; no se añade trabajo por frame.

### Mensajes

- `Has ligado. Euforia durante 24 h.`
- `Te has pasado con la bebida. Resacón durante 24 h.`
- `La euforia ha terminado.`
- `El resacón ha terminado.`

## 13. Criterios de aceptación

- [x] AC-01 — Dado el catálogo inicializado, cuando se consulta, entonces existe `Salir_De_Fiesta` como `Actividad_Temporal` con `[0, 9, -3, -4, -2]`, `[0, 0, 0]` y prioridad P1.
- [x] AC-02 — Dado el menú de actividades temporales, cuando se abre Necesidades, entonces aparece el botón de Fiesta con icono y subtítulo, y su conexión llama al handler correcto.
- [x] AC-03 — Dado el selector de horario, cuando se intenta 17:59–06:00, entonces se rechaza con el motivo de inicio; cuando se intenta 18:00–06:00, entonces se acepta.
- [x] AC-04 — Dado el selector, cuando se intenta 18:00–19:59, entonces se rechaza por duración mínima; cuando se intenta 18:00–20:00, entonces se acepta.
- [x] AC-05 — Dado el selector, cuando se intenta 18:00–06:01, entonces se rechaza por fin; cuando se intenta 18:00–05:59, entonces se acepta.
- [x] AC-06 — Dado el selector, cuando se intenta 22:00–02:00, entonces se acepta el cruce de medianoche; cuando se intenta 02:00–06:00, entonces se acepta el inicio de madrugada.
- [x] AC-07 — Dado el selector con Fiesta, cuando se elige un bloque válido, entonces se muestra duración, probabilidad por minuto y acumuladas; cuando se elige otra actividad, el panel se oculta.
- [x] AC-08 — Dado el perfil estándar (Deporte 50, Académico 50, sin personalidad, necesidades 80), cuando se simula el primer minuto, entonces ligar es 0,070 % y resacón 0,024 %; en el minuto 360, ligar es 0,059 % y resacón 0,079 %.
- [x] AC-09 — Dado el mismo perfil con necesidades 40, cuando se calcula, entonces la probabilidad es menor que con 80; con Deporte y Académico 100 es mayor que con 20.
- [x] AC-10 — Dado un bloque programado, cuando se ejecutan sus minutos, entonces se activa como máximo un evento nuevo por bloque.
- [x] AC-11 — Dado que el evento es ligar, cuando se activa, entonces `Euforia` dura 1440 min, la salud mental queda al máximo permitido y se elimina `Resacon`.
- [x] AC-12 — Dado que el evento es resacón, cuando se activa, entonces `Resacon` dura 1440 min, física y mental se recortan a 30 y se elimina `Euforia`.
- [x] AC-13 — Dado `Resacon` activo, cuando quedan 480 min, entonces el techo es 65; cuando quedan 0, el techo es 100; en bancarrota el techo efectivo es 20.
- [x] AC-14 — Dado un guardado con estados y flag, cuando se carga, entonces se restauran; un save antiguo carga con `{}` y `false`.
- [x] AC-15 — Dado un estado activo, cuando se abre Necesidades, entonces se muestra el label con tiempo restante y, en resacón, el techo actual.
- [x] AC-16 — Dado el juego existente, cuando se ejecutan las demás actividades, entonces sus efectos, prioridades y guardados no cambian; los tests GUT pasan.
- [x] AC-17 — Dado el mismo perfil y duración, cuando las necesidades suben de 40 a 80, entonces la probabilidad de ligar sube y la de resacón baja; cuando bajan de 80 a 40, ocurre lo contrario.

## 14. Supuestos y decisiones

| ID | Supuesto | Motivo | Confirmado |
|---|---|---|---|
| SUP-01 | La probabilidad se resuelve por minuto, sin término directo de duración. | El desgaste de necesidades es el que hace más difícil ligar con el tiempo. | Sí |
| SUP-02 | Ligar y resacón tienen dos fórmulas y tiradas independientes (sin suma constante): ligar depende de ánimo/higiene/progreso/descanso/personalidad; resacón depende de hambre/descanso/física/deporte invertidos. | El usuario pidió explícitamente dos probabilidades independientes según las necesidades de cada evento. | Sí |
| SUP-03 | Constantes aprobadas: Ligar (Mental 0,30, Higiene 0,25, Deporte 0,20, Académico 0,15, Descanso 0,10, pers. ±10/−5); Resacón (Hambre 0,40, Descanso 0,30, Física 0,20, Deporte 0,10 invertido); rango `0,001 %–0,100 %/min` en ambas. | Confirmado por el usuario en la revisión de v1.0. | Sí |
| SUP-04 | Ventana: inicio 18:00–04:00, fin 20:00–06:00, duración 2–12 h. | La fiesta debe caber entre las 18:00 y las 06:00. | Sí |
| SUP-05 | `Salir_De_Fiesta` no entra en el pool aleatorio en v1; solo se ejecuta programada. | La ventana 18:00–06:00 y los estados especiales no encajan con la selección aleatoria actual, que no filtra por hora. | Sí |
| SUP-06 | Como máximo un evento por fiesta programada. | Evita estados contradictorios y mensajes duplicados. | Sí |
| SUP-07 | `Euforia` y `Resacon` son opuestos; el último sustituye al anterior. | No tiene sentido estar eufórico y con resacón a la vez. | Sí |
| SUP-08 | El techo del resacón sube linealmente de 30 a 100 en 1440 min; en bancarrota se aplica el mínimo con 20. | Recuperación gradual y respeto a la regla de bancarrota existente. | Sí |
| SUP-09 | Los estados duran 1440 minutos de juego. | El usuario pidió “un día”. | Sí |
| SUP-10 | La vista previa usa necesidades proyectadas; la tirada real usa las reales. | Da información útil sin prometer el resultado exacto. | Sí |
| SUP-11 | Solo se especifica `Salir_De_Fiesta`; las otras actividades quedan fuera. | El usuario pidió centrarse solo en esta actividad. | Sí |
| SUP-12 | Se usa `party-popper`, ya existente. | No se añaden assets nuevos. | Sí |
| SUP-13 | 1 minuto de juego = 1 minuto real. | Comportamiento actual del reloj. | Sí |
| SUP-14 | El label de estado vive en el panel de Necesidades Básicas. | Es donde el jugador consulta el estado del personaje. | Sí |
| SUP-15 | Los tests siguen el patrón GUT de `test_jerarquia.gd`. | Convención del proyecto. | Sí |

## 15. Preguntas abiertas

Todas las preguntas abiertas (`PA-01` a `PA-05`) han sido resueltas y aprobadas en la versión `v1.0`.

## 16. Historial de versiones

| Versión | Fecha | Cambio |
|---|---|---|
| v0.1 | 2026-11-19 | Borrador inicial: actividad, ventana 18:00–06:00, mínimo 2 h, probabilidad por minuto, Euforia/Resacón, vista previa, persistencia y tests. |
| v0.2 | 2026-11-19 | Añadida tabla de efecto de las necesidades en la probabilidad y aclaración de que ligar y resacón comparten tirada. |
| v0.3 | 2026-11-19 | Separadas las probabilidades de ligar y resacón: ligar sube con el estado y resacón baja. Actualizadas tablas, vista previa y criterios de aceptación. |
| v1.0 | 2026-11-19 | Aprobada: dos fórmulas y tiradas independientes para Ligar y Resacón, cerradas PA-01..PA-05. |
| v1.1 | 2026-11-19 | Implementada. Corregidos AC-08, AC-13, el ejemplo de §12 y la fórmula de Euforia (87/62); las 06:00 cuentan como noche del día anterior. |
